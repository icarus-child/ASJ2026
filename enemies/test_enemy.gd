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

@export var min_attack_cooldown: float
@export var max_attack_cooldown: float

var can_attack: bool = true

@onready var attacks: Array[Spell] = [Projectile.TestSpell.new()]
@onready var max_attack_range: float = (
	attacks.map(func(attack: Spell) -> float: return attack.range()).max()
)
@onready var player: CharacterBody2D = get_parent().get_node("Player")


func _ready() -> void:
	# sort ascending by attack range
	attacks.sort_custom(
		func(a1: Spell, a2: Spell) -> bool: return a1.range() < a2.range()
	)


func _physics_process(_delta: float) -> void:
	var distance_to_player := _get_distance_to_player()
	if can_attack and distance_to_player <= max_attack_range:
		_calculate_optimal_attack(distance_to_player).fire_attack(self , position.direction_to(player.position))
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
		func(attack: Spell) -> bool: return attack.range() <= range_to_player
	)]


func _get_distance_to_player() -> float:
	return position.distance_to(player.position)
