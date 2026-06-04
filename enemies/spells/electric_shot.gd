class_name ElectricShot
extends RigidBody2D

@export var speed: float = 400

var ally_shot: GradientTexture2D = preload("res://assets/enemies/electrician/ally_shot.tres")

@onready var particles: GPUParticles2D = $Particles2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	body_entered.connect(_on_body_enter)
	hitbox.area_entered.connect(_on_area_enter)


func _on_area_enter(body: Area2D) -> void:
	if body.collision_layer == 2:
		var player := body.get_parent() as Player
		player.parry_hit(PlayerResources.acquire_spell.bind(PSpell.new()), player.take_damage.bind(4))
	elif body.collision_layer == 32:
		var enemy := body.get_parent() as Enemy
		enemy.take_damage()
	_cleanup_particles()
	call_deferred("queue_free")


func _on_body_enter(_body: Node) -> void:
	_cleanup_particles()
	call_deferred("queue_free")


func _cleanup_particles() -> void:
	particles.emitting = false
	particles.finished.connect(particles.queue_free)
	remove_child(particles)
	particles.position = position
	get_parent().add_child(particles)


class PSpell extends Spell:
	const spell_scene: PackedScene = preload("res://enemies/spells/electric_shot.tscn")

	func dummy() -> Node2D:
		var spell := spell_scene.instantiate()
		(spell.get_child(2).get_child(0) as CollisionShape2D).disabled = true
		return spell

	func range() -> float:
		return 400

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := spell_scene.instantiate() as ElectricShot
		if caster is Player:
			(projectile.get_child(0) as Sprite2D).texture = projectile.ally_shot
			(projectile.get_child(2) as Area2D).collision_mask = 32
		projectile.position = caster.position
		projectile.linear_velocity = heading.normalized() * projectile.speed
		caster.add_sibling(projectile)
		if caster is Player:
			projectile.particles.texture = projectile.ally_shot
