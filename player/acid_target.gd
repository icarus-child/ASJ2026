class_name AcidTarget
extends Area2D

@onready var timer: Timer = $Timer
@onready var particles: GPUParticles2D = $Particles

signal poisoned_changed(poison: bool)
signal take_damage

var _poisoned: bool = false
var poisoned: bool:
	get:
		return _poisoned
	set(value):
		if _poisoned == value:
			return
		_poisoned = value
		poisoned_changed.emit(value)

		if poisoned:
			if timer.is_stopped():
				_timeout()
				timer.start()
			timer.one_shot = false
		else:
			timer.one_shot = true

func _ready() -> void:
	area_entered.connect(check_acid.unbind(1))
	area_exited.connect(check_acid.unbind(1))
	timer.timeout.connect(_timeout)

func check_acid() -> void:
	poisoned = has_overlapping_areas()

func _timeout() -> void:
	if poisoned:
		particles.restart()
		take_damage.emit()
