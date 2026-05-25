class_name Player
extends CharacterBody2D

@export var max_speed: float
@export var max_accel: float

# TODO: make player controller feel snappier
var facing := Vector2(0, 1)

func _physics_process(delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down").limit_length()
	if not move_input.is_zero_approx():
		facing = move_input.normalized()
	var target_vel: Vector2 = move_input * max_speed
	velocity += (target_vel - velocity).limit_length(max_accel * delta)
	move_and_slide()
	velocity = get_real_velocity()

func recieve_attack(damage: int = 1, can_parry: bool = true, custom_logic: Callable = func(_player: CharacterBody2D) -> void: return) -> void:
	if can_parry:
		pass
	print("got hit")
	PlayerResources.health = max(0, PlayerResources.health - damage)
	if PlayerResources.health <= 0:
		print("game over") # handle game over
	custom_logic.call(self)
