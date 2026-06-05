extends Node2D

func _ready() -> void:
	($Area2D as Area2D).area_entered.connect(_on_area_enter)


func _on_area_enter(body: Area2D) -> void:
	var player := body.get_parent() as Player
	if PlayerResources.health == PlayerResources.max_health:
		return
	player.heal_damage(4)
	var audio_stream: AudioStreamPlayer = $AudioStreamPlayer as AudioStreamPlayer
	audio_stream.finished.connect(call_deferred.bind("queue_free"))
	audio_stream.play()
	remove_child(audio_stream)
	# audio_stream.position = position
	get_parent().add_child(audio_stream)

	queue_free()
