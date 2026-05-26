class_name Projectile
extends RigidBody2D

@export var speed: float = 400

# A projectile owns the logic for it's own attack


func _ready() -> void:
	body_entered.connect(_on_body_enter)


func _on_body_enter(body: Node2D) -> void:
	assert(body is StaticBody2D or body is TileMapLayer, "unexpected collision with %s" % body.name)
	if body is StaticBody2D and (body as StaticBody2D).collision_layer == 2:
		var player := body.get_parent() as Player
		player.parry_hit(PlayerResources.acquire_spell.bind(TestSpell.new()), player.take_damage)
	else:
		pass # hit the wall animation
	queue_free()

class TestSpell extends Spell:
	const test_projectile: PackedScene = preload("res://enemies/test_projectile.tscn")

	func dummy() -> Node2D:
		return Node2D.new()

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := test_projectile.instantiate() as Projectile
		projectile.position = caster.position
		projectile.linear_velocity = heading.normalized() * projectile.speed
		caster.add_sibling(projectile)
