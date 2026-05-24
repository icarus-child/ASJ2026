extends CharacterBody2D

@export var max_speed: float

func _physics_process(_delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_input * max_speed
	
	move_and_slide()
