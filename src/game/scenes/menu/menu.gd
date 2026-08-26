extends IScene

@export_category('Major components')
@export var root_events: RootEvents
@export var menu_events: MenuEvents
@export var windows_stack_manager: WindowStackManager
@export var levels_choice_window: Control
@export_group('Configs')
@export var training_room_config: GameConfig
@export var training_lab_config: GameConfig
@export_group('Buttons')
@export var start_button: Button
@export var training_room_start_button: BaseButton
@export var training_lab_start_button: Button
@export var exit_button: BaseButton


func _ready() -> void:
	start_button.grab_focus()
	if training_room_start_button != null:
		training_room_start_button.pressed.connect(_on_training_room_start_pressed)
	if training_lab_start_button != null:
		training_lab_start_button.pressed.connect(_on_training_lab_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	menu_events.ev_close_settings_window.connect(_on_close_settings_window)


func initialize(data: Dictionary = {}) -> void:
	var container_id: String = str(data.get("open_level_select", ""))
	if not container_id.is_empty():
		call_deferred("_open_level_select", container_id)


func _open_level_select(container_id: String) -> void:
	levels_choice_window.open_level_select(container_id)


func _on_training_room_start_pressed() -> void:
	root_events.ev_start_game.emit({'custom_battle': training_room_config})


func _on_training_lab_start_pressed() -> void:
	root_events.ev_start_game.emit({'custom_battle': training_lab_config})


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_close_settings_window() -> void:
	windows_stack_manager.close_stacked_window()
