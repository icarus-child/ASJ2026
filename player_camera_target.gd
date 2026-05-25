extends Node2D

@export var distance: float

func _process(_delta: float) -> void:
	position = (get_parent() as Player).facing * distance
