class_name ElectricShot
extends RigidBody2D

@export var speed: float = 400

# A projectile owns the logic for it's own attack


func _ready() -> void:
	body_entered.connect(_on_body_enter)


func _on_body_enter(body: Node2D) -> void:
	if body is StaticBody2D and (body as StaticBody2D).collision_layer == 2:
		var player := body.get_parent() as Player
		player.parry_hit(PlayerResources.acquire_spell.bind(PSpell.new()), player.take_damage.bind(4))
	elif body is StaticBody2D and (body as StaticBody2D).collision_layer == 32:
		var enemy := body.get_parent() as Enemy
		enemy.take_damage()
	else:
		pass # hit the wall animation

	var particles: GPUParticles2D = $Particles2D
	particles.emitting = false
	particles.finished.connect(particles.queue_free)
	remove_child(particles)
	particles.position = position
	get_parent().add_child(particles)
	call_deferred("queue_free")


class PSpell extends Spell:
	const spell_scene: PackedScene = preload("res://enemies/spells/electric_shot.tscn")

	func dummy() -> Node2D:
		return spell_scene.instantiate()

	func range() -> float:
		return 400

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := spell_scene.instantiate() as ElectricShot
		if caster is Player:
			projectile.collision_mask = 288
		projectile.position = caster.position
		projectile.linear_velocity = heading.normalized() * projectile.speed
		caster.add_sibling(projectile)
