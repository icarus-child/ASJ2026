class_name Electrician
extends Enemy

var speed: float = 300
var acceleration: float = 150
var reposition_target: Vector2

var blink_on_cooldown: bool = false
var blink_trigger_range: float = 300
var blink_cooldown: float = 10

var can_attack: bool = true
var min_attack_cooldown: float = 2
var max_attack_cooldown: float = 4

var recovering_from_attack: bool = false
var attack_recovery: float = 1

var attack_range: float = 500
var ideal_distance: float = 400

var beam_scene: PackedScene = preload("res://enemies/spells/teleport_beam.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var avoid_shape: Area2D = $AvoidShape
@onready var electric_ball: Spell = ElectricShot.PSpell.new()
@onready var electric_circle: Spell = ElectricCircle.PSpell.new()


func _custom_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not following_player:
		_movement(delta)
		move_and_slide()
		velocity = get_real_velocity()
		return
	var distance_to_player := position.distance_to(player.position)
	if distance_to_player <= blink_trigger_range and not blink_on_cooldown:
		var target := _find_flank_position(true)

		# TODO: make pretty
		var beam := beam_scene.instantiate() as Line2D
		beam.global_position = global_position
		beam.points[1].x = target.x - beam.global_position.x
		beam.points[1].y = target.y - beam.global_position.y
		beam.add_child(_create_timer(0.1, beam.queue_free))
		add_sibling(beam)

		global_position = target
		_update_navigation_target()
		electric_circle.fire_attack(self, position.direction_to(player.position))
		blink_on_cooldown = true
		add_child(
			_create_timer(
				blink_cooldown,
				func() -> void: blink_on_cooldown = false
			)
		)
	elif can_attack and distance_to_player <= attack_range and _has_line_of_sight():
		var attack_direction := position.direction_to(player.position)
		sprite.flip_h = attack_direction.x < 0
		anim.attack()
		electric_ball.fire_attack(self, attack_direction)
		can_attack = false
		recovering_from_attack = true
		add_child(
			_create_timer(
				randf_range(min_attack_cooldown, max_attack_cooldown),
				func() -> void: can_attack = true
			)
		)
		add_child(
			_create_timer(
				attack_recovery, 
				func() -> void: recovering_from_attack = false
			)
		)
	elif not recovering_from_attack:
		_movement(delta)
	else:
		velocity += (Vector2.ZERO - velocity).limit_length(acceleration * delta)
	move_and_slide()
	velocity = get_real_velocity()


func _create_timer(duration: float, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = duration
	timer.timeout.connect(callback)
	return timer


func _movement(delta: float) -> void:
	var move_dir := position.direction_to(
		navigation_agent.get_next_path_position()
	)

	var separation := _get_separation_force()

	# only keep component perpendicular to movement
	var forward_strength := separation.dot(move_dir)

	var lateral_separation := (
		separation
		- move_dir * forward_strength
	)

	var final_dir := (
		move_dir
		+ lateral_separation * 1.2
	).normalized()

	var target_vel := final_dir * speed

	velocity += (
		target_vel - velocity
	).limit_length(acceleration * delta)
	sprite.flip_h = velocity.x < 0


func _get_separation_force() -> Vector2:
	var force := Vector2.ZERO

	for neighbour: Area2D in avoid_shape.get_overlapping_areas():
		var offset := global_position - neighbour.global_position
		var dist := offset.length()

		if dist <= 0.01:
			continue

		var strength := 1.0 - (dist / ((avoid_shape.get_child(0) as CollisionShape2D).shape as CircleShape2D).radius)

		force += offset.normalized() * strength

	return force.limit_length(0.4)


# Too far → move closer
# Too close → back away
# Good distance + LOS → strafe / hold position
# No LOS → move to regain visibility
func _update_navigation_target() -> void:
	if not following_player:
		navigation_agent.target_position = _get_random_movement_target()
	else:
		navigation_agent.target_position = _find_flank_position()


func _find_flank_position(teleport: bool = false) -> Vector2:
	const NUM_SAMPLES := 8
	const FLANK_ANGLE_STEP := 360.0/NUM_SAMPLES


	var best_pos := player.global_position
	var best_score := -INF

	for i in range(NUM_SAMPLES):
		var angle := deg_to_rad(i * FLANK_ANGLE_STEP)

		var dir := global_position.direction_to(player.global_position).rotated(angle)

		var temp_ideal_distance := randf_range(ideal_distance - 20, ideal_distance + 20)
		var candidate := (
			player.global_position
			+ dir * temp_ideal_distance
		)
		# get closest valid navmesh point
		candidate = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, candidate)
		var score := _rate_position(candidate, temp_ideal_distance, teleport)
		# _display_flanks_for_testing(score, candidate, i)

		if score > best_score:
			best_score = score
			best_pos = candidate

	return best_pos


func _rate_position(candidate: Vector2, temp_ideal_distance: float, teleport: bool = false) -> float:
	var score := 0.0

	# Prefer LOS
	if not _has_line_of_sight(candidate):
		return -INF

	var res: float
	if not teleport:
		# Prefer a specific distance
		res = -absf(candidate.distance_to(player.global_position) - temp_ideal_distance) * 2
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
	timer.wait_time = 0.5
	timer.timeout.connect(label.queue_free)
	label.add_child(timer)
	add_sibling(label)


func _die() -> void:
	print("ouch, I've been hit in the knee with an arrow")
	queue_free()
