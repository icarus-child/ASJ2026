class_name LobTarget
extends Node2D

@onready var hitbox: Area2D = $Area2D

func _ready() -> void:
	hitbox.body_entered.connect(print.bind("body entered"))


func _hit_area() -> void:
	print("hitting")
	print(len(hitbox.get_overlapping_bodies()))
	for body in hitbox.get_overlapping_bodies():
		print(typeof(body))
		if body is StaticBody2D and (body as StaticBody2D).collision_layer == 2:
			var player := body.get_parent() as Player
			(body as Player).parry_hit(PlayerResources.acquire_spell.bind(Lob.PSpell.new()), player.take_damage.bind(4))
		elif body is StaticBody2D and (body as StaticBody2D).collision_layer == 32:
			var enemy := body.get_parent() as Enemy
			enemy.take_damage()
