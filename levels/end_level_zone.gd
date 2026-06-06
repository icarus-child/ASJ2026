extends Node2D


@onready var area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D


func _ready() -> void:
	area.area_entered.connect(_on_area_enter)
	PlayerResources.level_done.connect(_on_level_done)


func _on_area_enter(_area: Area2D) -> void:
	if PlayerResources.current_level < PlayerResources.last_level:
		PlayerResources.load_next_level()
	else:
		($CanvasLayer as CanvasLayer).visible = true
		get_tree().paused = true


func _on_level_done() -> void:
	visible = true
	collision.disabled = false
