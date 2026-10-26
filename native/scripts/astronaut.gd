extends Node3D
const Catalog = preload("res://scripts/catalog.gd")
const Rifle = preload("res://scripts/winchester.gd")
var id = 1
var walk_time = 0.0
var limbs: Array[Node3D] = []
var name_tag: Label3D
var suit: StandardMaterial3D
var visual: Node3D
var route: Array[Vector3] = []
var target_task = -1
var wait = 0.0
var mimic_id = -1
var alien: Node3D
var reveal_time = 0.0
var rifle: Node3D

func _ready() -> void:
	visual = Node3D.new()
	add_child(visual)
	suit = StandardMaterial3D.new()
	suit.albedo_color = Catalog.color_for(id).darkened(0.25)
	suit.metallic = 0.35
	suit.roughness = 0.7
	var dark = StandardMaterial3D.new()
	dark.albedo_color = Color("101d28")
	var visor = StandardMaterial3D.new()
	visor.albedo_color = Color("0c293b")
	visor.metallic = 0.85
	visor.roughness = 0.13
	var trim = StandardMaterial3D.new()
	trim.albedo_color = Color("9eaeb5")
	part(visual, Vector3(0, 1.05, 0), Vector3(0.64, 0.72, 0.38), suit, "capsule")
	part(visual, Vector3(0, 1.58, 0), Vector3(0.55, 0.56, 0.51), suit, "sphere")
	part(visual, Vector3(0, 1.59, -0.18), Vector3(0.46, 0.3, 0.21), visor, "sphere")
	part(visual, Vector3(0, 1.04, 0.28), Vector3(0.43, 0.58, 0.28), dark, "box")
	part(visual, Vector3(0, 1.19, -0.22), Vector3(0.3, 0.22, 0.055), trim, "box")
	for side in [-1.0, 1.0]:
		var leg = Node3D.new()
		visual.add_child(leg)
		leg.position = Vector3(side * 0.17, 0.77, 0)
		part(leg, Vector3(0, -0.3, 0), Vector3(0.23, 0.65, 0.26), suit, "capsule")
		part(leg, Vector3(0, -0.64, -0.07), Vector3(0.24, 0.18, 0.38), dark, "box")
		limbs.append(leg)
		var arm = Node3D.new()
		visual.add_child(arm)
		arm.position = Vector3(side * 0.38, 1.35, 0)
		part(arm, Vector3(0, -0.25, 0), Vector3(0.22, 0.58, 0.23), suit, "capsule")
		part(arm, Vector3(0, -0.56, 0), Vector3(0.19, 0.2, 0.2), dark, "sphere")
		limbs.append(arm)
	name_tag = Label3D.new()
	name_tag.font_size = 24
	name_tag.pixel_size = 0.008
	name_tag.position.y = 2.05
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.text = Catalog.NAMES[id]
	add_child(name_tag)
	alien = Node3D.new()
	add_child(alien)
	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color("39304b")
	skin.metallic = 0.3
	var eyes = StandardMaterial3D.new()
	eyes.albedo_color = Color("cefc98")
	eyes.emission_enabled = true
	eyes.emission = Color("a5e962")
	part(alien, Vector3(0, 1.5, -0.1), Vector3(0.6, 0.85, 0.6), skin, "sphere")
	for side in [-1.0, 1.0]:
		part(alien, Vector3(side * 0.18, 1.65, -0.38), Vector3(0.17, 0.06, 0.06), eyes, "sphere")
		for i in 3:
			var claw = part(alien, Vector3(side * (0.45 + i * 0.07), 1.0 - i * 0.15, -0.3), Vector3(0.05, 0.65, 0.06), skin, "capsule")
			claw.rotation.z = side * (0.4 + i * 0.2)
	alien.visible = false
	rifle = Rifle.new()
	visual.add_child(rifle)
	rifle.position = Vector3(0.21, 1.04, -0.18)
	rifle.rotation.x = 0.2
	rifle.visible = false

func equip_hunter(equipped: bool) -> void:
	rifle.visible = equipped

func part(parent: Node3D, at: Vector3, dimensions: Vector3, mat: Material, type: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	if type == "sphere":
		var mesh = SphereMesh.new()
		mesh.radial_segments = 12
		mesh.rings = 6
		node.mesh = mesh
	elif type == "capsule":
		var mesh = CapsuleMesh.new()
		mesh.radial_segments = 12
		mesh.rings = 3
		node.mesh = mesh
	else:
		node.mesh = BoxMesh.new()
	parent.add_child(node)
	node.position = at
	node.scale = dimensions
	if type == "capsule":
		node.scale.y *= 0.5
	node.material_override = mat
	return node

func animate_walk(delta: float, moving: bool) -> void:
	reveal_time = maxf(0, reveal_time - delta)
	alien.visible = reveal_time > 0
	visual.visible = not alien.visible
	walk_time += delta * (7.0 if moving else 1.0)
	for i in limbs.size():
		limbs[i].rotation.x = sin(walk_time + float(i % 2) * PI) * (0.45 if moving else 0.025)

func reveal() -> void:
	reveal_time = 1.5

func show_identity(copy_id: int) -> void:
	if copy_id == mimic_id:
		return
	mimic_id = copy_id
	var shown = id if copy_id < 0 else copy_id
	suit.albedo_color = Catalog.color_for(shown).darkened(0.25)
	name_tag.text = Catalog.NAMES[shown]

func become_body() -> void:
	visual.rotation.z = PI / 2
	visual.position.y = 0.25
	name_tag.visible = false
