extends Node2D

@export var padding: float

var last_health: int = 0

func _process(_delta: float) -> void:
	if PlayerResources.health == last_health:
		return
	
	if PlayerResources.health < last_health:
		get_child(-1).queue_free()
		last_health -= 1

	if PlayerResources.health > last_health:
		var new_hp: Node2D = preload("res://ui/hp.tscn").instantiate()
		new_hp.position.x += padding * last_health
		add_child(new_hp)
		last_health += 1
