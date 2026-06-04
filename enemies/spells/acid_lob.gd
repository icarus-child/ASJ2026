class_name AcidLob
extends RigidBody2D

@export var hang_time: float = 5.0
const max_range: float = 500

# A projectile owns the logic for it's own attack


func _ready() -> void:
	body_entered.connect(_on_body_enter)


func _on_body_enter(body: Node2D) -> void:
	if body is Area2D and (body as Area2D).collision_layer == 2:
		var player := body.get_parent() as Player
		player.parry_hit(PlayerResources.acquire_spell.bind(PSpell.new()), player.take_damage)
	elif body is Area2D and (body as Area2D).collision_layer == 32:
		var enemy := body.get_parent() as Enemy
		enemy.take_damage()
	else:
		pass # hit the wall animation
	queue_free()

class PSpell extends Spell:
	const scene: PackedScene = preload("res://enemies/spells/lob.tscn")

	func dummy() -> Node2D:
		var d: Node = scene.instantiate()
		(d.get_node("AnimationPlayer") as AnimationPlayer).active = false
		return d

	func range() -> float:
		return max_range

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := scene.instantiate() as Lob
		if caster is Player:
			projectile.set_collision_mask_value(2, false)
			projectile.set_collision_mask_value(6, true)
		projectile.position = caster.position
		projectile.linear_velocity = heading.limit_length(max_range) / projectile.hang_time
		print(heading)
		caster.add_sibling(projectile)
