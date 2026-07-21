extends IScene

@export_category('Major components')
@export var root_events: RootEvents
@export var menu_events: MenuEvents
@export var windows_stack_manager: WindowStackManager
@export_group('Configs')
@export var training_room_config: GameConfig
@export_group('Buttons')
@export var start_button: Button
@export var training_room_start_button: Button
@export var exit_button: Button


func _ready() -> void:
	start_button.grab_focus()
	
	training_room_start_button.pressed.connect(_on_training_room_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	menu_events.ev_close_settings_window.connect(_on_close_settings_window)

func _on_training_room_start_pressed() -> void:
	root_events.ev_start_game.emit({'custom_battle': training_room_config})

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_close_settings_window() -> void:
	windows_stack_manager.close_stacked_window()
	
