extends Node3D

# Original low-poly lever-action rifle placeholder, authored for this game.
var rig: Node3D
var lever: Node3D
var flash: MeshInstance3D
var cycle = 0.0
var first_person = false
var materials: Dictionary = {}

func _ready() -> void:
	rig = Node3D.new()
	add_child(rig)
	var wood = Color("6d3520")
	var grain = Color("a46b3d")
	var steel = Color("39444c")
	var brass = Color("9b8150")
	# Wooden stock, grip and fore-end around a dark receiver and long barrel.
	box(Vector3(0, -0.035, 0.29), Vector3(0.10, 0.18, 0.32), wood)
	box(Vector3(0, -0.04, 0.46), Vector3(0.11, 0.21, 0.035), Color("161d23"))
	var grip = box(Vector3(0, -0.055, 0.09), Vector3(0.085, 0.14, 0.13), wood)
	grip.rotation.x = -0.25
	box(Vector3(0, 0.025, -0.035), Vector3(0.105, 0.13, 0.25), brass)
	box(Vector3(0, 0.055, -0.06), Vector3(0.11, 0.06, 0.17), steel)
	box(Vector3(0, -0.012, -0.34), Vector3(0.10, 0.095, 0.35), wood)
	for side in [-1.0, 1.0]:
		box(Vector3(side * 0.051, 0.002, -0.34), Vector3(0.004, 0.009, 0.27), grain)
		box(Vector3(side * 0.051, -0.025, 0.29), Vector3(0.004, 0.012, 0.22), grain)
	cylinder(Vector3(0, 0.084, -0.46), 0.023, 0.82, steel)
	cylinder(Vector3(0, 0.025, -0.45), 0.017, 0.68, steel)
	cylinder(Vector3(0, 0.084, -0.884), 0.025, 0.017, Color("0c1218"))
	box(Vector3(0, 0.12, -0.80), Vector3(0.015, 0.028, 0.035), brass)
	box(Vector3(0, 0.12, -0.09), Vector3(0.06, 0.025, 0.018), steel)
	# Oval lever and trigger silhouette, without branded logos or copied assets.
	lever = Node3D.new()
	rig.add_child(lever)
	lever.position = Vector3(0, -0.065, 0.03)
	var loop = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.042
	torus.outer_radius = 0.057
	torus.rings = 12
	torus.ring_segments = 8
	loop.mesh = torus
	loop.material_override = surface(steel, true)
	loop.rotation.z = PI / 2
	loop.scale = Vector3(1.0, 1.0, 1.6)
	loop.position = Vector3(0, -0.04, 0)
	lever.add_child(loop)
	box(Vector3(0, -0.08, -0.01), Vector3(0.012, 0.045, 0.02), steel)
	flash = MeshInstance3D.new()
	var burst = SphereMesh.new()
	burst.radial_segments = 8
	burst.rings = 4
	burst.radius = 0.055
	burst.height = 0.14
	flash.mesh = burst
	var glow = StandardMaterial3D.new()
	glow.albedo_color = Color("ffe4a0")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = glow
	flash.position = Vector3(0, 0.084, -0.92)
	flash.visible = false
	rig.add_child(flash)
	if first_person:
		for hold in [Vector3(0.025, -0.10, 0.08), Vector3(-0.025, -0.075, -0.39)]:
			var glove = box(hold, Vector3(0.105, 0.11, 0.12), Color("30535d"))
			glove.rotation.z = -0.2

func surface(tint: Color, metal: bool = false) -> StandardMaterial3D:
	var key = str(tint) + str(metal)
	if not materials.has(key):
		var material = StandardMaterial3D.new()
		material.albedo_color = tint
		material.metallic = 0.6 if metal else 0.08
		material.roughness = 0.42 if metal else 0.8
		materials[key] = material
	return materials[key]

func box(at: Vector3, dimensions: Vector3, tint: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.material_override = surface(tint)
	rig.add_child(node)
	node.position = at
	return node

func cylinder(at: Vector3, radius: float, length: float, tint: Color) -> void:
	var node = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = surface(tint, true)
	node.rotation.x = PI / 2
	node.position = at
	rig.add_child(node)

func fire() -> void:
	cycle = 1.0

func _process(delta: float) -> void:
	cycle = maxf(0, cycle - delta * 1.8)
	flash.visible = cycle > 0.88
	rig.position.z = maxf(0, cycle - 0.6) * 0.12
	rig.rotation.x = maxf(0, cycle - 0.6) * 0.12
	lever.rotation.x = -sin(cycle * PI) * 0.55
