extends AnimatedSprite2D

@export var ROTATION:float = deg_to_rad(2)
@onready var _position_shaker: PositionShaker = PositionShaker.new()
@onready var _scale_shaker: ScaleShacker = ScaleShacker.new()
@onready var _rotationShacker: RotationShaker = RotationShaker.new()
@onready var _base_scale: Vector2 = scale
@onready var _base_rotation: float = rotation


func setup(parent:Node) -> void:
	_updateAnimation(parent.directionY)
	_updateRotation(parent.directionY)

func setDirection(directionY:float) -> void:
	_updateAnimation(directionY)
	_updateRotation(directionY)

func update(delta: float) -> void:
	_position_shaker.update(delta)
	_scale_shaker.update(delta)
	_rotationShacker.update(delta)
	
	offset = _position_shaker.get_pos_offset()
	scale = _base_scale + _scale_shaker.get_scale_offset()
	rotation = _base_rotation + _rotationShacker.get_rotation_offset()

func _updateAnimation(directionY:float) -> void:
	var animationName = 'default'
	if directionY < 0.0:
		animationName = 'up'
	elif directionY > 0.0:
		animationName = 'down'
	play(animationName)
	
	
func _updateRotation(directionY:float) -> void:
	_base_rotation = 0.0
	if directionY > 0:
		_base_rotation += ROTATION
	elif directionY < 0:
		_base_rotation -= ROTATION
		
