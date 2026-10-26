extends SceneTree
const Rules = preload("res://scripts/match.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks = 0
var failures = 0

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func make_match(total: int = 12, traitors: int = 2, role: String = "Astronaut"):
	var rules = Rules.new()
	rules.start(total, traitors, role, 742)
	return rules

func find_traitor(rules) -> int:
	for p in rules.players:
		if p.traitor:
			return p.id
	return -1

func find_crew(rules, excluded: int = -1) -> int:
	for p in rules.players:
		if not p.traitor and p.id != excluded:
			return p.id
	return -1

func _initialize() -> void:
	for size in [12, 24, 40]:
		for traitors in range(1, 6):
			for role in Catalog.CREW_ROLES + Catalog.TRAITOR_ROLES:
				var r = make_match(size, traitors, role)
				expect(r.players.size() == size, "population")
				expect(r.alive_count(true) == traitors, "exact traitor count")
				expect(r.players[0].role == role, "selected human role")
				expect(r.crew_tasks_required == (size - traitors) * 6, "shared task denominator")
	var r = make_match()
	expect(not r.complete_task(-1, 0), "reject negative actor ID")
	expect(not r.complete_task(0, -1), "reject negative task ID")
	expect(not r.complete_task(0, 6), "reject absent task")
	expect(r.complete_task(0, 0), "crew task")
	expect(not r.complete_task(0, 0), "duplicate task does not count")
	expect(r.progress() == 1, "task deduplication")
	var killer = find_traitor(r)
	var victim = find_crew(r)
	expect(not r.complete_task(killer, 1), "traitor cannot advance crew tasks")
	r.players[killer].kill_cd = 0
	r.players[killer].pos = Vector3(10, 0, 0)
	expect(not r.try_kill(killer, victim), "out of range miss")
	r.players[killer].pos = Vector3.ZERO
	r.players[victim].protected_until = 20
	expect(not r.try_kill(killer, victim), "shield blocks attack")
	expect(r.players[victim].alive, "shield preserves life")
	r.players[victim].protected_until = -1
	r.players[killer].kill_cd = 0
	expect(r.try_kill(killer, victim), "valid contact elimination")
	expect(not r.try_kill(killer, victim), "duplicate elimination rejected")
	expect(r.bodies.size() == 1, "one body per victim")
	expect(not r.call_meeting(victim, victim), "dead actor cannot report")
	var reporter = find_crew(r, victim)
	r.players[reporter].pos = Vector3(10, 0, 0)
	expect(not r.call_meeting(reporter, victim), "distant report rejected")
	r.players[reporter].pos = Vector3.ZERO
	expect(r.call_meeting(reporter, victim), "body report starts meeting")
	expect(not r.try_kill(killer, reporter), "attacks blocked in meeting")
	expect(not r.complete_task(reporter, 1), "tasks blocked in meeting")
	expect(not r.vote(victim, killer), "dead actor cannot vote")
	expect(r.vote(reporter, killer), "living vote accepted")
	expect(not r.vote(reporter, killer), "double vote rejected")
	for p in r.players:
		if p.alive:
			r.vote(p.id, -1)
	r.resolve_votes()
	expect(r.players[killer].alive, "skip majority preserves suspect")
	expect(r.bodies.is_empty(), "meeting clears bodies")
	r = make_match(12, 1)
	killer = find_traitor(r)
	expect(r.call_meeting(0), "emergency at central table")
	for p in r.players:
		r.vote(p.id, killer)
	r.resolve_votes()
	expect(r.phase == "ended" and r.result.winner == "ECHIPAJUL", "last traitor ejected wins")
	r = make_match()
	r.call_meeting(0)
	for p in r.players:
		r.vote(p.id, 1 if p.id < 6 else 2)
	r.resolve_votes()
	expect(r.players[1].alive and r.players[2].alive, "tied ballot ejects nobody")
	expect(not r.call_meeting(0), "one emergency per participant")
	r = make_match()
	killer = find_traitor(r)
	expect(not r.sabotage(killer), "initial sabotage cooldown")
	r.tick(36)
	expect(r.sabotage(killer), "sabotage starts after cooldown")
	expect(not r.sabotage(killer), "duplicate sabotage rejected")
	r.players[0].pos = Vector3.ZERO
	expect(not r.repair_reactor(0), "repair requires reactor proximity")
	r.players[0].pos = Catalog.TASKS[0].pos
	expect(r.repair_reactor(0), "reactor repaired nearby")
	expect(r.reactor_time < 0, "repair clears alarm")
	r.sabotage_cooldown = 0
	r.sabotage(killer)
	r.call_meeting(1, -1)
	# Emergency meetings are disabled during an active reactor failure.
	expect(r.phase == "active", "reactor blocks emergency meeting")
	r.tick(76)
	expect(r.phase == "ended" and r.result.winner == "TRĂDĂTORII", "reactor timeout victory")
	r = make_match()
	r.tick(36)
	r.sabotage(find_traitor(r))
	var body_victim = find_crew(r, 0)
	killer = find_traitor(r)
	r.players[killer].kill_cd = 0
	r.try_kill(killer, body_victim)
	r.call_meeting(0, body_victim)
	var time_left = r.reactor_time
	r.tick(10)
	expect(r.reactor_time == time_left, "reactor clock pauses in meeting")
	r = make_match()
	for p in r.players:
		if not p.traitor:
			for task in Catalog.TASKS:
				r.complete_task(p.id, task.id)
	expect(r.phase == "ended" and r.result.winner == "ECHIPAJUL", "all tasks wins")
	r = make_match()
	var remaining = r.alive_count(false)
	for p in r.players:
		if not p.traitor and remaining > 2:
			p.alive = false
			remaining -= 1
	r.check_win()
	expect(r.phase == "ended" and r.result.winner == "TRĂDĂTORII", "parity victory")
	print("RULES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
