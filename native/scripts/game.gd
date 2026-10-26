extends Node3D
const Catalog = preload("res://scripts/catalog.gd")
const MatchRules = preload("res://scripts/match.gd")
const Station = preload("res://scripts/station.gd")
const Player = preload("res://scripts/player.gd")
const Astronaut = preload("res://scripts/astronaut.gd")
const Interface = preload("res://scripts/interface.gd")
const Sound = preload("res://scripts/sound.gd")
const Hunter = preload("res://scripts/hunter.gd")

var rules = MatchRules.new()
var station
var player
var ui
var audio
var actors: Dictionary = {}
var corpse_nodes: Dictionary = {}
var playing = false
var paused = false
var touch_enabled = false
var show_map = true
var think_timer = 0.0
var alarm_timer = 0.0
var notice_timer = 0.0
var meeting_age = 0.0
var capture_done = false
var automated = false
var simulation_test = false
var simulation_limit = 1200.0
var simulation_elapsed = 0.0
var quitting = false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	touch_enabled = OS.has_feature("android") or DisplayServer.is_touchscreen_available()
	station = Station.new()
	add_child(station)
	player = Player.new()
	add_child(player)
	player.position = Vector3(3.0, 0.1, 5.0)
	player.rotation.y = 0.3
	audio = Sound.new()
	add_child(audio)
	player.stepped.connect(func(): audio.play_effect("step"))
	var layer = CanvasLayer.new()
	add_child(layer)
	ui = Interface.new()
	ui.game = self
	layer.add_child(ui)
	rules.event.connect(on_event)
	rules.meeting_started.connect(on_meeting)
	rules.meeting_ended.connect(on_meeting_end)
	rules.finished.connect(on_result)
	ui.show_menu()
	var args = OS.get_cmdline_user_args()
	if "--bot-simulation" in args or "--bot-simulation-40" in args:
		simulation_test = true
		start_match(40 if "--bot-simulation-40" in args else 12, 5 if "--bot-simulation-40" in args else 2, "Astronaut", 742)
	elif "--integration" in args:
		automated = true
		integration_check.call_deferred()
	elif "--capture-hunter" in args or "--capture-hunter-touch" in args:
		automated = true
		touch_enabled = "--capture-hunter-touch" in args
		start_match(12, 2, "Hunter", 742)
		capture.call_deferred("hunter-touch" if touch_enabled else "hunter")
	elif "--capture-game" in args or "--capture-touch" in args or "--capture-meeting" in args:
		automated = true
		start_match(12, 2, "Astronaut", 1024)
		if "--capture-touch" in args:
			touch_enabled = true
		if "--capture-meeting" in args:
			rules.players[0].pos = Vector3(0, 0, 3)
			rules.call_meeting(0)
		capture.call_deferred("meeting" if "--capture-meeting" in args else ("touch" if touch_enabled else "game"))
	elif "--capture-menu" in args:
		automated = true
		capture.call_deferred("menu")

func start_match(total: int, traitors: int, role: String, seed_value: int = -1) -> void:
	clear_actors()
	rules.start(total, traitors, role, seed_value)
	playing = true
	paused = false
	think_timer = 0.0
	player.position = Vector3(0, 0.1, 4.0)
	player.rotation = Vector3.ZERO
	player.pitch = 0.0
	player.camera.rotation = Vector3.ZERO
	player.equip_hunter(role == "Hunter")
	rules.players[0].pos = player.position
	for p in rules.players:
		if p.id == 0:
			continue
		var actor = Astronaut.new()
		actor.id = p.id
		add_child(actor)
		actor.equip_hunter(p.role == "Hunter")
		var arm = p.id % 4
		var distance = 4.5 + float(p.id / 4) * 1.8
		var start = Vector3.ZERO
		if arm == 0:
			start = Vector3(0, 0, -distance)
		elif arm == 1:
			start = Vector3(distance, 0, 0)
		elif arm == 2:
			start = Vector3(0, 0, distance)
		else:
			start = Vector3(-distance, 0, 0)
		actor.position = start
		actor.wait = rules.rng.randf_range(0, 3)
		p.pos = start
		actors[p.id] = actor
	ui.clear_modal()
	ui.hud.visible = true
	player.enabled = true
	if not touch_enabled and not automated:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	notify("Rol secret: " + role + ". " + Catalog.ROLE_INFO[role], 9)

