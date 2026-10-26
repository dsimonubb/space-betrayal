extends SceneTree
const Rules = preload("res://scripts/match.gd")
const Hunter = preload("res://scripts/hunter.gd")
var checks = 0
var failures = 0
var game

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("HUNTER FAIL: " + message)

func _initialize() -> void:
	run.call_deferred()

func new_rules(total: int = 12, traitors: int = 2):
	var rules = Rules.new()
	rules.start(total, traitors, "Hunter", 742)
	return rules

func traitor_id(rules) -> int:
	for p in rules.players:
		if p.traitor:
			return p.id
	return -1

func crew_id(rules) -> int:
	for p in rules.players:
		if p.id != 0 and not p.traitor:
			return p.id
	return -1

func frames(count: int = 5) -> void:
	for i in count:
		await process_frame

func tap(control: Control, finger: int = 0) -> void:
	var point = root.get_screen_transform() * control.get_global_rect().get_center()
	var down = InputEventScreenTouch.new()
	down.index = finger
	down.position = point
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up = InputEventScreenTouch.new()
	up.index = finger
	up.position = point
	up.pressed = false
	Input.parse_input_event(up)
	await frames()

func position_scene() -> void:
	game.start_match(12, 2, "Hunter", 742)
	# Empty north corridor, clear of the meeting table and room props.
	game.player.position = Vector3(0, 0.01, -7)
	game.player.rotation = Vector3.ZERO
	game.player.pitch = 0
	game.player.camera.rotation = Vector3.ZERO
	game.rules.players[0].pos = game.player.position
	for p in game.rules.players:
		if p.id != 0:
			p.pos = Vector3(20, 0, 0)
			game.actors[p.id].position = p.pos

