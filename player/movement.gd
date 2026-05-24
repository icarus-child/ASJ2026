extends CharacterBody2D

@export var max_speed: float
@export var max_accel: float

func _physics_process(delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down").limit_length()
	var target_vel: Vector2 = move_input * max_speed
	velocity += (target_vel - velocity).limit_length(max_accel * delta)
	move_and_slide()
	velocity = get_real_velocity()
