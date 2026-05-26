@abstract
class_name Spell
extends Object

@abstract func dummy() -> Node2D

@abstract func fire_attack(caster: Node2D, heading: Vector2) -> void

# This is a func so that it can be overriden
func range() -> float:
	return INF
