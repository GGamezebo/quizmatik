extends IContext

@export_category('Major components')
@export var main_events: MainEvents
@export_group('Buttons')
@export var menu_button: Button
@export var repeat_button: Button

func _ready() -> void:
	repeat_button.grab_focus()
	
	menu_button.pressed.connect(_on_menu)

func _on_menu() -> void:
	main_events.ev_return_to_menu.emit()
