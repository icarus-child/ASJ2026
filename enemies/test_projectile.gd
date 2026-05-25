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
		player.recieve_attack()
	else:
		pass  # hit the wall animation
	queue_free()
