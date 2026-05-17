class_name EndGameState
extends StateBase

static func get_state() -> String:
	return FSMGameStates.END_GAME
	
@export var main_events: MainEvents
@export var air_plane: AirPlane
	
func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	air_plane.ev_dead_animation_finished.connect(_on_dead_animation_finished)
	air_plane.die()
	
func leave(_event_data: Dictionary) -> void:
	pass
	
func _on_dead_animation_finished() -> void:
	main_events.ev_exit_game.emit()
