class_name ExamSlot
extends Control

## Plain wrapper for the exam tile in the level grid: the tile keeps its own hover scale,
## the wrapper pulses (HARD: «take the exam», `UiPulse` never on a hover-scaled button).

@export var pulse: UiPulse


func hold(tile: Control) -> void:
	add_child(tile)


func set_pulsing(on: bool) -> void:
	if pulse != null:
		pulse.set_active(on and is_inside_tree())
