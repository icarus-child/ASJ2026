extends TextureRect

@export var slot_number: int
var _dummy: Node2D

func _ready() -> void:
	PlayerResources.spell_changed.connect(_on_slot_change)

func _on_slot_change(slot: int) -> void:
	if slot != slot_number:
		return
	
	var spell := PlayerResources.spells[slot]
	if spell == null:
		_dummy.queue_free()
		return
	
	_dummy = spell.dummy()
	call_deferred("add_child", _dummy)
