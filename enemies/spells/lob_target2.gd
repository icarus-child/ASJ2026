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
	var hit_player := false
	for body in hitbox.get_overlapping_areas():
		if body is Area2D and (body as Area2D).collision_layer == 2:
			hit_player = true
			var player := body.get_parent() as Player
			player.parry_hit(PlayerResources.acquire_spell.bind(Lob.PSpell.new()),
				func() -> void:
					player.take_damage(2)
					_spawn_acid(global_position)
			)
		elif body is Area2D and (body as Area2D).collision_layer == 32:
			var enemy := body.get_parent() as Enemy
			enemy.take_damage()
	if not hit_player:
		_spawn_acid(global_position)


func _spawn_acid(pos: Vector2) -> void:
	var acid: Node2D = acid_scene.instantiate()
	acid.global_position = pos
	add_sibling(acid)
