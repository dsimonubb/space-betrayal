extends Control
const Catalog = preload("res://scripts/catalog.gd")
const ACCENT = Color("74e6d3")
const INK = Color("dce9eb")
var game
var hud: Control
var modal: Control
var status: Label
var location_label: Label
var objective: Label
var prompt: Label
var notice: Label
var cooldown: Label
var alert: Label
var meeting_clock: Label
var task_bar: ProgressBar
var touch_controls: Control
var current_modal = ""
var task_sequence: Array[int] = []
var task_index = 0
var task_id = -1
var task_hint: Label
var task_state: Label
var role_button: Button
var attack_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_resource = Theme.new()
	theme_resource.default_font_size = 18
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("17323d")
	button_style.border_color = Color("3c727c")
	button_style.set_border_width_all(1)
	button_style.set_corner_radius_all(5)
	button_style.content_margin_left = 16
	button_style.content_margin_right = 16
	button_style.content_margin_top = 12
	button_style.content_margin_bottom = 12
	theme_resource.set_stylebox("normal", "Button", button_style)
	var hover = button_style.duplicate()
	hover.bg_color = Color("24515a")
	hover.border_color = ACCENT
	theme_resource.set_stylebox("hover", "Button", hover)
	theme_resource.set_stylebox("pressed", "Button", hover)
	theme_resource.set_stylebox("normal", "OptionButton", button_style)
	theme_resource.set_color("font_color", "Label", INK)
	theme_resource.set_color("font_color", "Button", INK)
	theme = theme_resource
	build_hud()

func label(parent: Node, words: String, size: int = 18, color: Color = INK) -> Label:
	var node = Label.new()
	node.text = words
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func button(parent: Node, words: String, callback: Callable) -> Button:
	var node = Button.new()
	node.text = words
	node.custom_minimum_size.y = 46
	parent.add_child(node)
	node.pressed.connect(func():
		game.audio.play_effect("ui")
		callback.call())
	return node

func place(node: Control, anchors: Vector4, offsets: Vector4) -> void:
	node.anchor_left = anchors.x
	node.anchor_top = anchors.y
	node.anchor_right = anchors.z
	node.anchor_bottom = anchors.w
	node.offset_left = offsets.x
	node.offset_top = offsets.y
	node.offset_right = offsets.z
	node.offset_bottom = offsets.w

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var top = VBoxContainer.new()
	hud.add_child(top)
	place(top, Vector4(0, 0, 0, 0), Vector4(32, 24, 420, 210))
	label(top, "OMEGA—9   /   LEGĂTURĂ LOCALĂ", 14, ACCENT)
	status = label(top, "", 22)
	task_bar = ProgressBar.new()
	task_bar.custom_minimum_size = Vector2(320, 6)
	task_bar.show_percentage = false
	top.add_child(task_bar)
	objective = label(top, "", 15, Color("9dafb8"))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 350
	location_label = label(hud, "", 17)
	place(location_label, Vector4(0.5, 0, 0.5, 0), Vector4(-230, 28, 230, 60))
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt = label(hud, "", 21, ACCENT)
	place(prompt, Vector4(0.5, 0.65, 0.5, 0.65), Vector4(-440, 0, 440, 80))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice = label(hud, "", 18)
	place(notice, Vector4(0.5, 1, 0.5, 1), Vector4(-470, -120, 470, -64))
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cooldown = label(hud, "", 16, Color("9dafb8"))
	place(cooldown, Vector4(0, 1, 0, 1), Vector4(32, -56, 780, -24))
	alert = label(hud, "", 24, Color("ff997f"))
	place(alert, Vector4(0.5, 0, 0.5, 0), Vector4(-400, 78, 400, 118))
	alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(hud, "Ⅱ", game.toggle_pause)
	var pause_button = hud.get_child(hud.get_child_count() - 1)
	place(pause_button, Vector4(1, 0, 1, 0), Vector4(-82, 24, -28, 70))
	touch_controls = Control.new()
	touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(touch_controls)
	var actions = HBoxContainer.new()
	touch_controls.add_child(actions)
	place(actions, Vector4(1, 1, 1, 1), Vector4(-470, -78, -28, -24))
	button(actions, "E · Folosește", game.interact)
	button(actions, "R · Raport", game.report)
	role_button = button(actions, "Q · Rol", game.ability)
	attack_button = button(actions, "F · Atac", game.attack)
	hud.visible = false

