class_name TestEnemy
extends CharacterBody2D


@export var min_attack_cooldown: float
@export var max_attack_cooldown: float
@export var speed: float
@export var acceleration: float
@export var health: int = 3

const IDEAL_DISTANCE := 300.0

var can_attack: bool = true
var attack_recovery: bool = false
var reposition_target: Vector2

@onready var attacks: Array[Spell] = [Projectile.TestSpell.new(), Lob.PSpell.new()]
@onready var max_attack_range: float = (
	attacks.map(func(attack: Spell) -> float: return attack.range()).max()
)
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var avoid_shape: Area2D = $AvoidShape


func _ready() -> void:
	# sort ascending by attack range
	attacks.sort_custom(
		func(a1: Spell, a2: Spell) -> bool: return a1.range() < a2.range()
	)
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = randf_range(0.5, 1)
	timer.timeout.connect(_update_navigation_target)
	add_child(timer)


# TODO: enemy attacks should have a startup and recovery time where they don't move
# TODO: enemy won't stop and attack when inside of an obstacle
func _physics_process(delta: float) -> void:
	var distance_to_player := position.distance_to(player.position)
	if can_attack and distance_to_player <= max_attack_range and _has_line_of_sight():
		_calculate_optimal_attack(distance_to_player).fire_attack(self , player.position - position)
		var wait_time := randf_range(min_attack_cooldown, max_attack_cooldown)
		var timer := Timer.new()
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = wait_time
		timer.timeout.connect(func() -> void: can_attack = true)
		can_attack = false
		var timer2 := Timer.new()
		timer2.one_shot = true
		timer2.autostart = true
		timer2.wait_time = 0.5
		timer2.timeout.connect(func() -> void: attack_recovery = false)
		attack_recovery = true
		add_child(timer2)
		add_child(timer)
	elif not attack_recovery:
		_movement(delta)
	else:
		velocity += (Vector2.ZERO - velocity).limit_length(acceleration * delta)
	move_and_slide()
	velocity = get_real_velocity()


# calculate shortest range attack that is within the attack range
func _calculate_optimal_attack(range_to_player: float) -> Spell:
	return attacks[attacks.find_custom(
		func(attack: Spell) -> bool: return attack.range() <= range_to_player
	)]


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


# Too far → move closer
# Too close → back away
# Good distance + LOS → strafe / hold position
# No LOS → move to regain visibility
func _update_navigation_target() -> void:
	navigation_agent.target_position = _find_flank_position()


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


func _find_flank_position() -> Vector2:
	const NUM_SAMPLES := 8
	const FLANK_ANGLE_STEP := 360.0 / NUM_SAMPLES


	var best_pos := player.global_position
	var best_score := -INF

	for i in range(NUM_SAMPLES):
		var angle := deg_to_rad(i * FLANK_ANGLE_STEP)

		var dir := global_position.direction_to(player.global_position).rotated(angle)

		var candidate := (
			player.global_position
			+ dir * IDEAL_DISTANCE
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
	var res := -absf(candidate.distance_to(player.global_position) - IDEAL_DISTANCE) * 2
	score += res
	# print("gained for distance %s" % res)

	# Prefer shorter movement
	res = - global_position.distance_to(candidate)
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


func _has_line_of_sight(from: Vector2 = global_position) -> bool:
	var space := get_world_2d().direct_space_state

	var query := PhysicsRayQueryParameters2D.create(
		from,
		player.global_position
	)

	query.collision_mask = 0b110000001

	var result := space.intersect_ray(query)

	if result.is_empty():
		return true

	return result.collider == player


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


func take_damage() -> void:
	health -= 1
	if health <= 0:
		_die()
