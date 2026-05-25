class_name Spell
extends Node

var attack_range: float
var attack_action: Callable
var can_parry: bool


func _init(range_in: float, can_parry_in: bool, action_in: Callable) -> void:
	attack_range = range_in
	can_parry = can_parry_in
	attack_action = action_in