func clear_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
	current_modal = ""
	game.player.release_input()

func sheet(kind: String, title: String, subtitle: String, width: float = 730, height: float = 570) -> VBoxContainer:
	clear_modal()
	current_modal = kind
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade = ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.055, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.09, 0.96)
	style.border_color = Color("3a6770")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	modal.add_child(panel)
	place(panel, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-width / 2, -height / 2, width / 2, height / 2))
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	label(content, "OMEGA—9    /    PROTOTIP 0.2 · HUNTER", 13, ACCENT)
	label(content, title, 34)
	var description = label(content, subtitle, 17, Color("a0b6bd"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return content

func show_menu() -> void:
	hud.visible = false
	var content = sheet("menu", "SPACE BETRAYAL", "2189. Stația răspunde. Echipajul nu mai inspiră încredere.\nPerspectivă la persoana întâi · partidă locală cu boți.", 740, 650)
	var row = HBoxContainer.new()
	content.add_child(row)
	label(row, "Participanți: ")
	var total = SpinBox.new()
	total.min_value = 12
	total.max_value = 40
	total.value = 12
	row.add_child(total)
	label(row, "    Trădători: ")
	var traitors = SpinBox.new()
	traitors.min_value = 1
	traitors.max_value = 5
	traitors.value = 2
	row.add_child(traitors)
	label(content, "Rolul tău pentru test", 16, ACCENT)
	var roles = OptionButton.new()
	for role in Catalog.CREW_ROLES + Catalog.TRAITOR_ROLES:
		roles.add_item(role)
	content.add_child(roles)
	var description = label(content, Catalog.ROLE_INFO.Astronaut, 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roles.item_selected.connect(func(index): description.text = Catalog.ROLE_INFO[roles.get_item_text(index)])
	var touch_toggle = CheckButton.new()
	touch_toggle.text = "Comenzi tactile / Android"
	touch_toggle.button_pressed = game.touch_enabled
	content.add_child(touch_toggle)
	touch_toggle.toggled.connect(func(value): game.touch_enabled = value)
	var instructions = label(content, "PC: W A S D · mouse · E interacțiune · R raport · Q abilitate\nF eliminare (trădător) · Tab hartă · Esc pauză · M sunet\nAndroid: joystick stânga · privire în dreapta · butoane de acțiune", 15, Color("a0b6bd"))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(content, "INTRĂ PE OMEGA—9   →", func(): game.start_match(int(total.value), int(traitors.value), roles.get_item_text(roles.selected)))
	var note = label(content, "Disponibil acum: OMEGA-9 și 11 roluri, inclusiv Hunter cu Winchester.\nOnline, celelalte 4 hărți și modelele realiste finale sunt în plan.", 14, Color("8ba0aa"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(content, "Licențe și credite", show_credits)
	button(content, "Închide jocul", game.shutdown)

func show_credits() -> void:
	var content = sheet("credits", "LICENȚE ȘI CREDITE", "Space Betrayal 0.1 · decor, modele temporare și sunete originale.\nRealizat cu Godot Engine. Nu este un produs Innersloth.", 850, 650)
	button(content, "Înapoi la meniu", show_menu)
	var text = label(content, FileAccess.get_file_as_string("res://GODOT_COPYRIGHT.txt"), 13)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func show_pause() -> void:
	var content = sheet("pause", "SEMNAL ÎN AȘTEPTARE", "Partida locală este oprită.", 620, 440)
	button(content, "Continuă", game.toggle_pause)
	button(content, "Sunet: pornit / oprit", func(): game.audio.toggle_mute())
	button(content, "Înapoi la meniu", game.back_to_menu)
	button(content, "Închide jocul", game.shutdown)

func show_meeting() -> void:
	var content = sheet("meeting", "CINE NU SPUNE ADEVĂRUL?", "Votează pe baza a ceea ce ai observat. Egalitatea și abținerea nu expulzează pe nimeni.", 900, 650)
	meeting_clock = label(content, "", 20, ACCENT)
	if not game.rules.players[0].alive:
		label(content, "Ești un ecou. Urmărești ședința fără drept de vot.", 18, Color("ffb295"))
	var evidence: Array[String] = []
	for p in game.rules.players:
		if p.alive and not p.traitor:
			for suspect in p.suspicion:
				if game.rules.players[suspect].alive:
					evidence.append(p.name + ": «Am văzut un atacator cu identitatea " + game.rules.players[suspect].name + ".»")
					break
	if evidence.size() > 0:
		label(content, "MĂRTURII", 14, ACCENT)
		for i in mini(evidence.size(), 3):
			var testimony = label(content, evidence[i], 15)
			testimony.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label(content, "Nu există mărturii directe. Poți alege să te abții.", 15)
	var grid = GridContainer.new()
	grid.columns = 5
	content.add_child(grid)
	for p in game.rules.players:
		if not p.alive:
			continue
		var id = int(p.id)
		var choice = button(grid, p.name, func(): cast_vote(id))
		choice.modulate = Catalog.color_for(id).lightened(0.25)
		choice.disabled = not game.rules.players[0].alive
	var skip = button(content, "MĂ ABȚIN", func(): cast_vote(-1))
	skip.disabled = not game.rules.players[0].alive

func cast_vote(id: int) -> void:
	if game.rules.vote(0, id):
		for node in modal.find_children("*", "Button", true, false):
			node.disabled = true
		meeting_clock.text = "Vot înregistrat. Se așteaptă restul echipajului…"

func show_task(id: int) -> void:
	task_id = id
	task_index = 0
	task_sequence.clear()
	for i in (2 if game.rules.players[0].role == "Inginer" else 4):
		task_sequence.append(game.rules.rng.randi_range(1, 4))
	var repair = game.rules.reactor_time > 0 and id in [0, 4] and game.rules.players[0].alive
	var content = sheet("task", "STABILIZEAZĂ REACTORUL" if repair else "CALIBRARE TERMINAL", Catalog.TASKS[id].name + "\nApasă modulele în ordinea afișată. O eroare reia secvența.", 670, 440)
	task_hint = label(content, sequence_text(), 38, ACCENT)
	task_state = label(content, "Secvență: 0 / " + str(task_sequence.size()), 20)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	for i in range(1, 5):
		var number = i
		var node = button(row, "  " + str(i) + "  ", func(): task_press(number))
		node.custom_minimum_size = Vector2(120, 70)
	label(content, "Poți folosi și tastele 1, 2, 3, 4.", 15)
	button(content, "Deconectează terminalul", game.close_task)

func sequence_text() -> String:
	var words: Array[String] = []
	for i in task_sequence.size():
		words.append("✓" if i < task_index else str(task_sequence[i]))
	return "   →   ".join(words)

func task_press(number: int) -> void:
	if current_modal != "task" or game.rules.phase != "active":
		return
	if number == task_sequence[task_index]:
		task_index += 1
		game.audio.play_effect("ui")
	else:
		task_index = 0
		task_state.text = "Semnal incorect. Reia secvența."
		game.audio.play_effect("attack")
	task_hint.text = sequence_text()
	if task_index >= task_sequence.size():
		game.finish_task(task_id)
	else:
		task_state.text = "Secvență: %d / %d" % [task_index, task_sequence.size()]

func show_result(winner: String, reason: String) -> void:
	var content = sheet("result", winner + " CÂȘTIGĂ", reason, 760, 570)
	label(content, "IDENTITĂȚI DEZVĂLUITE", 14, ACCENT)
	for p in game.rules.players:
		if p.traitor:
			label(content, "%s — %s" % [p.name, p.role], 19, Color("ffa28d"))
	label(content, "Durată activă: %d:%02d   ·   Sisteme: %d / %d" % [int(game.rules.elapsed) / 60, int(game.rules.elapsed) % 60, game.rules.progress(), game.rules.crew_tasks_required], 17)
	button(content, "O nouă partidă", game.back_to_menu)
	button(content, "Închide jocul", game.shutdown)

func update_hud() -> void:
	queue_redraw()
	if not game.playing or game.rules.players.is_empty():
		return
	var human = game.rules.players[0]
	status.text = ("ECOU · " if not human.alive else "") + human.role.to_upper()
	status.modulate = Color("ffa28d") if human.traitor else INK
	location_label.text = game.station.room_at(game.player.position)
	task_bar.max_value = game.rules.crew_tasks_required
	task_bar.value = game.rules.progress()
	objective.text = "%d / %d sisteme reparate  ·  %d participanți în viață\n" % [game.rules.progress(), game.rules.crew_tasks_required, game.rules.alive_count(true) + game.rules.alive_count(false)]
	objective.text += "Infiltrează-te. Folosește terminalele pentru sabotaj." if human.traitor else "Misiunile tale: %d / 6. Terminalele sunt marcate pe hartă." % human.tasks.size()
	alert.text = "AVARIE REACTOR   %02d:%02d" % [int(maxf(0, game.rules.reactor_time)) / 60, int(maxf(0, game.rules.reactor_time)) % 60] if game.rules.reactor_time > 0 else ""
	prompt.text = game.context_prompt() if current_modal == "" else ""
	cooldown.text = "Q · %s   %s     |     Esc · Pauză     M · Sunet" % [human.role, "gata" if human.ability_cd <= 0 else "%ds" % ceili(human.ability_cd)]
	if human.traitor:
		cooldown.text += "     F · Atac %s" % ("gata" if human.kill_cd <= 0 else "%ds" % ceili(human.kill_cd))
	if human.role == "Hunter":
		cooldown.text = "WINCHESTER   %d / 3 CARTUȘE   ·   %s\nClick / Q / F · Trage   |   Esc · Pauză" % [human.ammo, "pregătită" if human.ability_cd <= 0 else "următorul foc: %ds" % ceili(human.ability_cd)]
		role_button.text = "Q · TRAGE"
		attack_button.visible = false
	else:
		role_button.text = "Q · Rol"
		attack_button.visible = true
	touch_controls.visible = game.touch_enabled and current_modal == ""
	if current_modal == "meeting" and is_instance_valid(meeting_clock):
		meeting_clock.text = "%ds rămase   ·   %d voturi înregistrate%s" % [ceili(game.rules.meeting_time), game.rules.votes.size(), "   ·   Ai votat" if game.rules.votes.has(0) else ""]

func _draw() -> void:
	if not game or not game.playing or current_modal != "":
		return
	var center = size / 2
	draw_circle(center, 2.0, ACCENT)
	for side in [-1.0, 1.0]:
		draw_line(center + Vector2(side * 7, 0), center + Vector2(side * 12, 0), Color(0.6, 0.9, 0.9, 0.5), 1.0)
	if game.show_map:
		var origin = Vector2(size.x - 155, 194)
		draw_style_box(map_style(), Rect2(origin - Vector2(107, 107), Vector2(214, 214)))
		if game.rules.sensors_off <= 0:
			for cell in game.station.cells:
				draw_rect(Rect2(origin + Vector2(cell.x, cell.y) * 14 - Vector2(6, 6), Vector2(12, 12)), Color("2b4b58"))
			for task in Catalog.TASKS:
				if task.id not in game.rules.players[0].tasks:
					draw_circle(origin + Vector2(task.pos.x, task.pos.z) * 3.5, 3.1, Color("e9bc65"))
			draw_circle(origin + Vector2(game.player.position.x, game.player.position.z) * 3.5, 4.0, ACCENT)
		else:
			draw_line(origin - Vector2(35, 35), origin + Vector2(35, 35), Color("ef886e"), 3)
	if game.touch_enabled:
		var base = game.player.touch_origin if game.player.left_touch >= 0 else Vector2(125, size.y - 125)
		draw_circle(base, 65, Color(0.2, 0.55, 0.6, 0.17))
		draw_arc(base, 65, 0, TAU, 48, Color(0.4, 0.8, 0.8, 0.5), 2)
		draw_circle(base + game.player.touch_move * 45, 24, Color(0.4, 0.8, 0.8, 0.5))

func map_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.04, 0.06, 0.82)
	style.border_color = Color("375963")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