func clear_actors() -> void:
	for actor in actors.values():
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	for body in corpse_nodes.values():
		remove_child(body)
		body.queue_free()
	corpse_nodes.clear()

func back_to_menu() -> void:
	playing = false
	paused = false
	rules.phase = "lobby"
	player.enabled = false
	player.release_input()
	player.equip_hunter(false)
	clear_actors()
	station.set_alarm(false)
	ui.show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()

func shutdown() -> void:
	if quitting:
		return
	quitting = true
	player.enabled = false
	audio.stop_all()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			audio.toggle_mute()
		if event.physical_keycode == KEY_ESCAPE:
			if ui.current_modal == "task":
				close_task()
			elif playing and rules.phase == "active":
				toggle_pause()
		if not playing or paused or rules.phase != "active":
			return
		if ui.current_modal == "task":
			if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
				ui.task_press(event.physical_keycode - KEY_1 + 1)
			return
		match event.physical_keycode:
			KEY_E: interact()
			KEY_R: report()
			KEY_Q: ability()
			KEY_F: attack()
			KEY_TAB: show_map = not show_map
	if event is InputEventMouseButton and event.pressed and ui.current_modal == "" and playing and not touch_enabled:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event.button_index == MOUSE_BUTTON_LEFT and rules.players[0].role == "Hunter":
			shoot_hunter()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_pause() -> void:
	if not playing or rules.phase != "active":
		return
	if ui.current_modal == "task":
		close_task()
	paused = not paused
	player.enabled = not paused
	player.release_input()
	if paused:
		ui.show_pause()
	else:
		ui.clear_modal()
		if not touch_enabled and not automated:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not playing or quitting:
		return
	ui.update_hud()
	if paused:
		return
	if simulation_test:
		simulation_elapsed += delta
		if rules.phase == "meeting" and rules.players[0].alive and not rules.votes.has(0):
			rules.vote(0, -1)
		if rules.phase == "active" and rules.elapsed > 60:
			# Automated human task completion is explicitly test-only.
			for task in Catalog.TASKS:
				rules.complete_task(0, task.id)
		if rules.phase == "ended":
			print("BOT SIMULATION PASS: population=", rules.players.size(), " winner=", rules.result.winner, " reason=", rules.result.reason, " active_seconds=", rules.elapsed, " total_seconds=", simulation_elapsed)
			shutdown()
			return
		if simulation_elapsed > simulation_limit:
			push_error("BOT SIMULATION TIMEOUT")
			get_tree().quit(1)
	if notice_timer > 0:
		notice_timer -= delta
		if notice_timer <= 0:
			ui.notice.text = ""
	if rules.phase == "meeting":
		meeting_age += delta
		if not automated:
			bot_votes()
		rules.tick(delta)
		if rules.phase == "meeting" and rules.votes.size() >= rules.alive_count(true) + rules.alive_count(false):
			rules.resolve_votes()
		return
	if rules.phase != "active":
		return
	rules.players[0].pos = player.position
	player.equip_hunter(rules.players[0].role == "Hunter" and rules.players[0].alive)
	player.speed = 7.2 if rules.players[0].boost_until > rules.elapsed else 4.8
	rules.tick(delta)
	if rules.phase != "active":
		return
	station.set_alarm(rules.reactor_time > 0)
	if rules.reactor_time > 0:
		alarm_timer -= delta
		if alarm_timer <= 0:
			alarm_timer = 2.5
			audio.play_effect("alarm")
	for id in actors:
		var actor = actors[id]
		var p = rules.players[id]
		actor.visible = p.alive and p.hidden_until <= rules.elapsed
		actor.show_identity(p.mimic_id if p.mimic_until > rules.elapsed else -1)
		var shown_role = rules.players[p.mimic_id].role if p.mimic_until > rules.elapsed else p.role
		actor.equip_hunter(shown_role == "Hunter")
		if not p.alive:
			continue
		var moving = false
		if not automated and not actor.route.is_empty() and actor.wait <= 0:
			var destination = actor.route[0]
			var offset = destination - actor.position
			var distance = offset.length()
			if distance < 0.2:
				actor.route.remove_at(0)
			else:
				var step = minf(delta * 2.3, distance)
				actor.position += offset.normalized() * step
				actor.rotation.y = lerp_angle(actor.rotation.y, atan2(-offset.x, -offset.z), minf(delta * 9, 1))
				moving = true
		actor.wait = maxf(0, actor.wait - delta)
		actor.animate_walk(delta, moving)
		p.pos = actor.position
	think_timer -= delta
	if think_timer <= 0 and not automated:
		think_timer = 0.4
		bot_think()
	sync_bodies()

