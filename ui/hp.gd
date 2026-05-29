extends Sprite2D

func _update_health(value: int) -> void:
	for child: Sprite2D in get_children():
		child.visible = value > 0
		value -= 1
