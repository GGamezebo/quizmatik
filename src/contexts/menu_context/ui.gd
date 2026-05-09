extends CanvasLayer

@export_category('Major components')
@export var main_events: MainEvents
@export_group('Buttons')
@export var start_button: Button
@export var exit_button: Button


func _ready() -> void:
	start_button.grab_focus()
	
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
func _on_start_pressed() -> void:
	main_events.ev_start_game.emit()

func _on_exit_pressed() -> void:
	get_tree().quit()
