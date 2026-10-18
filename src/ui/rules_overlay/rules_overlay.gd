class_name RulesOverlay
extends CanvasLayer

## Battle-mode rules card (overlay, not a stacked window); content = the scene (magister trial, endless record).
## `open(true)` adds the start button (first press on the menu entry) → `ev_start_pressed`.
## Closes on back button, tap on the dim, `ui_cancel` → `ev_closed`.

signal ev_start_pressed
signal ev_closed

@export var screen: Control
@export var dim: Control
@export var close_button: BaseButton
@export var start_button: BaseButton

const FADE_DURATION: float = 0.22


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	start_button.pressed.connect(_on_start_pressed)
	dim.gui_input.connect(_on_dim_gui_input)


func open(with_start: bool) -> void:
	start_button.visible = with_start
	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	(start_button if with_start else close_button).grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	hide()
	ev_closed.emit()


func _on_start_pressed() -> void:
	hide()
	ev_start_pressed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
		close()
