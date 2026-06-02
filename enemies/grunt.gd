class_name grunt
extends Enemy

var speed: float = 300
var acceleration: float = 500
var deceleration: float = 500
var reposition_target: Vector2

var attack_startup: float = 0.5
var attack_recovery: float = 1
var recovering_from_attack: bool = false

var attack_range: float = 200
var lunge_velocity: float = 600

var lunge_direction: Vector2

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var avoid_shape: Area2D = $AvoidShape
@onready var hitbox: Area2D = $Hitbox


func _custom_ready() -> void:
	hitbox.body_entered.connect(_on_hit_player)

# TODO: enemy won't stop and attack when inside of an obstacle
func _physics_process(delta: float) -> void:
	var distance_to_player := position.distance_to(player.position)
	if distance_to_player <= attack_range and _has_line_of_sight() and not recovering_from_attack:
		recovering_from_attack = true
		lunge_direction = global_position.direction_to(player.global_position)
		_lunge()
	elif not recovering_from_attack:
		_movement(delta)
	else:
		var s: float = max(0.0, velocity.length() - deceleration * delta)
		velocity = velocity.normalized() * s
	move_and_slide()
	velocity = get_real_velocity()


func _movement(delta: float) -> void:
	var target_pos := navigation_agent.get_next_path_position()
	var move_dir := position.direction_to(target_pos)
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

	var remaining_distance := navigation_agent.distance_to_target() - (attack_range - 50)
	var stopping_distance := velocity.length_squared() / (2.0 * deceleration)

	var target_speed := speed
	var accel := acceleration
	if remaining_distance <= stopping_distance:
		target_speed = 0.0
		accel = deceleration
	else:
		target_speed = speed
		accel = acceleration

	var target_vel := final_dir * target_speed

	velocity = velocity.move_toward(
		target_vel,
		accel * delta
	)


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


func _update_navigation_target() -> void:
	navigation_agent.target_position = player.global_position


func _die() -> void:
	print("now i am become death")
	queue_free()


func _create_timer(duration: float, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = duration
	timer.timeout.connect(callback)
	return timer


func _lunge() -> void:
	add_child(_create_timer(attack_startup,
		func() -> void: 
			velocity = lunge_velocity * lunge_direction
			add_child(_create_timer(attack_recovery,
				func() -> void: 
					recovering_from_attack = false
			))
	))


func _on_hit_player(_body: Node2D) -> void:
	player.take_damage(4)
