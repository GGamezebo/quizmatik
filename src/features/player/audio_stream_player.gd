extends AudioStreamPlayer

func initialize(parent: Node) -> void:
	_updateSound(parent.direction_y)

func update(_delta: float) -> void:
	pass

func setDirection(direction_y: float) -> void:
	_updateSound(direction_y)

func _updateSound(direction_y: float) -> void:
	if direction_y != 0:
		play()
	else:
		stop()
