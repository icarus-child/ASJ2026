class_name Electrician
extends Enemy

var reposition_target: Vector2


# Too far → move closer
# Too close → back away
# Good distance + LOS → strafe / hold position
# No LOS → move to regain visibility
func _update_navigation_target() -> void:
	navigation_agent.target_position = _find_flank_position()


func _find_flank_position() -> Vector2:
	const NUM_SAMPLES := 8
	const FLANK_ANGLE_STEP := 360.0/NUM_SAMPLES


	var best_pos := player.global_position
	var best_score := -INF

	for i in range(NUM_SAMPLES):
		var angle := deg_to_rad(i * FLANK_ANGLE_STEP)

		var dir := global_position.direction_to(player.global_position).rotated(angle)

		var candidate := (
			player.global_position
			+ dir * ideal_distance
		)
		# get closest valid navmesh point
		candidate = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, candidate)
		var score := _rate_position(candidate)
		# _display_flanks_for_testing(score, candidate, i)

		if score > best_score:
			best_score = score
			best_pos = candidate

	return best_pos


func _rate_position(candidate: Vector2) -> float:
	var score := 0.0

	# Prefer LOS
	if not _has_line_of_sight(candidate):
		return -INF

	# Prefer a specific distance
	var res := -absf(candidate.distance_to(player.global_position) - ideal_distance) * 2
	score += res
	# print("gained for distance %s" % res)

	# Prefer shorter movement
	res = -global_position.distance_to(candidate)
	score += res
	# print("gained for movement %s" % res)

	# Prefer changing spots once we've reached one
	res = 0
	if global_position.distance_to(candidate) < 10:
		res = -300
	score += res
	# print("gained for position %s" % res)

	# Prefer positions that aren't crowded
	for neighbour: Area2D in avoid_shape.get_overlapping_areas():
		var dist := neighbour.global_position.distance_to(candidate)

		if dist < 100:
			score -= (100 - dist) * 10

	return score


func _display_flanks_for_testing(score: float, candidate: Vector2, i: int) -> void:
	var label := Label.new()
	label.text = "%s : %s" % [i, snappedf(score, 5)]
	label.global_position = candidate
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = 1
	timer.timeout.connect(label.queue_free)
	label.add_child(timer)
	add_sibling(label)


func _die() -> void:
	print("ouch, I've been hit in the knee with an arrow")
	queue_free()
