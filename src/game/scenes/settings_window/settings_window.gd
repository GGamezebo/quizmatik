extends IScene

@export var menu_events: MenuEvents
@export var root_events: RootEvents

func _on_button_exit_pressed() -> void:
	menu_events.ev_close_settings_window.emit()

func _on_reset_account_progress_pressed() -> void:
	root_events.ev_reset_account_progress.emit()
