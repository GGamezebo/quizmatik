extends CanvasLayer

@export var main_events: MainEvents
@export var game_confg: GameConfig

func _on_exit_button_down() -> void:
	main_events.ev_exit_game.emit({'game_config': game_confg})
