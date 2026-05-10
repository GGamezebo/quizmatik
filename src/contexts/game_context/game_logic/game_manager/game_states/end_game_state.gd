class_name EndGameState
extends StateBase

static func get_state() -> String:
	return FSMGameStates.END_GAME
	
@export var main_events: MainEvents
	
func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	main_events.ev_exit_game.emit()
