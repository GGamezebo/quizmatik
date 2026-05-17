class_name EndGameState
extends StateBase

static func get_state() -> String:
	return FSMGameStates.END_GAME
	
@export var main_events: MainEvents
@export var game_config: GameConfig
@export var player: Player
@export var air_plane: AirPlane
	
func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	if player.score == game_config.questions_count:
		air_plane.ev_win_animation_finished.connect(_on_animation_finished)
		air_plane.win_animation()
	else:
		air_plane.ev_dead_animation_finished.connect(_on_animation_finished)
		air_plane.die_animation()
	
func leave(_event_data: Dictionary) -> void:
	pass
	
func _on_animation_finished() -> void:
	main_events.ev_exit_game.emit()
