class_name WindowStackManager
extends Node

@export_category('stacked_windows_settings')
@export var default_window: Control
@export var button_transitions: Array[ButtonWindowTransition]

var window_stack: Array[Control] = []

func _ready() -> void:
	for transition in button_transitions:
		transition.target_window.hide()
		transition.button.pressed.connect(_on_button_pressed.bind(transition.target_window))
	
	open_stacked_window(default_window)

func open_stacked_window(new_window: Control) -> void:
	if not window_stack.is_empty():
		window_stack.back().hide() # Скрываем текущее верхнее окно
	
	window_stack.append(new_window)
	new_window.show()
	
	# Опционально: фокусируемся на первой кнопке для геймпадов
	var first_button = new_window.find_next_valid_focus()
	if first_button:
		first_button.grab_focus()

# come back
func close_stacked_window() -> void:
	if window_stack.size() <= 1:
		return # Не закрываем последнее окно (главное меню)

	var current_window = window_stack.pop_back()
	current_window.hide()
	
	var previous_window = window_stack.back()
	previous_window.show()
	
	# Возвращаем фокус
	var first_button = previous_window.find_next_valid_focus()
	if first_button:
		first_button.grab_focus()

# Обработка клавиши "Назад" (Esc)
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_stacked_window()
		
func _on_button_pressed(target_window: Control) -> void:
	open_stacked_window(target_window)
