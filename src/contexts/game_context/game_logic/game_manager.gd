class_name GameManager
extends Node

@export var states: Array[StateBase]

var fsm:FSM
var time:float = 0.0

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
