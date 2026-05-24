class_name Projectile
extends RigidBody2D

@export var speed: float = 400

# A projectile owns the logic for it's own attack


func _ready() -> void:
	body_entered.connect(_on_body_enter)


func _on_body_enter(body: CollisionObject2D) -> void:
	assert(body is Player or body is StaticBody2D, "unexpected collision with %s" % body.name)
	if body is Player:
		var player := body as Player
		player.recieve_attack()
	else:
		pass  # hit the wall animation
	queue_free()
