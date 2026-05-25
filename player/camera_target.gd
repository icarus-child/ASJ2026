extends Node2D

@export_range(0.0, 1.0) var aim_influence: float = 0.5

@onready var aim_target: AimTarget = get_node("../AimTarget")

func _physics_process(_delta: float) -> void:
	position = aim_target.position.limit_length(aim_target.aim_range) * aim_influence
