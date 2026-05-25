class_name AimTarget
extends Sprite2D

@export var aim_range: float
@export var hide_range: float

var mouse_active: bool = false

func _physics_process(_delta: float) -> void:
	if mouse_active:
		global_position = get_viewport().get_camera_2d().get_global_mouse_position()
	else:
		var right_stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down").limit_length()
		position = right_stick * aim_range
	print(position.length())
	visible = position.length() > hide_range


func _input(event: InputEvent) -> void:
	if (InputMap.event_is_action(event, "aim_left") or
		InputMap.event_is_action(event, "aim_right") or
		InputMap.event_is_action(event, "aim_up") or
		InputMap.event_is_action(event, "aim_down")):
		mouse_active = false

	if event is InputEventMouseMotion:
		mouse_active = true