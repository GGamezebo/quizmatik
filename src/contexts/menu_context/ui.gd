extends Control

@export var eventManager:EventManager
@export var start_button:Button
@export var exit_button:Button

func _ready():
	start_button.grab_focus()

	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	eventManager.ev_start_game.emit()

func _on_exit_pressed():
	get_tree().quit()
