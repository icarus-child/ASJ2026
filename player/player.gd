class_name Player
extends CharacterBody2D

@export var max_speed: float
@export var max_accel: float

@onready var hurtbox: StaticBody2D = $Hurtbox
@onready var parrybox: CollisionShape2D = $Parrybox/CollisionShape2D
@onready var parry_cooldown_timer: Timer = $ParryCooldown
@onready var parry_early_window: Timer = $ParryEarlyWindow
@onready var parry_late_window: Timer = $ParryLateWindow
@onready var parry_freeze_timer: Timer = $ParryFreeze
@onready var anim: PlayerAnimTree = $AnimationTree
@onready var shader: ShaderMaterial = ($Sprite2D as Sprite2D).material
@onready var hit_recolor_timer: Timer = $HitRecolorTime


func _ready() -> void:
	parry_freeze_timer.timeout.connect(func() -> void: get_tree().paused = false)
	parry_early_window.timeout.connect(func() -> void: parrybox.disabled = true)
	# hit_recolor_timer.timeout.connect(shader.set_shader_parameter.bind("hit", false))


func _physics_process(delta: float) -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down").limit_length()
	var target_vel: Vector2 = move_input * max_speed
	velocity += (target_vel - velocity).limit_length(max_accel * delta)
	move_and_slide()
	velocity = get_real_velocity()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("parry") and parry_cooldown_timer.is_stopped() and PlayerResources.can_acquire_spell():
		parrybox.disabled = false
		anim.parry()
		if not parry_late_window.is_stopped() and not parry_cooldown_timer.is_stopped():
			parry_late_window.stop()
			defer_parry.call()
		parry_early_window.start()
		parry_cooldown_timer.start()

var defer_parry: Callable

# This function is called by projectiles that can be parried
# One of these callbacks will be called depending on if a parry was performed in time or not
# These callbacks are responsible for actually dealing damage or stocking a spell
func parry_hit(parried: Callable, hit: Callable) -> void:
	call_deferred("_disable_parrybox")
	if not PlayerResources.can_acquire_spell():
		hit.call()

	var on_parry: Callable = func() -> void:
		parried.call()
		parry_freeze_timer.start()
		get_tree().paused = true
		
	# if we parry early -> start timer & cooldown
	# if we get hit when parry early timer is started -> parry and refund cooldown
	# if we get hit without parry early timer but with parry late timer -> trigger old parry late timer and start a new one
	if not parry_late_window.is_stopped():
		parry_late_window.stop()
		parry_late_window.timeout.emit()
		signal_disconnect_all(parry_late_window.timeout)
		parry_late_window.timeout.connect(hit)
		parry_late_window.start()

	if not parry_early_window.is_stopped():
		parry_early_window.stop()
		parry_cooldown_timer.stop()
		on_parry.call()
	else:
		# shader.set_shader_parameter("hit", true)
		# hit_recolor_timer.start()
		signal_disconnect_all(parry_late_window.timeout)
		parry_late_window.timeout.connect(hit)
		parry_late_window.start()
		defer_parry = on_parry

# Parry has failed
func take_damage(amount: int = 1) -> void:
	anim.hurt()
	PlayerResources.health -= amount

func signal_disconnect_all(target_signal: Signal) -> void:
	for n: Dictionary in target_signal.get_connections():
		var callable_variant: Variant = n.get("callable")
		assert(callable_variant is Callable)
		var callable: Callable = callable_variant
		target_signal.disconnect(callable as Callable)


func _disable_parrybox() -> void:
	parrybox.disabled = true


@onready var poison_timer: Timer = $PoisonTimer
@onready var poison_particles: GPUParticles2D = $PoisonParticles

var _in_poison: int = 0
var in_poison: int:
	get:
		return _in_poison
	set(value):
		if (_in_poison > 0) == (value > 0):
			_in_poison = value
			return
		_in_poison = value

		if in_poison > 0:
			if poison_timer.is_stopped():
				_take_poison_damage()
				poison_timer.start()
			poison_timer.one_shot = false
		else:
			poison_timer.one_shot = true

func _take_poison_damage() -> void:
	if in_poison > 0:
		poison_particles.restart()
		take_damage()