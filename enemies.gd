extends Node2D


func _ready() -> void:
	child_exiting_tree.connect(_on_child_exit_tree)


func _on_child_exit_tree(_node: Node) -> void:
	call_deferred("add_sibling", _create_timer(0.5, _do_thing))


func _do_thing() -> void:
	var child_count: int = 0
	for node: Node2D in get_children():
		if node is Enemy:
			child_count += 1
	print(child_count)
	if child_count == 0:
		print("level over")
		PlayerResources.level_done.emit()


func _create_timer(duration: float, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = duration
	timer.timeout.connect(callback)
	return timer
