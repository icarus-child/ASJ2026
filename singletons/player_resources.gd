extends Node

var health: int = 5 # hollow knight style health, where damage is discrete. Not Final

var spells: Array[Spell]

signal spell_changed(slot: int)

func _ready() -> void:
	spells.resize(3)
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
