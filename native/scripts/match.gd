extends RefCounted
const Catalog = preload("res://scripts/catalog.gd")
const Hunter = preload("res://scripts/hunter.gd")

signal event(message: String)
signal meeting_started
signal meeting_ended(message: String)
signal finished(winner: String, reason: String)

var players: Array[Dictionary] = []
var bodies: Array[Dictionary] = []
var phase = "lobby"
var elapsed = 0.0
var reactor_time = -1.0
var sabotage_cooldown = 0.0
var sensors_off = 0.0
var meeting_time = 0.0
var votes: Dictionary = {}
var result: Dictionary = {}
var rng = RandomNumberGenerator.new()
var crew_tasks_required = 0
var log: Array[String] = []

func start(total: int, traitor_count: int, human_role: String, seed_value: int = -1) -> void:
	players.clear()
	bodies.clear()
	log.clear()
	result.clear()
	votes.clear()
	elapsed = 0.0
	reactor_time = -1.0
	sensors_off = 0.0
	sabotage_cooldown = 35.0
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	total = clampi(total, 12, 40)
	traitor_count = clampi(traitor_count, 1, 5)
	if human_role not in Catalog.CREW_ROLES and human_role not in Catalog.TRAITOR_ROLES:
		human_role = "Astronaut"
	var remaining_traitors = traitor_count - int(Catalog.is_traitor(human_role))
	var ids: Array[int] = []
	for i in range(1, total):
		ids.append(i)
	# Shuffle with this match's RNG, independent of the global RNG.
	for i in range(ids.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var old = ids[i]
		ids[i] = ids[j]
		ids[j] = old
	var traitor_ids = ids.slice(0, remaining_traitors)
	for i in total:
		var role = human_role if i == 0 else Catalog.CREW_ROLES[rng.randi_range(0, Catalog.CREW_ROLES.size() - 1)]
		if i in traitor_ids:
			role = Catalog.TRAITOR_ROLES[rng.randi_range(0, Catalog.TRAITOR_ROLES.size() - 1)]
		players.append({"id": i, "name": Catalog.NAMES[i], "role": role,
			"traitor": Catalog.is_traitor(role), "alive": true,
			"tasks": [], "pos": Vector3.ZERO, "kill_cd": 18.0,
			"ability_cd": 0.0, "protected_until": -1.0, "hidden_until": -1.0,
			"ammo": Hunter.STARTING_AMMO if role == "Hunter" else 0,
			"boost_until": -1.0, "mimic_until": -1.0, "mimic_id": -1,
			"emergency_used": false, "suspicion": {}})
	crew_tasks_required = (total - traitor_count) * Catalog.TASKS.size()
	phase = "active"
	announce("Legătura cu OMEGA-9 a fost restabilită. Identitățile sunt secrete.")

func announce(message: String) -> void:
	log.append(message)
	event.emit(message)

func tick(delta: float) -> void:
	if phase == "meeting":
		meeting_time -= delta
		if meeting_time <= 0.0:
			resolve_votes()
		return
	if phase != "active":
		return
	elapsed += delta
	sabotage_cooldown = maxf(0.0, sabotage_cooldown - delta)
	sensors_off = maxf(0.0, sensors_off - delta)
	for p in players:
		p.kill_cd = maxf(0.0, p.kill_cd - delta)
		p.ability_cd = maxf(0.0, p.ability_cd - delta)
	if reactor_time > 0.0:
		reactor_time -= delta
		if reactor_time <= 0.0:
			end("TRĂDĂTORII", "Reactorul a devenit instabil.")
	check_win()

func complete_task(id: int, task_id: int) -> bool:
	if phase != "active" or id < 0 or id >= players.size() or task_id < 0 or task_id >= Catalog.TASKS.size():
		return false
	var p = players[id]
	if p.traitor or task_id in p.tasks:
		return false
	p.tasks.append(task_id)
	if id == 0:
		announce("Misiune încheiată: " + Catalog.TASKS[task_id].name)
	check_win()
	return true

func progress() -> int:
	var amount = 0
	for p in players:
		if not p.traitor:
			amount += p.tasks.size()
	return amount

func alive_count(traitors: bool) -> int:
	var count = 0
	for p in players:
		if p.alive and p.traitor == traitors:
			count += 1
	return count

func try_kill(attacker: int, victim: int) -> bool:
	if phase != "active" or attacker < 0 or victim < 0 or attacker >= players.size() or victim >= players.size():
		return false
	var a = players[attacker]
	var v = players[victim]
	if not a.alive or not v.alive or not a.traitor or v.traitor or a.kill_cd > 0.0:
		return false
	if a.pos.distance_to(v.pos) > 2.8:
		return false
	if v.protected_until > elapsed:
		a.kill_cd = 6.0
		announce("Un scut a blocat o eliminare.")
		return false
	v.alive = false
	a.hidden_until = -1.0
	a.kill_cd = 22.0 if a.role == "Asasin" else 30.0
	bodies.append({"id": victim, "pos": v.pos, "killer": attacker, "time": elapsed})
	# Witness testimony is added by Game only after visibility and distance checks.
	if victim == 0:
		announce("Ai fost eliminat. Ca ecou, poți termina misiunile, dar nu mai votezi.")
	check_win()
	return true

func witness(witness_id: int, attacker: int) -> void:
	if witness_id > 0 and players[witness_id].alive and not players[witness_id].traitor:
		players[witness_id].suspicion[attacker] = 1.0

func hunter_shot(shooter: int, target: int = -1) -> Dictionary:
	var shot = {"fired": false, "killed": false, "target": target}
	if phase != "active" or shooter < 0 or shooter >= players.size() or target < -1 or target >= players.size():
		return shot
	var hunter = players[shooter]
	if hunter.role != "Hunter" or hunter.traitor or not hunter.alive or hunter.ammo <= 0 or hunter.ability_cd > 0:
		return shot
	hunter.ammo -= 1
	hunter.ability_cd = Hunter.CYCLE_SECONDS
	shot.fired = true
	# Misses, crew contacts and shields still consume a cartridge. The Hunter
	# never harms crew, irrespective of copied names or appearance.
	if target < 0 or target == shooter:
		return shot
	var victim = players[target]
	if not victim.alive or not victim.traitor or hunter.pos.distance_to(victim.pos) > Hunter.RANGE or victim.protected_until > elapsed:
		return shot
	victim.alive = false
	bodies.append({"id": target, "pos": victim.pos, "killer": shooter, "time": elapsed})
	shot.killed = true
	announce("Winchester: " + hunter.name + " a eliminat " + victim.name + ".")
	check_win()
	return shot

func sabotage(id: int) -> bool:
	if phase != "active" or id < 0 or id >= players.size():
		return false
	var p = players[id]
	if not p.alive or not p.traitor or reactor_time > 0.0 or sabotage_cooldown > 0.0:
		return false
	reactor_time = 75.0
	sabotage_cooldown = 100.0
	announce("AVARIE REACTOR. Repară unul dintre cele două terminale din REACTOR!")
	return true

func repair_reactor(id: int) -> bool:
	if phase != "active" or reactor_time <= 0 or id < 0 or id >= players.size():
		return false
	var p = players[id]
	if p.traitor or not p.alive:
		return false
	var distance = minf(p.pos.distance_to(Catalog.TASKS[0].pos), p.pos.distance_to(Catalog.TASKS[4].pos))
	if distance > 3.0:
		return false
	reactor_time = -1.0
	announce("Reactor stabilizat. Energia a revenit.")
	return true

func call_meeting(id: int, body_id: int = -1) -> bool:
	if phase != "active" or id < 0 or id >= players.size() or not players[id].alive:
		return false
	if body_id < 0:
		if players[id].emergency_used or reactor_time > 0.0 or players[id].pos.distance_to(Vector3.ZERO) > 3.5:
			return false
		players[id].emergency_used = true
	else:
		var found = false
		for body in bodies:
			if body.id == body_id and players[id].pos.distance_to(body.pos) <= 4.0:
				found = true
		if not found:
			return false
	phase = "meeting"
	meeting_time = 25.0
	votes.clear()
	announce(players[id].name + (" a raportat o victimă." if body_id >= 0 else " a convocat ședința."))
	meeting_started.emit()
	return true

func vote(voter: int, target: int) -> bool:
	if phase != "meeting" or voter < 0 or voter >= players.size() or not players[voter].alive or votes.has(voter):
		return false
	if target != -1 and (target < 0 or target >= players.size() or not players[target].alive):
		return false
	votes[voter] = target
	return true

func resolve_votes() -> void:
	if phase != "meeting":
		return
	# Every abstention becomes skip; a silent player cannot force an ejection.
	for p in players:
		if p.alive and not votes.has(p.id):
			votes[p.id] = -1
	var counts: Dictionary = {}
	for target in votes.values():
		counts[target] = int(counts.get(target, 0)) + 1
	var highest = 0
	var candidates: Array[int] = []
	for target in counts:
		var n = int(counts[target])
		if n > highest:
			highest = n
			candidates = [int(target)]
		elif n == highest:
			candidates.append(int(target))
	var message = "Egalitate sau abținere. Nimeni nu a fost expulzat."
	if candidates.size() == 1 and candidates[0] >= 0:
		var ejected = players[candidates[0]]
		ejected.alive = false
		message = ejected.name + " a fost expulzat. Era " + ("TRĂDĂTOR." if ejected.traitor else "membru al echipajului.")
	bodies.clear()
	phase = "active"
	for p in players:
		p.kill_cd = maxf(p.kill_cd, 8.0)
		if p.role == "Hunter":
			p.ability_cd = maxf(p.ability_cd, Hunter.CYCLE_SECONDS)
	announce(message)
	meeting_ended.emit(message)
	check_win()

func check_win() -> void:
	if phase != "active":
		return
	var traitors = alive_count(true)
	var crew = alive_count(false)
	if traitors == 0:
		end("ECHIPAJUL", "Toți trădătorii au fost descoperiți.")
	elif traitors >= crew:
		end("TRĂDĂTORII", "Trădătorii au preluat controlul stației.")
	elif progress() >= crew_tasks_required:
		end("ECHIPAJUL", "Toate sistemele stației au fost reparate.")

func end(winner: String, reason: String) -> void:
	if phase == "ended":
		return
	phase = "ended"
	result = {"winner": winner, "reason": reason}
	finished.emit(winner, reason)
