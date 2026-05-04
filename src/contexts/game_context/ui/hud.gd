extends CanvasLayer

@export var rootEvents:RootEvents

func _on_exit_button_down() -> void:
	rootEvents.ev_exit_game.emit()
