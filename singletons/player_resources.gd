extends Node

signal game_over
signal level_done
signal game_won
signal health_changed(health: int)
signal spell_changed(slot: int)

var current_level: int = 0
var last_level: int = 2
var levels: Array[PackedScene] = [
	preload("res://levels/level_one.tscn"),
	preload("res://levels/level_two.tscn"),
	preload("res://levels/level_three.tscn")
]

var max_health: int = 20
var _health: int = max_health
var health: int:
	get:
		return _health
	set(value):
		var new_health := clampi(value, 0, max_health)
		if new_health != _health:
			_health = new_health
			health_changed.emit(new_health)
		if _health == 0:
			print("game over")
			game_over.emit()


var spells: Array[Spell]


func _ready() -> void:
	spells.resize(3)


func _load_level(level_index: int) -> void:
	var tree_scene := get_tree().current_scene
	if tree_scene.get_child_count() > 4:
		var level: Node = tree_scene.get_child(4)
		level.call_deferred("queue_free")
	tree_scene.call_deferred("add_child", levels[level_index].instantiate())


func restart_game() -> void:
	get_tree().reload_current_scene()
	health = max_health
	spells.resize(0)
	spells.resize(3)
	# _load_level(0)


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


func load_next_level() -> void:
	current_level += 1
	assert(current_level <= last_level)
	_load_level(current_level)


func load_current_level() -> void:
	assert(current_level <= last_level)
	_load_level(current_level)
