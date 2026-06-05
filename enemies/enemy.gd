@abstract
class_name Enemy
extends CharacterBody2D

@abstract func _update_navigation_target() -> void
@abstract func _die() -> void

@export var health: int

var health_pack_scene: PackedScene = preload("res://player/health_pack.tscn")

@onready var player: Player = get_parent().get_parent().get_node("Player")
@onready var anim: EnemyAnimTree = $AnimationTree


func _ready() -> void:
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = randf_range(0.5, 1)
	timer.timeout.connect(_update_navigation_target)
	add_child(timer)

	_custom_ready()


func _custom_ready() -> void:
	pass


func _has_line_of_sight(from: Vector2 = global_position) -> bool:
	var space := get_world_2d().direct_space_state

	var query := PhysicsRayQueryParameters2D.create(
		from,
		player.global_position
	)

	query.collision_mask = 0b110000001

	var result := space.intersect_ray(query)

	if result.is_empty():
		return true

	return result.collider == player


func take_damage(damage: int = 1) -> void:
	health -= damage
	if anim:
		anim.hurt()
	if health <= 0:
		_attempt_spawn_healthpack()
		_die()


func _attempt_spawn_healthpack() -> void:
	if randf() <= 5.0/5:
		var health_pack: Node2D = health_pack_scene.instantiate()
		health_pack.global_position = global_position
		player.add_sibling(health_pack)
