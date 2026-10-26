extends SceneTree

var game
var failures = 0

func _initialize() -> void:
	run.call_deferred()

func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("TOUCH UI FAIL: " + message)

func wait_layout() -> void:
	for i in 5:
		await process_frame

func find_button(words: String) -> BaseButton:
	for node in game.ui.find_children("*", "BaseButton", true, false):
		if node.is_visible_in_tree() and words in node.text:
			return node
	return null

func screen_point(control: Control) -> Vector2:
	return root.get_screen_transform() * control.get_global_rect().get_center()

func tap(point: Vector2, finger: int = 0) -> void:
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
	await wait_layout()

func run() -> void:
	if "--emulate-mouse" in OS.get_cmdline_user_args():
		Input.emulate_mouse_from_touch = true
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.automated = true
	game.touch_enabled = true
	game.ui.show_menu()
	await wait_layout()
	var role_choices = game.ui.modal.find_children("*", "OptionButton", true, false)[0]
	var has_hunter = false
	for i in role_choices.item_count:
		if role_choices.get_item_text(i) == "Hunter":
			has_hunter = true
	expect(has_hunter, "Hunter is selectable in the role menu")
	# Also keep pointer emulation from activating toggles twice.
	var toggle = find_button("Comenzi tactile")
	var initial_toggle = toggle.button_pressed
	await tap(screen_point(toggle))
	expect(toggle.button_pressed != initial_toggle, "touch toggles the control exactly once")
	await tap(screen_point(toggle))
	expect(toggle.button_pressed == initial_toggle, "second touch restores the toggle")
	# Standard numeric selectors need the same pointer path as Android menus.
	var spinboxes = game.ui.modal.find_children("*", "SpinBox", true, false)
	var spin = spinboxes[0]
	var arrow = spin.get_global_rect().position + Vector2(spin.size.x - 6, 6)
	await tap(root.get_screen_transform() * arrow)
	expect(spin.value == 13, "touch increments the participant selector exactly once")
	var start = find_button("INTRĂ PE")
	expect(is_instance_valid(start), "start button exists")
	if is_instance_valid(start):
		await tap(screen_point(start))
	expect(game.playing and game.rules.phase == "active", "raw screen touch activates Start through GUI")
	if failures == 0:
		# The native GUI still receives a second finger while a joystick finger is held.
		var held = InputEventScreenTouch.new()
		held.index = 0
		held.position = Vector2(100, 500)
		held.pressed = true
		Input.parse_input_event(held)
		await process_frame
		var role_button = find_button("Q · Rol")
		await tap(screen_point(role_button), 1)
		expect(game.rules.players[0].ability_cd > 0, "second-finger role button works during joystick hold")
		held.pressed = false
		Input.parse_input_event(held)
		await process_frame
		var pause_button = find_button("Ⅱ")
		await tap(screen_point(pause_button))
		expect(game.paused and game.ui.current_modal == "pause", "touch opens pause")
		var resume = find_button("Continuă")
		await tap(screen_point(resume))
		expect(not game.paused and game.ui.current_modal == "", "touch resumes")
	print("TOUCH UI: ", failures, " failures; emulation=", Input.emulate_mouse_from_touch)
	game.audio.stop_all()
	await wait_layout()
	quit(1 if failures else 0)
