class_name HallLamps
extends Control

## Garlands over the hall of fame: bulbs stay grey until everything is unlocked
## (`ProgressController.is_hall_complete`), then light up one by one and twinkle.

@export var bulbs: Array[HallBulb] = []
@export var first_delay: float = 0.35
@export var step_delay: float = 0.12


func set_lit(lit: bool) -> void:
	for index in bulbs.size():
		bulbs[index].set_lit(lit, first_delay + step_delay * index)
