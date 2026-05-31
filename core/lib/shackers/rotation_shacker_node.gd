extends Node

@export var target_object: Node
@export var rotation_speed: float = 8.0
@export var rotation_strength: float = 3.0  # degrees
@export var frequency: float = 0.05

var _shacker: RotationShaker

@onready var _base_rotation: float = target_object.rotation

func _ready() -> void:
	_shacker = RotationShaker.new(rotation_speed, rotation_strength, frequency)
	
func _process(delta: float) -> void:
	_shacker.update(delta)
	target_object.rotation = _base_rotation + _shacker.get_rotation_offset()
