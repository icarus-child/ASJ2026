class_name Projectile
extends RigidBody2D

@export var speed: float = 400

# A projectile owns the logic for it's own attack


func _ready() -> void:
	body_entered.connect(_on_body_enter)


func _on_body_enter(body: Node2D) -> void:
	if body is Area2D and (body as Area2D).collision_layer == 2:
		var player := body.get_parent() as Player
		player.parry_hit(PlayerResources.acquire_spell.bind(TestSpell.new()), player.take_damage)
	elif body is Area2D and (body as Area2D).collision_layer == 32:
		var enemy := body.get_parent() as Enemy
		enemy.take_damage()
	else:
		pass # hit the wall animation
	queue_free()

class TestSpell extends Spell:
	const test_projectile: PackedScene = preload("res://enemies/spells/test_projectile.tscn")

	func dummy() -> Node2D:
		return test_projectile.instantiate()

	func range() -> float:
		return 400

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := test_projectile.instantiate() as Projectile
		if caster is Player:
			projectile.set_collision_mask_value(2, false)
			projectile.set_collision_mask_value(6, true)
		projectile.position = caster.position
		projectile.linear_velocity = heading.normalized() * projectile.speed
		caster.add_sibling(projectile)
