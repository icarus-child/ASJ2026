class_name Controller
extends Enemy

var speed: float = 200
var acceleration: float = 100
var reposition_target: Vector2

var short_nav_trigger_distance: float = 400
var short_nav_on_cooldown: bool = false
var short_nav_cooldown: float = 2

var slow_on_cooldown: bool = true
var slow_cooldown: float = 20

var can_attack: bool = false
var min_attack_cooldown: float = 4
var max_attack_cooldown: float = 6

var recovering_from_attack: bool = false
var attack_recovery: float = 2

var attack_range: float = 800
var ideal_distance: float = 750


@onready var sprite: Sprite2D = $Sprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var avoid_shape: Area2D = $AvoidShape
@onready var lob_attack: Spell = Lob.PSpell.new()
@onready var slow_attack: Spell = AcidLob.PSpell.new()


func _ready() -> void:
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = randf_range(3, 6)
	timer.timeout.connect(_update_navigation_target)
	add_child(timer)
	
	add_child(_create_timer(randf_range(1, 4),
		func() -> void: slow_on_cooldown = false
	))
	add_child(_create_timer(randf_range(1, 3),
		func() -> void: can_attack = true
	))


func _physics_process(delta: float) -> void:
	var distance_to_player := position.distance_to(player.position)
	if not short_nav_on_cooldown and distance_to_player <= short_nav_trigger_distance:
		_update_navigation_target()
		short_nav_on_cooldown = true
		add_child(
			_create_timer(
				slow_cooldown,
				func() -> void: short_nav_on_cooldown = false
			)
		)
	if distance_to_player <= attack_range and not slow_on_cooldown and can_attack:
		var attack_direction := player.global_position
		sprite.flip_h = global_position.direction_to(player.global_position).x < 0
		anim.attack()
		slow_attack.fire_attack(self, attack_direction)
		slow_on_cooldown = true
		add_child(
			_create_timer(
				slow_cooldown,
				func() -> void: slow_on_cooldown = false
			)
		)
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
	elif can_attack and distance_to_player <= attack_range:
		var attack_direction := player.global_position
		sprite.flip_h = global_position.direction_to(player.global_position).x < 0
		anim.attack()
		lob_attack.fire_attack(self, attack_direction)
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
	navigation_agent.target_position = _find_flank_position()


func _find_flank_position(teleport: bool = false) -> Vector2:
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
		var score := _rate_position(candidate, ideal_distance, teleport)
		_display_flanks_for_testing(score, candidate, i)

		if score > best_score:
			best_score = score
			best_pos = candidate

	return best_pos


func _rate_position(candidate: Vector2, temp_ideal_distance: float, teleport: bool = false) -> float:
	var score := 0.0
	var res: float

	# Prefer not LOS
	if not _has_line_of_sight(candidate):
		res = 100
		score += res

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
	if global_position.distance_to(candidate) < 20:
		res = -700
	score += res
	# print("gained for position %s" % res)

	# Prefer positions that aren't crowded
	for neighbour: Area2D in avoid_shape.get_overlapping_areas():
		var dist := neighbour.global_position.distance_to(candidate)

		if dist < 100:
			score -= (100 - dist) * 100

	return score


func _display_flanks_for_testing(score: float, candidate: Vector2, i: int) -> void:
	var label := Label.new()
	label.text = "%s : %s" % [i, snappedf(score, 5)]
	label.global_position = candidate
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = 2
	timer.timeout.connect(label.queue_free)
	label.add_child(timer)
	add_sibling(label)


func _die() -> void:
	print("if not for you meddling wissard")
	queue_free()
