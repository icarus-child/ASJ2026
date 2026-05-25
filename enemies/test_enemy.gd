extends Node2D

# Notes for self
# When attack off cooldown, calculate optimal attack based on current location
#     'optimal' attack prioritizes shortest range attack that will hit
# Calculate path to optimal range for this enemy
# Attack when off cooldown, move when on cooldown

# NOTE: AI should try to avoid being cornered -> handle during pathfinding logic
# NOTE: AI might attack less when the player has a lot of spells to make themselves harder to hit?

# the ai needs to know how far it can move before it's cooldown is done so it can
# move intelligently between attacks (?) i.e. it prioritizes local optimums

@export var min_attack_cooldown: float = 3
@export var max_attack_cooldown: float = 6

var can_attack: bool = true

@onready var test_projectile := preload("res://enemies/test_projectile.tscn") as PackedScene
@onready var attacks: Array[Spell] = [
	Spell.new(300, true, func(player_ref: CharacterBody2D) -> void: _shoot_projectile(player_ref))
]
@onready var max_attack_range: float = (
	attacks.map(func(attack: Spell) -> float: return attack.attack_range).max()
)
@onready var player: CharacterBody2D = get_parent().get_node("Player")


func _ready() -> void:
	# sort ascending by attack range
	attacks.sort_custom(
		func(a1: Spell, a2: Spell) -> bool: return a1.attack_range < a2.attack_range
	)


func _process(_delta: float) -> void:
	var distance_to_player := _get_distance_to_player()
	if can_attack and distance_to_player <= max_attack_range:
		_calculate_optimal_attack(distance_to_player).attack_action.call(player)
		var timer := Timer.new()
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = randf_range(min_attack_cooldown, max_attack_cooldown)
		timer.timeout.connect(func() -> void: can_attack = true)
		can_attack = false
		add_child(timer)


# calculate shortest range attack that is within the attack range
func _calculate_optimal_attack(range_to_player: float) -> Spell:
	return attacks[attacks.find_custom(
		func(attack: Spell) -> bool: return attack.attack_range <= range_to_player
	)]


func _get_distance_to_player() -> float:
	return position.distance_to(player.position)


func _shoot_projectile(target: Node2D) -> void:
	var projectile := test_projectile.instantiate() as Projectile
	add_sibling(projectile)
	projectile.position = position
	projectile.linear_velocity = position.direction_to(target.position) * projectile.speed
