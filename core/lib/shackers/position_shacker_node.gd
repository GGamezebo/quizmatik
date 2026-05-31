extends Node

@export var target_object: Node
@export var shake_speed: float = 10.0
@export var shake_strength: float = 2.0
@export var frequency: float = 0.05

var _shacker: PositionShaker

func _ready() -> void:
	_shacker = PositionShaker.new(shake_speed, shake_strength, frequency)
	
func _process(delta: float) -> void:
	_shacker.update(delta)
	target_object.offset = _shacker.get_pos_offset()
