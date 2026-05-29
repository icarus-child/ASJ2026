@abstract
class_name Enemy
extends CharacterBody2D

@abstract func _update_navigation_target() -> void
@abstract func _die() -> void

@export var min_attack_cooldown: float
@export var max_attack_cooldown: float
@export var attack_recovery: float
@export var speed: float
@export var acceleration: float
@export var ideal_distance: float
@export var health: int

var can_attack: bool = true
var recovering_from_attack: bool = false

@onready var attacks: Array[Spell]
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
		timer2.wait_time = attack_recovery
		timer2.timeout.connect(func() -> void: recovering_from_attack = false)
		recovering_from_attack = true
		add_child(timer2)
		add_child(timer)
	elif not recovering_from_attack:
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


func take_damage(damage: int = 1) -> void:
	health -= damage
	if health <= 0:
		_die()
