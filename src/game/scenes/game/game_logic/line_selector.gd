class_name LineSelector
extends Node

signal ev_selected_lane_changed

@export var air_plane: AirPlane
@export var area: GameArea
@export var game_events: GameEvents
## Plane counts as lined up when within this share of lane height from the lane center.
@export_range(0.05, 0.5) var centered_band: float = 0.22

var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()
var _centered: bool = false
var _reported_lane: int = -1

func initialize(_game_config: GameConfig) -> void:
	area.boundary_changed.connect(_on_boundary_changed)
	_update_plane_discret_positions()

func _process(_delta: float) -> void:
	if air_plane.movement_mode == AirPlane.MovementMode.DIRECT:
		selected_lane = area.getLine(air_plane.position)
	elif air_plane.movement_mode == AirPlane.MovementMode.DISCRETE:
		selected_lane = air_plane.get_discret_lane()
	_report_lane()


func _report_lane() -> void:
	if game_events == null:
		return
	var lines: Array[Rect2] = area.getLines()
	if selected_lane < 0 or selected_lane >= lines.size():
		return
	var lane: Rect2 = lines[selected_lane]
	var centered := absf(air_plane.global_position.y - lane.get_center().y) <= lane.size.y * centered_band
	if selected_lane != _reported_lane or centered != _centered:
		_reported_lane = selected_lane
		_centered = centered
		game_events.ev_plane_lane_changed.emit(selected_lane, centered)
	
func _on_boundary_changed() -> void:
	_update_plane_discret_positions()
	selected_lane = area.getLine(air_plane.position)
	
func _update_plane_discret_positions() -> void:
	var lines: Array[Rect2] = area.getLines()
	var positions: Array[float] = []
	for line in lines:
		positions.append(line.get_center().y)
	air_plane.set_discret_positions(positions)
