extends Node2D

class_name GameManager

signal ev_selected_lane_changed

var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()


@export var player: Node2D
@export var area: GameArea

	
func _process(_delta: float) -> void:
	self.selected_lane = area.getLine(player.position)
