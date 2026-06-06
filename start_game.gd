extends Control


func _start_game() -> void:
	visible = false
	PlayerResources._load_level(0)
