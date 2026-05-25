extends Camera2D

@export var target: Node2D
@export var accel: float

func _ready() -> void:
	position = target.global_position

func _physics_process(delta: float) -> void:
	var target_pos := target.global_position
	var distance := target_pos - position
	var velocity := distance * accel
	position += velocity * delta
