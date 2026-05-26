extends Node

var health: int = 5 # hollow knight style health, where damage is discrete. Not Final

var spells: Array[Spell]

signal spell_changed(slot: int)

func _ready() -> void:
	spells.resize(3)

func acquire_spell(spell: Spell) -> void:
	for s in range(spells.size()):
		if spells[s] == null:
			spells[s] = spell
			spell_changed.emit(s)
			break
