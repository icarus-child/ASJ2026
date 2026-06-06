extends Control


func _ready() -> void:
	get_tree().paused = true


func _start_game() -> void:
	visible = false
	get_tree().paused = false