func bot_think() -> void:
	for id in actors:
		if rules.phase != "active":
			break
		var p = rules.players[id]
		var actor = actors[id]
		if not p.alive:
			# Ghosts finish assigned work slowly, keeping the shared objective attainable.
			if not p.traitor and rules.rng.randf() < 0.008:
				for task in Catalog.TASKS:
					if task.id not in p.tasks:
						rules.complete_task(id, task.id)
						break
			continue
		if p.role == "Hunter" and p.ammo > 0 and p.ability_cd <= 0:
			# Bots act on their own witnessed identity, not hidden team knowledge.
			for suspect in p.suspicion:
				var accused = rules.players[suspect]
				if not accused.alive or p.pos.distance_to(accused.pos) > Hunter.RANGE or not can_see(p.pos, accused.pos):
					continue
				actor.rotation.y = atan2(-(accused.pos.x - p.pos.x), -(accused.pos.z - p.pos.z))
				var eye = p.pos + Vector3.UP * 1.45
				var direction = (accused.pos + Vector3.UP * 1.3 - eye).normalized()
				var bot_trace = Hunter.trace(eye, direction, rules.players, id, get_world_3d().direct_space_state, [player.get_rid()])
				var bot_shot = rules.hunter_shot(id, bot_trace.target)
				if bot_shot.fired:
					actor.rifle.fire()
					audio.play_effect("rifle")
					sync_bodies()
				break
			if rules.phase != "active":
				return
		for body in rules.bodies:
			if not p.traitor and p.pos.distance_to(body.pos) < 3.0 and can_see(p.pos, body.pos):
				if rules.call_meeting(id, body.id):
					return
		if p.traitor and p.kill_cd <= 0:
			var victim = nearest_crew(p.pos, id, 2.7)
			if victim >= 0:
				var witnesses = 0
				for other in rules.players:
					if other.alive and not other.traitor and other.id != victim and other.pos.distance_to(p.pos) < 7 and can_see(other.pos, p.pos):
						witnesses += 1
				if witnesses == 0 or rules.rng.randf() < 0.035:
					attempt_kill(id, victim)
		if rules.phase != "active":
			return
		if p.traitor and rules.elapsed > 55 and rules.sabotage_cooldown <= 0 and rules.rng.randf() < 0.012:
			rules.sabotage(id)
		if actor.wait > 0:
			continue
		if not p.traitor and rules.reactor_time > 0:
			if rules.repair_reactor(id):
				actor.route.clear()
				actor.wait = 1.0
			elif actor.target_task not in [0, 4] or actor.route.is_empty():
				actor.target_task = 0 if id % 2 == 0 else 4
				actor.route = station.path(actor.position, approach(Catalog.TASKS[actor.target_task].pos))
			continue
		if actor.route.is_empty():
			if actor.target_task >= 0 and not p.traitor:
				rules.complete_task(id, actor.target_task)
			var available: Array[int] = []
			for task in Catalog.TASKS:
				if p.traitor or task.id not in p.tasks:
					available.append(task.id)
			if available.is_empty():
				actor.route = station.path(actor.position, Vector3(0, 0, 3.5))
				actor.target_task = -1
				actor.wait = rules.rng.randf_range(4, 8)
			else:
				actor.target_task = available[rules.rng.randi_range(0, available.size() - 1)]
				actor.route = station.path(actor.position, approach(Catalog.TASKS[actor.target_task].pos))
				actor.wait = rules.rng.randf_range(5, 9)

