extends CharacterBody3D
const Rifle = preload("res://scripts/winchester.gd")
signal stepped
var camera: Camera3D
var enabled = false
var speed = 4.8
var touch_move = Vector2.ZERO
var left_touch = -1
var right_touch = -1
var touch_origin = Vector2.ZERO
var pitch = 0.0
var stride = 0.0
var previous_step = 0
var hands: Node3D
var alien_hands: Node3D
var reveal_time = 0.0
var rifle: Node3D
var hunter_equipped = false

func _ready() -> void:
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	var shape = CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.875
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.63
	camera.fov = 78.0
	camera.near = 0.08
	add_child(camera)
	camera.current = true
	hands = Node3D.new()
	camera.add_child(hands)
	var glove = StandardMaterial3D.new()
	glove.albedo_color = Color("294a55")
	var cuff = StandardMaterial3D.new()
	cuff.albedo_color = Color("9daeb5")
	for side in [-1, 1]:
		var hand = MeshInstance3D.new()
		var mesh = CapsuleMesh.new()
		mesh.radius = 0.065
		mesh.height = 0.28
		hand.mesh = mesh
		hand.material_override = glove
		hand.position = Vector3(side * 0.36, -0.46, -0.65)
		hand.rotation.x = -0.6
		hands.add_child(hand)
		var ring = MeshInstance3D.new()
		var band = CylinderMesh.new()
		band.top_radius = 0.09
		band.bottom_radius = 0.09
		band.height = 0.05
		ring.mesh = band
		ring.material_override = cuff
		hand.add_child(ring)
		ring.position.y = -0.07
	alien_hands = Node3D.new()
	camera.add_child(alien_hands)
	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color("55425d")
	for side in [-1.0, 1.0]:
		for i in 3:
			var claw = MeshInstance3D.new()
			var shape_mesh = CapsuleMesh.new()
			shape_mesh.radius = 0.018
			shape_mesh.height = 0.38
			claw.mesh = shape_mesh
			claw.material_override = skin
			claw.position = Vector3(side * (0.3 + i * 0.04), -0.26, -0.63)
			claw.rotation.x = -1.15
			alien_hands.add_child(claw)
	alien_hands.visible = false
	rifle = Rifle.new()
	rifle.first_person = true
	camera.add_child(rifle)
	rifle.position = Vector3(0.23, -0.18, -0.70)
	rifle.rotation = Vector3(0.025, 0.12, -0.045)
	rifle.visible = false

func equip_hunter(equipped: bool) -> void:
	hunter_equipped = equipped
	rifle.visible = equipped
	hands.visible = not equipped and not alien_hands.visible

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative * 0.0022)
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index == left_touch:
				left_touch = -1
				touch_move = Vector2.ZERO
			if event.index == right_touch:
				right_touch = -1
		elif event.position.x < get_viewport().get_visible_rect().size.x * 0.42 and left_touch < 0:
			left_touch = event.index
			touch_origin = event.position
		elif right_touch < 0 and event.position.y < get_viewport().get_visible_rect().size.y * 0.7:
			right_touch = event.index
	if event is InputEventScreenDrag:
		if event.index == left_touch:
			touch_move = ((event.position - touch_origin) / 70.0).limit_length()
		elif event.index == right_touch:
			look(event.relative * 0.004)

func look(amount: Vector2) -> void:
	rotation.y -= amount.x
	pitch = clampf(pitch - amount.y, -1.3, 1.3)
	camera.rotation.x = pitch

func release_input() -> void:
	touch_move = Vector2.ZERO
	left_touch = -1
	right_touch = -1
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	reveal_time = maxf(0, reveal_time - delta)
	alien_hands.visible = reveal_time > 0
	hands.visible = not alien_hands.visible and not hunter_equipped
	if not enabled:
		velocity = Vector3.ZERO
		return
	var input = Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	input = (input + touch_move).limit_length()
	var direction = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if input.length() > 0.15 and is_on_floor():
		stride += delta * speed * 1.8
		var step = int(stride / PI)
		if step != previous_step:
			previous_step = step
			stepped.emit()
	camera.position.y = 1.63 + sin(stride * 2.0) * input.length() * 0.018
	hands.position.y = sin(stride) * input.length() * 0.018
