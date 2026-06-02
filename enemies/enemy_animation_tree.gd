class_name EnemyAnimTree
extends AnimationTree

@onready var state: AnimationNodeStateMachinePlayback = self ["parameters/playback"]

func attack() -> void:
	state.travel("attack")

func hurt() -> void:
	state.travel("hurt")
