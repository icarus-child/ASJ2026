class_name PlayerAnimTree
extends AnimationTree

@onready var state: AnimationNodeStateMachinePlayback = self ["parameters/playback"]

func attack() -> void:
	state.travel("attack")

func parry() -> void:
	state.travel("parry")