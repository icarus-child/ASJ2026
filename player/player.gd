class_name Player
extends CharacterBody2D

@export var max_speed: float
@export var max_accel: float

@onready var hurtbox: StaticBody2D = $Hurtbox
@onready var parry_cooldown: Timer = $ParryCooldown
@onready var parry_early_window: Timer = $ParryEarlyWindow
@onready var parry_late_window: Timer = $ParryLateWindow


# TODO: make player controller feel snappier
func _physics_process(delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down").limit_length()
	var target_vel: Vector2 = move_input * max_speed
	velocity += (target_vel - velocity).limit_length(max_accel * delta)
	move_and_slide()
	velocity = get_real_velocity()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("parry") and parry_cooldown.is_stopped():
		if not parry_late_window.is_stopped():
			parry_late_window.stop()
			parry()
		parry_early_window.start()
		parry_cooldown.start()
			

# if we parry early -> start timer & cooledown
# if we get hit when parry early timer is started -> parry and refund cooldown
# if we get hit without parry early timer but with parry late timer -> trigger old parry late timer and start a new one
# NOTE: does it feel better to keep an array backlog of grace windows and let you parry them all at once?
# how would this function with the parry limit of 3?
func recieve_attack(damage: int = 1, attack_can_be_parried: bool = true, custom_logic: Callable = func(_player: CharacterBody2D) -> void: return) -> void:
	var hit_logic: Callable = func() -> void:
		print("got hit")
		PlayerResources.health = max(0, PlayerResources.health - damage)
		if PlayerResources.health <= 0:
			print("game over")
		custom_logic.call(self)

	# got hit before we parried the last attack, ending grace window
	if not parry_late_window.is_stopped():
		parry_late_window.stop()
		parry_late_window.timeout.emit()
		signal_disconnect_all(parry_late_window.timeout)
		parry_late_window.timeout.connect(hit_logic)
		parry_late_window.start()

	if attack_can_be_parried:
		if not parry_early_window.is_stopped():
			parry_early_window.stop()
			parry_cooldown.stop()
			parry()
		else:
			signal_disconnect_all(parry_late_window.timeout)
			parry_late_window.timeout.connect(hit_logic)
			parry_late_window.start()
	else:
		hit_logic.call()



func parry() -> void:
	print("parried attack")



func signal_disconnect_all(target_signal : Signal) -> void:
	for n: Dictionary in target_signal.get_connections():
		var callable_variant: Variant = n.get("callable")
		assert(callable_variant is Callable)
		var callable: Callable = callable_variant
		target_signal.disconnect(callable as Callable)
