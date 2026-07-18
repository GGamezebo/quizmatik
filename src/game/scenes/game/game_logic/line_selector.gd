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

func _ready() -> void:
	area.boundary_changed.connect(_on_boundary_changed)
	_update_plane_discret_positions()

func _process(_delta: float) -> void:
	if air_plane.movement_mode == AirPlane.MovementMode.DIRECT:
		selected_lane = area.getLine(air_plane.position)
	elif air_plane.movement_mode == AirPlane.MovementMode.DISCRETE:
		selected_lane = air_plane.get_discret_lane()
	
func _on_boundary_changed() -> void:
	selected_lane = area.getLine(air_plane.position)
	
func _update_plane_discret_positions() -> void:
	var lines: Array[Rect2] = area.getLines()
	var positions: Array[float] = []
	for line in lines:
		positions.append(line.get_center().y)
	air_plane.set_discret_positions(positions)
