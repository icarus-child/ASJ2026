class_name TestEnemy
extends CharacterBody2D

# Notes for self
# When attack off cooldown, calculate optimal attack based on current location
#     'optimal' attack prioritizes shortest range attack that will hit
# Calculate path to optimal range for this enemy
# Attack when off cooldown, move when on cooldown

# NOTE: AI should try to avoid being cornered -> handle during pathfinding logic
# NOTE: AI might attack less when the player has a lot of spells to make themselves harder to hit?

# the ai needs to know how far it can move before it's cooldown is done so it can
# move intelligently between attacks (?) i.e. it prioritizes local optimums

@export var min_attack_cooldown: float
@export var max_attack_cooldown: float
@export var max_speed: float
@export var acceleration: float
@export var health: int = 3

var can_attack: bool = true
var attack_recovery: bool = false

@onready var attacks: Array[Spell] = [Projectile.TestSpell.new()]
@onready var max_attack_range: float = (
	attacks.map(func(attack: Spell) -> float: return attack.range()).max()
)
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	# sort ascending by attack range
	attacks.sort_custom(
		func(a1: Spell, a2: Spell) -> bool: return a1.range() < a2.range()
	)
	# TODO: artificially stagger the timers so every enemy doesn't update at the same time
	($NavigationTargetCooldown as Timer).timeout.connect(_update_navigation_target)
	_update_navigation_target()


# TODO: enemy attacks should have a startup and recovery time where they don't move
func _physics_process(delta: float) -> void:
	var distance_to_player := position.distance_to(player.position)
	if can_attack and distance_to_player <= max_attack_range and _has_line_of_sight():
		_calculate_optimal_attack(distance_to_player).fire_attack(self , position.direction_to(player.position))
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
	var direction := position.direction_to(navigation_agent.get_next_path_position())
	var target_vel: Vector2 = direction * max_speed
	velocity += (target_vel - velocity).limit_length(acceleration * delta)

# Too far → move closer
# Too close → back away
# Good distance + LOS → strafe / hold position
# No LOS → move to regain visibility
func _update_navigation_target() -> void:
	var IDEAL_DISTANCE := 300.0
	var DISTANCE_TOLERANCE := 200.0

	var target: Vector2
	var distance := player.position.distance_to(position)
	var has_los := _has_line_of_sight()
	var desired_position := (
		player.global_position - global_position.direction_to(player.global_position)
		* IDEAL_DISTANCE
		)


	if not has_los:
		target = _find_flank_position()
	elif (
		distance > IDEAL_DISTANCE + DISTANCE_TOLERANCE 
		or distance < IDEAL_DISTANCE - DISTANCE_TOLERANCE
	):
		target = desired_position
	else:
		target = _find_flank_position()

	navigation_agent.target_position = target


func _has_line_of_sight(from: Vector2 = global_position) -> bool:
	var space := get_world_2d().direct_space_state

	var query := PhysicsRayQueryParameters2D.create(
		from,
		player.global_position
	)

	query.collision_mask = 0b100000011

	var result := space.intersect_ray(query)

	if result.is_empty():
		return true

	return result.collider == player


func _find_flank_position() -> Vector2:
	const IDEAL_DISTANCE := 300.0
	const FLANK_ANGLE_STEP := 45.0
	const NUM_SAMPLES := 8

	var to_enemy := (global_position - player.global_position).normalized()

	var best_pos := player.global_position
	var best_score := -INF

	for i in range(NUM_SAMPLES):
		var angle := deg_to_rad(i * FLANK_ANGLE_STEP)

		var dir := to_enemy.rotated(angle)

		var candidate := (
			player.global_position
			+ dir * IDEAL_DISTANCE
		)

		if not _is_position_reachable(candidate):
			continue

		var score := 0.0

		# Prefer LOS
		if _has_line_of_sight(candidate):
			score += 1000.0

		# Prefer shorter movement
		score -= global_position.distance_to(candidate)

		# Prefer keeping current side slightly
		score += to_enemy.dot(dir) * 50.0

		if score > best_score:
			best_score = score
			best_pos = candidate

	return best_pos


func _is_position_reachable(target_point: Vector2) -> bool:
	var map := get_world_2d().navigation_map
	var closest_point := NavigationServer2D.map_get_closest_point(map, target_point)
	return (closest_point - target_point).is_zero_approx()


func _die() -> void:
	print("ouch, I've been hit in the knee with an arrow")
	queue_free()


func take_damage() -> void:
	health -= 1
	if health <= 0:
		_die()
