class_name LobTarget
extends Node2D

var acid_scene: PackedScene = preload("res://enemies/area_denial/acid.tscn")
@onready var hitbox: Area2D = $Area2D


func _hit_area() -> void:
	for body in hitbox.get_overlapping_areas():
		if body is Area2D and (body as Area2D).collision_layer == 2:
			var player := body.get_parent() as Player
			player.parry_hit(PlayerResources.acquire_spell.bind(Lob.PSpell.new()), player.take_damage.bind(4))
		elif body is Area2D and (body as Area2D).collision_layer == 32:
			var enemy := body.get_parent() as Enemy
			enemy.take_damage()


func _hit_area_acid() -> void:
	for body in hitbox.get_overlapping_areas():
		if body is Area2D and (body as Area2D).collision_layer == 2:
			var player := body.get_parent() as Player
			player.parry_hit(PlayerResources.acquire_spell.bind(AcidLob.PSpell.new()), player.take_damage.bind(4))
		elif body is Area2D and (body as Area2D).collision_layer == 32:
			var enemy := body.get_parent() as Enemy
			enemy.take_damage()
	_spawn_acid()


func _spawn_acid() -> void:
	var acid: Node2D = acid_scene.instantiate()
	acid.global_position = global_position
	add_sibling(acid)