func approach(point: Vector3) -> Vector3:
	var center = Vector3.ZERO
	if absf(point.z) > 14:
		center.z = -20 if point.z < 0 else 20
	else:
		center.x = -20 if point.x < 0 else 20
	return point + (center - point).normalized() * 1.6

func bot_votes() -> void:
	for p in rules.players:
		if p.id == 0 or not p.alive or rules.votes.has(p.id) or meeting_age < 3.0 + float(p.id % 7) * 0.6:
			continue
		var target = -1
		for suspected in p.suspicion:
			if rules.players[suspected].alive:
				target = suspected
				break
		if target < 0:
			var testimonies: Array[int] = []
			for witness in rules.players:
				if witness.alive and not witness.traitor:
					for suspected in witness.suspicion:
						if rules.players[suspected].alive:
							testimonies.append(suspected)
			if not testimonies.is_empty() and rules.rng.randf() < 0.8 and not p.traitor:
				target = testimonies[0]
			elif p.traitor and rules.rng.randf() < 0.4:
				var crew: Array[int] = []
				for other in rules.players:
					if other.alive and not other.traitor:
						crew.append(other.id)
				if not crew.is_empty():
					target = crew[rules.rng.randi_range(0, crew.size() - 1)]
		rules.vote(p.id, target)

func nearest_crew(point: Vector3, except_id: int = 0, max_distance: float = 3.0) -> int:
	var result = -1
	var closest = max_distance
	for p in rules.players:
		if p.id == except_id or not p.alive or p.traitor:
			continue
		var distance = point.distance_to(p.pos)
		if distance < closest and can_see(point, p.pos):
			closest = distance
			result = p.id
	return result

func nearest_person() -> int:
	var result = -1
	var closest = 3.5
	for p in rules.players:
		if p.id == 0 or not p.alive:
			continue
		var distance = player.position.distance_to(p.pos)
		if distance < closest and can_see(player.position, p.pos):
			closest = distance
			result = p.id
	return result

