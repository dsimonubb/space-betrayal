extends RefCounted

# Prototype tuning in game-world metres; this is not a weapon simulation.
const STARTING_AMMO = 3
const RANGE = 25.0
const CYCLE_SECONDS = 3.0

static func trace(origin: Vector3, direction: Vector3, participants: Array[Dictionary], shooter: int, space: PhysicsDirectSpaceState3D, excluded: Array[RID]) -> Dictionary:
	var forward = direction.normalized()
	var endpoint = origin + forward * RANGE
	var query = PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.exclude = excluded
	var wall = space.intersect_ray(query)
	var reach = RANGE
	if not wall.is_empty():
		reach = origin.distance_to(wall.position)
		endpoint = wall.position
	var target = -1
	var closest = reach
	for p in participants:
		if p.id == shooter or not p.alive:
			continue
		# Select the first body in the sight line, irrespective of its hidden team.
		# Crew therefore blocks a shot at a traitor standing behind them.
		var feet = p.pos + Vector3.UP * 0.35
		var head = p.pos + Vector3.UP * 1.65
		var pair = Geometry3D.get_closest_points_between_segments(origin, origin + forward * RANGE, feet, head)
		var along = (pair[1] - origin).dot(forward)
		if along <= 0.0 or along > closest or pair[0].distance_to(pair[1]) > 0.32:
			continue
		# A wall before the body's centre prevents grazing through thin partitions.
		var visible_query = PhysicsRayQueryParameters3D.create(origin, pair[1])
		visible_query.exclude = excluded
		if not space.intersect_ray(visible_query).is_empty():
			continue
		closest = along
		target = p.id
		endpoint = pair[0]
	return {"target": target, "end": endpoint}
