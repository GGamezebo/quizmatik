class_name LineSelector
extends Node

signal ev_selected_lane_changed

@export var air_plane: AirPlane
@export var area: GameArea

var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()

func _process(_delta: float) -> void:
	selected_lane = area.getLine(air_plane.position)
