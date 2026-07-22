extends CanvasLayer

@export var root_events: RootEvents
@export var player: Player

var _game_confg: GameConfig

func initialize(game_config: GameConfig):
	self._game_confg = game_config

func _on_exit_button_down() -> void:
	root_events.ev_exit_game.emit(
		PostBattleScene.build_result_data(_game_confg, player, false)
	)
