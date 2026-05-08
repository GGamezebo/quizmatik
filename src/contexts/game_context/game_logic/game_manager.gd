class_name GameManager
extends Node

signal ev_selected_lane_changed

@export var states: Array[StateBase]
@export var player: Player
@export var area: GameArea

var fsm:FSM
var time:float = 0.0
var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()


func _ready() -> void:
	for state in states:
		state.initialize(self)
	
	fsm = FSM.new({
		"initial": {"state": CountDownState.get_state()},
		"transitions": [
			{"src": CountDownState.get_state(), "dst": GameState.get_state(), "event": "ev_start_game"},
			{"src": GameState.get_state(), "dst": EndGameState.get_state(), "event": "ev_end_game"},
			{"src": EndGameState.get_state(), "dst": CountDownState.get_state(), "event": "ev_restart"},
		],
		"states": states,
	})

func _exit_tree() -> void:
	fsm.deinit()
	
func _process(delta: float) -> void:
	time += delta
	selected_lane = area.getLine(player.position)
