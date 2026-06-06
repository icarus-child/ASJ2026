extends Control

func _ready() -> void:
	PlayerResources.game_over.connect(_on_game_over)


func _on_game_over() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	get_tree().paused = true


func _restart_game() -> void:
	get_tree().paused = false
	PlayerResources.restart_game()
