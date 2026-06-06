extends Sprite2D

@onready var end_level_zone: Node2D = get_parent().get_parent().get_child(1)


func _ready() -> void:
	PlayerResources.level_done.connect(func() -> void: visible = true)


func _physics_process(_delta: float) -> void:
	look_at(end_level_zone.global_position)
