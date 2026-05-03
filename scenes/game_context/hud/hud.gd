extends CanvasLayer

@export var eventManager:EventManager

func _on_exit_button_down() -> void:
	eventManager.ev_exit_game.emit()
