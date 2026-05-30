class_name EndGameState
extends StateBase

static func get_state() -> String:
	return FSMGameStates.END_GAME
	
@export var main_events: MainEvents
@export var game_config: GameConfig
@export var player: Player
@export var air_plane: AirPlane
@export var progress_controller: ProgressController
	
func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	if player.score == game_config.questions_count:
		air_plane.ev_win_animation_finished.connect(_on_animation_finished.bind(true))
		air_plane.win_animation()
	else:
		air_plane.ev_dead_animation_finished.connect(_on_animation_finished.bind(false))
		air_plane.die_animation()
	
func leave(_event_data: Dictionary) -> void:
	pass
	
func _on_animation_finished(is_win) -> void:
	var score: int = player.score
	var stars: int = _calculate_stars(player.score)
	_apply_battle_result(is_win, stars)
	var battle_result = {
		"game_config": game_config,
		"stars": stars,
		"score": score,
	}
	main_events.ev_exit_game.emit(battle_result)
	
func _apply_battle_result(is_win: bool, stars: int) -> void:
	var battle_info = game_config.battle_info
	if is_win and battle_info:
		progress_controller.post_battle(
			battle_info,
			stars
		)
		
func _calculate_stars(score: int) -> int:
	var percentage: float = float(score) / float(game_config.questions_count)
	if percentage >= 1.0:
		return 3
	elif percentage >= 0.75:
		return 2
	else:
		return 1
