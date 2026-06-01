class_name ElectricCircle
extends RigidBody2D

@export var max_radius: float = 400
@export var speed: float = 5

@onready var sprite := $Sprite2D as Sprite2D
@onready var shape := ($CollisionShape2D as CollisionShape2D).shape as CircleShape2D
@onready var shape_scale_amount: float = shape.radius * speed
@onready var art_scale_amount: Vector2 = sprite.scale * speed

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
	queue_free()


func _physics_process(delta: float) -> void:
	if shape.radius >= max_radius:
		queue_free()
	shape.radius += shape_scale_amount * delta
	sprite.scale += art_scale_amount * delta
	# print("shape: %s - sprite: %s" % [shape.radius/10, sprite.scale/0.156])


class PSpell extends Spell:
	const spell_scene: PackedScene = preload("res://enemies/spells/electric_circle.tscn")

	func dummy() -> Node2D:
		return (load("res://enemies/spells/spell_icons/electric_circle_icon.tscn") as PackedScene).instantiate()

	func range() -> float:
		return 100

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := spell_scene.instantiate() as ElectricCircle
		if caster is Player:
			projectile.collision_mask = 32
		projectile.position = caster.position
		projectile.linear_velocity = heading.normalized() * projectile.speed
		caster.add_sibling(projectile)
