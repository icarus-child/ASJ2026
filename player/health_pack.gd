extends Node2D

func _ready() -> void:
	($Area2D as Area2D).area_entered.connect(_on_area_enter)


func _on_area_enter(body: Area2D) -> void:
	var player := body.get_parent() as Player
	if PlayerResources.health == PlayerResources.max_health:
		return
	player.heal_damage(4)
	($AudioStreamPlayer as AudioStreamPlayer).play()
	queue_free()
