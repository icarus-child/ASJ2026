class_name LobTarget
extends Node2D

@onready var hitbox: Area2D = $Area2D


func _hit_area() -> void:
	for body in hitbox.get_overlapping_areas():
		if body is Area2D and (body as Area2D).collision_layer == 2:
			var player := body.get_parent() as Player
			player.parry_hit(PlayerResources.acquire_spell.bind(Lob.PSpell.new()), player.take_damage.bind(4))
		elif body is Area2D and (body as Area2D).collision_layer == 32:
			var enemy := body.get_parent() as Enemy
			enemy.take_damage()
