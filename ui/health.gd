extends Node2D

@export var padding: float

const HP = preload("res://ui/hp.gd")
var pips: Array[HP]

func _ready() -> void:
	PlayerResources.health_changed.connect(_update_health)

	@warning_ignore("integer_division")
	for i in range((PlayerResources.max_health + 3) / 4):
		var new_hp: Node2D = preload("res://ui/hp.tscn").instantiate()
		new_hp.position.x += padding * i
		add_child(new_hp)
		pips.push_back(new_hp)

func _update_health(value: int) -> void:
	for pip in pips:
		pip._update_health(value)
		value -= 4