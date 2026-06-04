class_name Lob
extends RigidBody2D

@export var hang_time: float = 1.8

# A projectile owns the logic for it's own attack

class PSpell extends Spell:
	const projectile_scene: PackedScene = preload("res://enemies/spells/lob.tscn")
	const target_scene: PackedScene = preload("res://enemies/spells/lob_target.tscn")

	func dummy() -> Node2D:
		var d: Node = projectile_scene.instantiate()
		(d.get_node("AnimationPlayer") as AnimationPlayer).active = false
		return d

	func range() -> float:
		return INF

	func fire_attack(caster: Node2D, target_pos: Vector2) -> void:
		var target := target_scene.instantiate() as LobTarget
		var projectile := projectile_scene.instantiate() as Lob
		if caster is Player:
			target_pos += caster.global_position
			var area: Area2D = target.get_child(1)
			area.set_collision_mask_value(2, false)
			area.set_collision_mask_value(6, true)
		target.global_position = target_pos
		caster.add_sibling(target)
		caster.add_sibling(_create_timer(1,
			func() -> void:
				projectile.position = caster.position
				var heading := target_pos - caster.global_position
				projectile.linear_velocity = heading / projectile.hang_time
				caster.add_sibling(projectile)
		))

	func _create_timer(duration: float, callback: Callable) -> Timer:
		var timer := Timer.new()
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = duration
		timer.timeout.connect(callback)
		return timer
