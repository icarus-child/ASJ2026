extends Control


func _start_game() -> void:
	visible = false
	PlayerResources.load_current_level()
