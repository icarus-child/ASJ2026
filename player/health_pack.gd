extends Node2D

func _ready() -> void:
	($Area2D as Area2D).area_entered.connect(
		func(body: Area2D) -> void:
			var player := body.get_parent() as Player
			player.heal_damage()
	)
