extends CanvasLayer

@export var root_events: RootEvents
@export var game_confg: GameConfig
@export var player: Player

func _on_exit_button_down() -> void:
	root_events.ev_exit_game.emit(
		PostBattleScene.build_result_data(game_confg, player, false)
	)
