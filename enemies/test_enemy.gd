class_name TestEnemy
extends CharacterBody2D

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
@export var max_speed: float
@export var acceleration: float
@export var health: int = 3

var can_attack: bool = true

@onready var attacks: Array[Spell] = [Projectile.TestSpell.new()]
@onready var max_attack_range: float = (
	attacks.map(func(attack: Spell) -> float: return attack.range()).max()
)
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	# sort ascending by attack range
	attacks.sort_custom(
		func(a1: Spell, a2: Spell) -> bool: return a1.range() < a2.range()
	)
	# TODO: artificially stagger the timers so every enemy doesn't update at the same time
	($NavigationTargetCooldown as Timer).timeout.connect(_update_navigation_target)
	_update_navigation_target()


# TODO: enemy attacks should have a startup and recovery time where they don't move
func _physics_process(delta: float) -> void:
	var distance_to_player := position.distance_to(player.position)
	if can_attack and distance_to_player <= max_attack_range:
		_calculate_optimal_attack(distance_to_player).fire_attack(self , position.direction_to(player.position))
		var timer := Timer.new()
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = randf_range(min_attack_cooldown, max_attack_cooldown)
		timer.timeout.connect(func() -> void: can_attack = true)
		can_attack = false
		add_child(timer)
	else:
		_movement(delta)


# calculate shortest range attack that is within the attack range
func _calculate_optimal_attack(range_to_player: float) -> Spell:
	return attacks[attacks.find_custom(
		func(attack: Spell) -> bool: return attack.range() <= range_to_player
	)]


func _movement(delta: float) -> void:
	var direction := position.direction_to(navigation_agent.get_next_path_position())
	var target_vel: Vector2 = direction * max_speed
	velocity += (target_vel - velocity).limit_length(acceleration * delta)
	move_and_slide()
	velocity = get_real_velocity()


func _update_navigation_target() -> void:
	var target := player.position
	navigation_agent.target_position = target


func _die() -> void:
	print("ouch, I've been hit in the knee with an arrow")
	queue_free()


func take_damage() -> void:
	health -= 1
	if health <= 0:
		_die()