func run() -> void:
	var r = new_rules()
	expect(r.players[0].role == "Hunter" and not r.players[0].traitor, "Hunter is crew")
	expect(r.players[0].ammo == 3, "starts with three cartridges")
	expect(r.alive_count(true) == 2, "Hunter does not change selected traitor count")
	expect(r.complete_task(0, 0), "Hunter completes crew tasks")
	expect(not r.sabotage(0), "Hunter cannot sabotage")
	var crew = crew_id(r)
	var traitor = traitor_id(r)
	var shot = r.hunter_shot(0, crew)
	expect(shot.fired and not shot.killed and r.players[crew].alive, "crew survives a shot")
	expect(r.players[0].alive, "Hunter is not penalized for crew contact")
	expect(r.players[0].ammo == 2, "crew contact consumes one cartridge")
	expect(not r.hunter_shot(0, traitor).fired and r.players[0].ammo == 2, "cycle prevents duplicate shots")
	r.tick(Hunter.CYCLE_SECONDS + 0.01)
	r.players[traitor].pos = Vector3(20, 0, 0)
	shot = r.hunter_shot(0, traitor)
	expect(shot.killed and not r.players[traitor].alive, "ranged shot kills traitor")
	expect(r.bodies.size() == 1 and r.bodies[0].killer == 0, "Hunter elimination creates a reportable body")
	r.tick(Hunter.CYCLE_SECONDS + 0.01)
	expect(r.hunter_shot(0).fired and r.players[0].ammo == 0, "miss consumes last cartridge")
	r.tick(Hunter.CYCLE_SECONDS + 0.01)
	expect(not r.hunter_shot(0).fired and r.players[0].ammo == 0, "empty rifle cannot fire or underflow")
	r = new_rules()
	traitor = traitor_id(r)
	r.players[traitor].protected_until = 15
	shot = r.hunter_shot(0, traitor)
	expect(shot.fired and not shot.killed and r.players[traitor].alive, "shield blocks Hunter shot")
	r = new_rules()
	traitor = traitor_id(r)
	r.players[traitor].pos = Vector3(26, 0, 0)
	expect(not r.hunter_shot(0, traitor).killed, "range limited")
	r = new_rules()
	expect(not r.hunter_shot(-1).fired and not r.hunter_shot(0, 999).fired, "invalid IDs rejected")
	expect(not r.hunter_shot(traitor_id(r)).fired, "traitor cannot use Hunter API")
	r.players[0].alive = false
	expect(not r.hunter_shot(0).fired, "dead Hunter cannot fire")
	r = new_rules()
	r.call_meeting(0)
	expect(not r.hunter_shot(0).fired, "meeting blocks shooting")
	r.resolve_votes()
	expect(r.players[0].ability_cd >= Hunter.CYCLE_SECONDS, "meeting exit preserves safety cycle")
	r = new_rules(12, 1)
	shot = r.hunter_shot(0, traitor_id(r))
	expect(shot.killed and r.result.get("winner") == "ECHIPAJUL", "shooting last traitor wins for crew")

	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.automated = true
	game.touch_enabled = true
	position_scene()
	await frames()
	expect(game.player.rifle.visible and game.player.hunter_equipped, "first person Winchester equipped at spawn")
	traitor = traitor_id(game.rules)
	crew = crew_id(game.rules)
	game.rules.players[traitor].pos = Vector3(0, 0, -15)
	game.actors[traitor].position = game.rules.players[traitor].pos
	game.rules.players[crew].pos = Vector3(0, 0, -11)
	game.actors[crew].position = game.rules.players[crew].pos
	await frames()
	shot = game.shoot_hunter()
	expect(shot.target == crew and not shot.killed, "front crew blocks traitor behind them")
	expect(game.rules.players[traitor].alive and game.rules.players[crew].alive, "shot never passes through crew")
	game.rules.players[0].ability_cd = 0
	game.rules.players[crew].pos = Vector3(20, 0, 0)
	game.actors[crew].position = game.rules.players[crew].pos
	await frames()
	shot = game.shoot_hunter()
	expect(shot.target == traitor and shot.killed, "crosshair selects visible traitor")
	expect(game.player.rifle.cycle > 0, "rifle animates after shot")

	position_scene()
	traitor = traitor_id(game.rules)
	# West/east rooms are separated from this corridor by a real wall.
	game.rules.players[traitor].pos = Vector3(10, 0, -7)
	game.actors[traitor].position = game.rules.players[traitor].pos
	game.player.rotation.y = -PI / 2
	await frames()
	shot = game.shoot_hunter()
	expect(shot.fired and not shot.killed and shot.target == -1, "physical wall blocks ray")
	expect(game.rules.players[traitor].alive, "wall preserves target")
	game.rules.players[0].ability_cd = 0
	game.toggle_pause()
	expect(not game.shoot_hunter().fired, "UI pause blocks shooting")
	game.toggle_pause()

	position_scene()
	await frames()
	# Native touch passes through Input and the actual GUI, not a direct callback.
	var held = InputEventScreenTouch.new()
	held.index = 0
	held.position = Vector2(100, 500)
	held.pressed = true
	Input.parse_input_event(held)
	await process_frame
	await tap(game.ui.role_button, 1)
	expect(game.rules.players[0].ammo == 2, "Android fire button consumes exactly one cartridge with second finger")
	held.pressed = false
	Input.parse_input_event(held)
	position_scene()
	game.touch_enabled = false
	if DisplayServer.get_name() == "headless":
		print("SKIP: captured left-click check requires a window; run rendered Hunter test")
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await frames()
		var mouse_down = InputEventMouseButton.new()
		mouse_down.button_index = MOUSE_BUTTON_LEFT
		mouse_down.position = root.get_screen_transform() * Vector2(640, 360)
		mouse_down.pressed = true
		Input.parse_input_event(mouse_down)
		await frames()
		expect(game.rules.players[0].ammo == 2, "PC left click dispatch fires exactly once")
		mouse_down.pressed = false
		Input.parse_input_event(mouse_down)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	position_scene()
	await frames()
	var key = InputEventKey.new()
	key.physical_keycode = KEY_F
	key.pressed = true
	Input.parse_input_event(key)
	await frames()
	expect(game.rules.players[0].ammo == 2, "PC F key dispatch fires")
	key.pressed = false
	Input.parse_input_event(key)
	game.start_match(12, 2, "Astronaut", 742)
	await frames()
	expect(not game.player.rifle.visible and not game.player.hunter_equipped, "rifle removed on non-Hunter rematch")
	print("HUNTER: %d checks, %d failures" % [checks, failures])
	game.audio.stop_all()
	await frames()
	quit(1 if failures else 0)
