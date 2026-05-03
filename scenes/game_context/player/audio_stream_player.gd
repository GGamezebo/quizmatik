extends AudioStreamPlayer

func setup(parent:Node) -> void:
	_updateSound(parent.directionY)

func update(_delta:float) -> void:
	pass

func setDirection(directionY:float) -> void:
	_updateSound(directionY)

func _updateSound(directionY:float) -> void:
	if directionY != 0:
		play()
	else:
		stop()
