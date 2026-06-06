class_name WindowStackManager
extends Node

@export_category('stacked_windows_settings')
@export var default_window: Control

var window_stack: Array[Control] = []

func _ready() -> void:
	for node in get_children():
		var transition = node as ButtonWindowTransition
		if transition:
			transition.target_window.hide()
			transition.button.pressed.connect(_on_button_pressed.bind(transition.target_window))
		
	open_stacked_window(default_window)

func open_stacked_window(new_window: Control) -> void:
	# 1. If the window is already in the stack, collapse down to it
	if window_stack.has(new_window):
		while window_stack.back() != new_window:
			var top_window = window_stack.pop_back()
			top_window.hide()
		
		# Show the target window (now on top of the stack)
		new_window.show()
	else:
		# 2. Otherwise hide the current window and push the new one
		if not window_stack.is_empty() and not window_stack.back().is_ancestor_of(new_window):
			window_stack.back().hide()
		
		window_stack.append(new_window)
		new_window.show()

	# 3. Focus management
	var first_button = new_window.find_next_valid_focus()
	if first_button:
		first_button.grab_focus()

# come back
func close_stacked_window() -> void:
	if window_stack.size() <= 1:
		return # Keep the root window (main menu) open

	var current_window = window_stack.pop_back()
	current_window.hide()
	
	var previous_window = window_stack.back()
	previous_window.show()
	
	# Restore focus
	var first_button = previous_window.find_next_valid_focus()
	if first_button:
		first_button.grab_focus()

# Handle Back / Esc
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_stacked_window()
		
func _on_button_pressed(target_window: Control) -> void:
	open_stacked_window(target_window)
