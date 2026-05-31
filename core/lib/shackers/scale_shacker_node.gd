extends Node

@export var target_object: Node
@export var pulse_speed: float = 5.0
@export var pulse_strength: float = 0.05
@export var frequency: float = 0.05

var _shacker: ScaleShacker
var _base_scale: Vector2

func _ready() -> void:
	_base_scale = target_object.scale
	_shacker = ScaleShacker.new(pulse_speed, pulse_strength, frequency)
	
func _process(delta: float) -> void:
	_shacker.update(delta)
	var scale: Vector2 = _base_scale + _shacker.get_scale_offset()
	target_object.scale = scale