func can_see(from: Vector3, to: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(from + Vector3.UP * 1.45, to + Vector3.UP * 1.45)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func nearby_task() -> int:
	var closest = 3.0
	var found = -1
	for task in Catalog.TASKS:
		var distance = player.position.distance_to(task.pos)
		if distance < closest and can_see(player.position, task.pos):
			closest = distance
			found = task.id
	return found

func nearby_body() -> int:
	for body in rules.bodies:
		if player.position.distance_to(body.pos) < 4.0 and can_see(player.position, body.pos):
			return body.id
	return -1

func context_prompt() -> String:
	if not playing or rules.phase != "active":
		return ""
	var human = rules.players[0]
	if nearby_body() >= 0 and human.alive:
		return "R   /   RAPORTEAZĂ VICTIMA"
	var task_id = nearby_task()
	if task_id >= 0:
		if human.traitor:
			return "E   /   SABOTEAZĂ REACTORUL" if human.alive else ""
		if task_id in [0, 4] and rules.reactor_time > 0 and human.alive:
			return "E   /   STABILIZEAZĂ REACTORUL"
		return "E   /   " + Catalog.TASKS[task_id].name if task_id not in human.tasks else "TERMINAL CALIBRAT"
	if player.position.distance_to(Vector3.ZERO) < 3.5 and human.alive:
		return "E   /   CONVOACĂ O ȘEDINȚĂ" if not human.emergency_used else "ȘEDINȚA TA DE URGENȚĂ A FOST FOLOSITĂ"
	if human.traitor and human.alive:
		var target = nearest_crew(player.position)
		if target >= 0:
			return "F   /   ELIMINĂ " + rules.players[target].name
	return ""

func can_act() -> bool:
	return playing and not paused and rules.phase == "active" and ui.current_modal == ""

func interact() -> void:
	if not can_act():
		return
	var human = rules.players[0]
	var task_id = nearby_task()
	if task_id >= 0:
		if human.traitor:
			if not rules.sabotage(0):
				notify("Sabotaj indisponibil. Pauză: %ds." % ceili(rules.sabotage_cooldown))
			return
		var repair = task_id in [0, 4] and rules.reactor_time > 0 and human.alive
		if task_id in human.tasks and not repair:
			notify("Ai calibrat deja acest terminal.")
			return
		player.enabled = false
		player.release_input()
		ui.show_task(task_id)
	elif not rules.call_meeting(0):
		notify("Apropie-te de un terminal sau de masa din nodul central.")

func close_task() -> void:
	if ui.current_modal != "task":
		return
	ui.clear_modal()
	player.enabled = rules.phase == "active" and not paused
	if not touch_enabled and not automated:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func finish_task(task_id: int) -> void:
	if ui.current_modal != "task" or rules.phase != "active":
		return
	# Keep the terminal interaction physically grounded, including ghost tasks.
	if player.position.distance_to(Catalog.TASKS[task_id].pos) > 3.1:
		close_task()
		return
	if task_id in [0, 4] and rules.reactor_time > 0 and rules.players[0].alive:
		rules.players[0].pos = player.position
		rules.repair_reactor(0)
	close_task()
	rules.complete_task(0, task_id)
	audio.play_effect("task")

func report() -> void:
	if not can_act():
		return
	var id = nearby_body()
	if id < 0 or not rules.call_meeting(0, id):
		notify("Nicio victimă în apropiere.")

func attack() -> void:
	if not can_act():
		return
	var human = rules.players[0]
	if human.role == "Hunter":
		shoot_hunter()
		return
	if not human.traitor or not human.alive:
		notify("Acest rol nu poate elimina participanți.")
		return
	var target = nearest_crew(player.position)
	if target < 0:
		notify("Ținta trebuie să fie la mai puțin de 2,8 metri, fără obstacole.")
	elif not attempt_kill(0, target):
		notify("Eliminare indisponibilă. Pauză: %ds." % ceili(human.kill_cd))

func attempt_kill(attacker: int, victim: int) -> bool:
	if not can_see(rules.players[attacker].pos, rules.players[victim].pos):
		return false
	var a = rules.players[attacker]
	var hidden = a.hidden_until > rules.elapsed
	var apparent_id = a.mimic_id if a.mimic_until > rules.elapsed else attacker
	if not rules.try_kill(attacker, victim):
		return false
	if attacker == 0:
		player.reveal_time = 1.5
	elif actors.has(attacker):
		actors[attacker].reveal()
	for p in rules.players:
		if p.alive and not p.traitor and p.id != victim and not hidden and p.pos.distance_to(a.pos) < 9 and can_see(p.pos, a.pos):
			rules.witness(p.id, apparent_id)
	audio.play_effect("attack")
	sync_bodies()
	if victim == 0 and ui.current_modal == "task":
		close_task()
	return true

func shoot_hunter() -> Dictionary:
	var empty = {"fired": false, "killed": false, "target": -1}
	if not can_act():
		return empty
	var human = rules.players[0]
	if human.role != "Hunter" or not human.alive:
		return empty
	if human.ammo <= 0:
		notify("Winchester: nu mai ai cartușe.")
		return empty
	if human.ability_cd > 0:
		notify("Winchester: pregătești următorul foc · %ds." % ceili(human.ability_cd))
		return empty
	human.pos = player.position
	var trace = Hunter.trace(player.camera.global_position, -player.camera.global_basis.z, rules.players, 0, get_world_3d().direct_space_state, [player.get_rid()])
	var shot = rules.hunter_shot(0, trace.target)
	if not shot.fired:
		return shot
	player.rifle.fire()
	audio.play_effect("rifle")
	if rules.phase == "active":
		notify("Trădător eliminat. Cartușe: %d." % human.ammo if shot.killed else "Foc tras. Cartușe: %d. Echipajul este protejat." % human.ammo)
	sync_bodies()
	return shot

func ability() -> void:
	if not can_act():
		return
	var p = rules.players[0]
	if not p.alive or p.ability_cd > 0:
		notify("Abilitatea nu este disponibilă acum.")
		return
	var target = nearest_person()
	match p.role:
		"Hunter":
			shoot_hunter()
			return
		"Astronaut", "Inginer":
			var closest = -1
			var distance = INF
			for task in Catalog.TASKS:
				if task.id not in p.tasks and player.position.distance_to(task.pos) < distance:
					closest = task.id
					distance = player.position.distance_to(task.pos)
			if closest >= 0:
				notify("Următoarea misiune: " + Catalog.TASKS[closest].name + " · %dm în linie dreaptă." % distance, 7)
			else:
				notify("Misiunile tale sunt gata. Observă echipajul și raportează incidentele.")
			p.ability_cd = 3.0
		"Medic":
			if target < 0:
				notify("Apropie-te de un astronaut pentru a-l proteja.")
				return
			rules.players[target].protected_until = rules.elapsed + 20
			p.ability_cd = 35
			notify("Protecție medicală activă pentru " + rules.players[target].name + ".")
		"Gardian":
			p.protected_until = rules.elapsed + 15
			p.ability_cd = 35
			notify("Scut personal activ: 15 secunde.")
		"Detectiv":
			var body_id = nearby_body()
			if body_id < 0:
				notify("Analiza necesită o victimă în apropiere.")
				return
			for body in rules.bodies:
				if body.id == body_id:
					notify("Urme de costum: identitatea " + rules.players[body.killer].name + ". Analiza de prototip indică atacatorul real.", 10)
			p.ability_cd = 12
		"Sabotor":
			if not rules.sabotage(0):
				notify("Sabotaj disponibil în %ds." % ceili(rules.sabotage_cooldown))
				return
			p.ability_cd = 30
		"Mimetic":
			if target < 0:
				notify("Apropie-te de cineva pentru a-i copia identitatea.")
				return
			p.mimic_id = target
			p.mimic_until = rules.elapsed + 12
			p.ability_cd = 35
			notify("Identitate copiată: " + rules.players[target].name + " · 12 secunde.")
		"Umbră":
			p.hidden_until = rules.elapsed + 8
			p.ability_cd = 35
			notify("Camuflaj activ: 8 secunde. Atacul îl întrerupe.")
		"Asasin":
			p.boost_until = rules.elapsed + 6
			p.ability_cd = 30
			notify("Accelerație activă: 6 secunde.")
		"Hacker":
			rules.sensors_off = 20
			p.ability_cd = 40
			notify("Senzorii stației au fost dezactivați: 20 secunde.")
	audio.play_effect("ui")

func sync_bodies() -> void:
	for id in actors:
		if not rules.players[id].alive:
			actors[id].visible = false
	var existing: Array[int] = []
	for body in rules.bodies:
		existing.append(body.id)
		if not corpse_nodes.has(body.id):
			var corpse = Astronaut.new()
			corpse.id = body.id
			add_child(corpse)
			corpse.position = body.pos
			corpse.become_body()
			corpse.equip_hunter(rules.players[body.id].role == "Hunter")
			corpse_nodes[body.id] = corpse
	for id in corpse_nodes.keys():
		if id not in existing:
			var body = corpse_nodes[id]
			remove_child(body)
			body.queue_free()
			corpse_nodes.erase(id)

func on_event(message: String) -> void:
	notify(message, 8)

func notify(message: String, duration: float = 5) -> void:
	if is_instance_valid(ui) and is_instance_valid(ui.notice):
		ui.notice.text = message
		notice_timer = duration

func on_meeting() -> void:
	meeting_age = 0.0
	player.enabled = false
	player.release_input()
	ui.show_meeting()
	audio.play_effect("meeting")

func on_meeting_end(message: String) -> void:
	ui.clear_modal()
	player.enabled = true
	if not touch_enabled and not automated:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sync_bodies()
	notify(message, 9)

func on_result(winner: String, reason: String) -> void:
	player.enabled = false
	player.release_input()
	station.set_alarm(false)
	ui.show_result(winner, reason)
	audio.play_effect("task")

func capture(kind: String) -> void:
	for i in 30:
		await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var evidence = OS.get_environment("SPACE_BETRAYAL_EVIDENCE")
		if evidence.is_empty():
			evidence = ProjectSettings.globalize_path("res://artifacts")
		DirAccess.make_dir_recursive_absolute(evidence)
		var path = evidence.path_join(kind + ".png")
		var error = get_viewport().get_texture().get_image().save_png(path)
		print("CAPTURE ", kind, " ", error)
	shutdown()

func integration_check() -> void:
	start_match(12, 2, "Inginer", 742)
	for i in 5:
		await get_tree().physics_frame
	# Exercise the actual terminal UI and completion callback.
	player.position = approach(Catalog.TASKS[2].pos)
	rules.players[0].pos = player.position
	await get_tree().physics_frame
	interact()
	if ui.current_modal != "task":
		push_error("INTEGRATION: terminal did not open")
		get_tree().quit(1)
		return
	var sequence = ui.task_sequence.duplicate()
	for number in sequence:
		ui.task_press(number)
	if 2 not in rules.players[0].tasks or ui.current_modal != "":
		push_error("INTEGRATION: task completion failed")
		get_tree().quit(1)
		return
	# Pausing must stop all simulation clocks.
	toggle_pause()
	var before = rules.elapsed
	for i in 5:
		await get_tree().process_frame
	if rules.elapsed != before:
		push_error("INTEGRATION: pause advanced clock")
		get_tree().quit(1)
		return
	toggle_pause()
	# Touch controls go through the real Player input handlers.
	var press = InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(100, 500)
	press.pressed = true
	player._input(press)
	var drag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(100, 450)
	player._input(drag)
	if player.touch_move.y >= 0:
		push_error("INTEGRATION: touch movement failed")
		get_tree().quit(1)
		return
	player.release_input()
	# Use the touch vector to walk into a physical wall; collision must stop us.
	player.position = Vector3(0, 0.1, 11)
	player.rotation.y = -PI / 2
	player.touch_move = Vector2(0, -1)
	for i in 75:
		await get_tree().physics_frame
	if player.position.x > 1.7 or player.position.x < 0.5:
		push_error("INTEGRATION: wall collision failed, x=" + str(player.position.x))
		get_tree().quit(1)
		return
	player.release_input()
	# Real report UI, ballot and victory screen.
	player.position = Vector3(0, 0, 3)
	rules.players[0].pos = player.position
	interact()
	if rules.phase != "meeting" or ui.current_modal != "meeting":
		push_error("INTEGRATION: meeting failed")
		get_tree().quit(1)
		return
	ui.cast_vote(-1)
	rules.resolve_votes()
	if rules.phase != "active" or ui.current_modal != "":
		push_error("INTEGRATION: vote return failed")
		get_tree().quit(1)
		return
	for p in rules.players:
		if not p.traitor:
			for task in Catalog.TASKS:
				rules.complete_task(p.id, task.id)
	if rules.phase != "ended" or ui.current_modal != "result":
		push_error("INTEGRATION: result screen failed")
		get_tree().quit(1)
		return
	# Exercise each role through the same public ability entry point as keyboard/touch.
	for role in Catalog.CREW_ROLES + Catalog.TRAITOR_ROLES:
		start_match(12, 2, role, 742)
		var human = rules.players[0]
		human.ability_cd = 0.0
		rules.sabotage_cooldown = 0.0
		player.position = Vector3(0, 0.1, 4)
		human.pos = player.position
		rules.players[1].pos = Vector3(1, 0, 4)
		actors[1].position = rules.players[1].pos
		if role == "Detectiv":
			var killer = -1
			var victim = -1
			for p in rules.players:
				if p.id != 0 and p.id != 1:
					if p.traitor:
						killer = p.id
					else:
						victim = p.id
			rules.players[killer].pos = Vector3(0, 0, 4)
			rules.players[victim].pos = Vector3(0, 0, 4)
			rules.players[killer].kill_cd = 0.0
			rules.try_kill(killer, victim)
		ability()
		if human.ability_cd <= 0:
			push_error("INTEGRATION: role ability failed: " + role)
			get_tree().quit(1)
			return
	print("INTEGRATION PASS: terminal puzzle, pause, touch input, wall collision, meeting, skip, task victory, result UI, all ", (Catalog.CREW_ROLES + Catalog.TRAITOR_ROLES).size(), " role actions")
	audio.stop_all()
	for i in 3:
		await get_tree().process_frame
	get_tree().quit()
