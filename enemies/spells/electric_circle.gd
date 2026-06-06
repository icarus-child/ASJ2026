class_name ElectricCircle
extends Node2D

@export var max_radius: float = 400
@export var speed: float = 5

@onready var sprite := $Sprite2D as Sprite2D
@onready var shape := ($Hitbox/CollisionShape2D as CollisionShape2D).shape as CircleShape2D
@onready var shape_scale_amount: float = shape.radius * speed
@onready var art_scale_amount: Vector2 = sprite.scale * speed
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	hitbox.area_entered.connect(_on_area_enter)


func _on_area_enter(body: Area2D) -> void:
	if body.collision_layer == 2:
		var player := body.get_parent() as Player
		player.parry_hit(PlayerResources.acquire_spell.bind(PSpell.new()), player.take_damage.bind(4))
	elif body.collision_layer == 32:
		var enemy := body.get_parent() as Enemy
		enemy.take_damage()
	call_deferred("queue_free")


func _physics_process(delta: float) -> void:
	if shape.radius >= max_radius:
		queue_free()
	shape.radius += shape_scale_amount * delta
	sprite.scale += art_scale_amount * delta


class PSpell extends Spell:
	const spell_scene: PackedScene = preload("res://enemies/spells/electric_circle.tscn")
	var ally_ring: GradientTexture2D = preload("res://assets/enemies/electrician/ally_ring.tres")

	func dummy() -> Node2D:
		return (load("res://enemies/spells/spell_icons/electric_circle_icon.tscn") as PackedScene).instantiate()

	func range() -> float:
		return 100

	func fire_attack(caster: Node2D, heading: Vector2) -> void:
		var projectile := spell_scene.instantiate() as ElectricCircle
		if caster is Player:
			(projectile.get_child(0) as Sprite2D).texture = ally_ring
			(projectile.get_child(1) as Area2D).collision_mask = 32
			var target := NavigationServer2D.map_get_closest_point(
				caster.get_world_2d().navigation_map,
				caster.global_position + heading
			)
			caster.global_position = target
		projectile.position = caster.position
		caster.add_sibling(projectile)
