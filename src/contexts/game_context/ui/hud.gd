extends CanvasLayer

@export var main_events: MainEvents

func _on_exit_button_down() -> void:
	main_events.ev_exit_game.emit()
