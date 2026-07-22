class_name GameManager
extends Node

@export var game_events: GameEvents
@export var states: Array[StateBase]

var fsm: FSM
var time: float = 0.0

func initialize(game_config: GameConfig) -> void:
	for state in states:
		state.initialize(self, game_config)
	
	fsm = FSM.new({
		"initial": {"state": CountDownState.get_state()},
		"transitions": [
			{"src": CountDownState.get_state(), "dst": GameState.get_state(), "event": FSMGameEvents.START_GAME},
			{"src": GameState.get_state(), "dst": EndGameState.get_state(), "event": FSMGameEvents.END_GAME},
			{"src": EndGameState.get_state(), "dst": CountDownState.get_state(), "event": FSMGameEvents.RESTART},
		],
		"states": states,
	})
	fsm.ev_state_changed.connect(_on_state_changed)

func _exit_tree() -> void:
	fsm.deinit()
	
func get_current_state_name() -> String:
	return fsm.get_current_state_name()
	
func _process(delta: float) -> void:
	time += delta
	
func _on_state_changed(from_state_name: String, to_state_name: String) -> void:
	game_events.ev_game_state_changed.emit(from_state_name, to_state_name)
