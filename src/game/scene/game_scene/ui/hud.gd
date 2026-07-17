extends CanvasLayer

@export var main_events: MainEvents
@export var game_confg: GameConfig
@export var player: Player

func _on_exit_button_down() -> void:
	main_events.ev_exit_game.emit(
		PostBattleScene.build_result_data(game_confg, player, false)
	)
