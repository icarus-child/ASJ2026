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
	visible = position.length() > hide_range

	var slot: int = 0
	for slot_action: StringName in ["spell_1", "spell_2", "spell_3"]:
		if slot > PlayerResources.spells.size():
			break
		if Input.is_action_just_pressed(slot_action) && not PlayerResources.spells[slot] == null:
			PlayerResources.spells[slot].fire_attack(get_parent() as Node2D, position)
			PlayerResources.spells[slot] = null
			PlayerResources.spell_changed.emit(slot)
			break
		slot += 1

func _input(event: InputEvent) -> void:
	if (InputMap.event_is_action(event, "aim_left") or
		InputMap.event_is_action(event, "aim_right") or
		InputMap.event_is_action(event, "aim_up") or
		InputMap.event_is_action(event, "aim_down")):
		mouse_active = false

	if event is InputEventMouseMotion:
		mouse_active = true
