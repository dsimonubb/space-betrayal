extends Node3D
const Catalog = preload("res://scripts/catalog.gd")
var cells: Dictionary = {}
var navigation = AStarGrid2D.new()
var terminals: Array[Node3D] = []
var lamps: Array[OmniLight3D] = []
var materials: Dictionary = {}
var alarm = false

func _ready() -> void:
	build()

func material(color: Color, emission: bool = false, metal: float = 0.5) -> StandardMaterial3D:
	var key = str(color) + str(emission) + str(metal)
	if materials.has(key):
		return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = 0.64
	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	materials[key] = mat
	return mat

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false, glow: bool = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var geometry = BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = material(color, glow)
	parent.add_child(mesh)
	mesh.position = at
	if solid:
		var body = StaticBody3D.new()
		mesh.add_child(body)
		var shape = CollisionShape3D.new()
		var bounds = BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
	return mesh

func text_3d(parent: Node3D, words: String, at: Vector3, size: int = 38, tint: Color = Color("8ce9e3")) -> Label3D:
	var label = Label3D.new()
	label.text = words
	label.font_size = size
	label.pixel_size = 0.009
	label.modulate = tint
	label.outline_size = 6
	parent.add_child(label)
	label.position = at
	return label

func build() -> void:
	for x in range(-6, 7):
		for z in range(-6, 7):
			var hub = abs(x) <= 1 and abs(z) <= 1
			var halls = (x == 0 or z == 0)
			var room = (abs(x) >= 4 and abs(z) <= 1) or (abs(z) >= 4 and abs(x) <= 1)
			if hub or halls or room:
				cells[Vector2i(x, z)] = true
	navigation.region = Rect2i(-6, -6, 13, 13)
	navigation.cell_size = Vector2(4, 4)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	navigation.set_point_solid(Vector2i.ZERO, true)
	for x in range(-6, 7):
		for z in range(-6, 7):
			if not cells.has(Vector2i(x, z)):
				navigation.set_point_solid(Vector2i(x, z), true)
	var steel = Color("172431")
	for cell in cells:
		var at = Vector3(cell.x * 4, 0, cell.y * 4)
		box(self, at + Vector3(0, -0.12, 0), Vector3(4, 0.24, 4), Color("253340"), true)
		box(self, at + Vector3(0, 3.75, 0), Vector3(4, 0.2, 4), steel, true)
		# Recessed floor seams and low edge lights.
		box(self, at + Vector3(1.96, 0.015, 0), Vector3(0.035, 0.02, 4), Color("435462"))
		box(self, at + Vector3(0, 0.015, 1.96), Vector3(4, 0.02, 0.035), Color("435462"))
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if cells.has(cell + direction):
				continue
			var along_x = direction.x != 0
			var offset = Vector3(direction.x * 2, 1.8, direction.y * 2)
			var wall_size = Vector3(0.22, 3.6, 4) if along_x else Vector3(4, 3.6, 0.22)
			box(self, at + offset, wall_size, steel, true)
			var panel_size = Vector3(0.26, 2.1, 3.65) if along_x else Vector3(3.65, 2.1, 0.26)
			box(self, at + offset, panel_size, Color("304453"))
			var strip_size = Vector3(0.3, 0.045, 3.5) if along_x else Vector3(3.5, 0.045, 0.3)
			box(self, at + Vector3(offset.x, 0.25, offset.z), strip_size, Color("257b85"), false, true)
		if (cell.x + cell.y) % 3 == 0:
			box(self, at + Vector3(0, 3.56, 0), Vector3(0.24, 0.06, 2.5), Color("b2d8df"), false, true)
	for point in [Vector3.ZERO, Vector3(0, 0, -12), Vector3(0, 0, 12), Vector3(12, 0, 0), Vector3(-12, 0, 0), Vector3(0, 0, -21), Vector3(0, 0, 21), Vector3(21, 0, 0), Vector3(-21, 0, 0)]:
		var light = OmniLight3D.new()
		light.position = point + Vector3(0, 2.7, 0)
		light.light_color = Color("91bdcc")
		light.light_energy = 1.4
		light.omni_range = 10.0
		light.shadow_enabled = false
		add_child(light)
		lamps.append(light)
	var environment_node = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("02050c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a1baca")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	for task in Catalog.TASKS:
		make_terminal(task)
	# Four distinct functional spaces, with props away from the walkable spine.
	for x in [-2.4, 2.4]:
		for z in [18.0, 23.5]:
			box(self, Vector3(x, 0.8, z), Vector3(1.3, 1.6, 1.0), Color("33565c"), true)
			box(self, Vector3(x, 1.65, z), Vector3(1.1, 0.1, 0.8), Color("48bfa7"), false, true)
	for z in [-3.4, 3.4]:
		for x in [-24.0, -17.0]:
			box(self, Vector3(x, 0.5, z), Vector3(1.4, 0.9, 2.3), Color("344956"), true)
			box(self, Vector3(x, 1.02, z), Vector3(1.3, 0.15, 2.2), Color("b1c8cd"))
	for x in [-3.8, 3.8]:
		box(self, Vector3(x, 1.15, -24), Vector3(1.5, 2.3, 1.5), Color("3b4855"), true)
		box(self, Vector3(x, 1.2, -23.2), Vector3(0.75, 1.6, 0.05), Color("dd9b55"), false, true)
	# Central meeting table and emergency console, reachable from the south.
	box(self, Vector3(0, 0.65, 0), Vector3(2.5, 1.3, 2.0), Color("253d4b"), true)
	box(self, Vector3(0, 1.34, 0), Vector3(2.6, 0.1, 2.1), Color("3e6872"))
	box(self, Vector3(0, 1.45, 0.5), Vector3(0.38, 0.16, 0.38), Color("f07860"), false, true)
	var sign = text_3d(self, "OMEGA—9\nADUNARE / E", Vector3(0, 2.45, -1.25), 36)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	for room in [{"name": "01   REACTOR", "p": Vector3(0, 2.9, -14.2), "angle": 0.0}, {"name": "02   COMUNICAȚII", "p": Vector3(14.2, 2.9, 0), "angle": -PI / 2}, {"name": "03   SUPORT VITAL", "p": Vector3(0, 2.9, 14.2), "angle": PI}, {"name": "04   INFIRMERIE", "p": Vector3(-14.2, 2.9, 0), "angle": PI / 2}]:
		var label = text_3d(self, room.name, room.p, 35)
		label.rotation.y = room.angle
		var frame = Node3D.new()
		add_child(frame)
		frame.position = Vector3(room.p.x, 0, room.p.z)
		frame.rotation.y = room.angle
		for x in [-1.75, 1.75]:
			box(frame, Vector3(x, 1.8, 0), Vector3(0.18, 3.6, 0.3), Color("5895a3"))
		box(frame, Vector3(0, 3.45, 0), Vector3(3.5, 0.15, 0.3), Color("65cecf"), false, true)

