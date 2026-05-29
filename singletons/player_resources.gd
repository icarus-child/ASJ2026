extends Node

var max_health: int = 20
var _health: int = max_health
var health: int:
	get:
		return _health
	set(value):
		var new_health := clampi(value, 0, max_health)
		print(new_health)
		if new_health != _health:
			_health = new_health
			health_changed.emit(new_health)
		if _health == 0:
			print("game over")

signal health_changed(health: int)

var spells: Array[Spell]

signal spell_changed(slot: int)

func _ready() -> void:
	spells.resize(4)
	#change_spells_size(4)

func acquire_spell(spell: Spell) -> void:
	for s in range(spells.size()):
		if spells[s] == null:
			spells[s] = spell
			spell_changed.emit(s)
			break

func can_acquire_spell() -> bool:
	for s in spells:
		if s == null:
			return true
	return false

func change_spells_size(size: int) -> void:
	spells.resize(size)
	# update UI