func make_terminal(task: Dictionary) -> void:
	var terminal = Node3D.new()
	add_child(terminal)
	terminal.position = task.pos
	var center = Vector3(0, 0, -20) if task.room == "REACTOR" else Vector3(20, 0, 0)
	if task.room == "INFIRMERIE":
		center = Vector3(-20, 0, 0)
	elif task.room == "SUPORT VITAL":
		center = Vector3(0, 0, 20)
	terminal.look_at(center)
	box(terminal, Vector3(0, 0.7, 0), Vector3(1.15, 1.4, 0.7), Color("344857"), true)
	box(terminal, Vector3(0, 1.3, -0.38), Vector3(0.9, 0.6, 0.05), Color("3ed4ca"), false, true)
	box(terminal, Vector3(0, 0.89, -0.45), Vector3(1, 0.08, 0.32), Color("9ab9c6"))
	var label = text_3d(terminal, task.name + "\n[E]", Vector3(0, 2.1, 0), 25)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	terminals.append(terminal)

func set_alarm(enabled: bool) -> void:
	if enabled == alarm:
		return
	alarm = enabled
	for lamp in lamps:
		lamp.light_color = Color("ff6954") if alarm else Color("91bdcc")

func path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var a = Vector2i(clampi(roundi(from.x / 4), -6, 6), clampi(roundi(from.z / 4), -6, 6))
	var b = Vector2i(clampi(roundi(to.x / 4), -6, 6), clampi(roundi(to.z / 4), -6, 6))
	var route: Array[Vector3] = []
	if not cells.has(a) or not cells.has(b):
		return route
	for p in navigation.get_id_path(a, b):
		route.append(Vector3(p.x * 4, 0, p.y * 4))
	if route.size() > 1:
		route.remove_at(0)
	route.append(to)
	return route

func room_at(point: Vector3) -> String:
	if point.z < -14:
		return "REACTOR"
	if point.z > 14:
		return "SUPORT VITAL"
	if point.x < -14:
		return "INFIRMERIE"
	if point.x > 14:
		return "COMUNICAȚII"
	return "NOD CENTRAL" if absf(point.x) < 6 and absf(point.z) < 6 else "CORIDOR DE TRANZIT"
