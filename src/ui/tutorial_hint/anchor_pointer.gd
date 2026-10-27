class_name AnchorPointer
extends Node

## Drives one `TutorialHint` (+ optional `SpotlightDim`) to the first step (in order) whose anchor
## is visible right now. Order = priority: deeper screens first so the hint follows navigation.

signal ev_step_changed(step: AnchorPointerStep)
## Hint confirm button pressed for `step` (steps with `button_text`).
signal ev_step_confirmed(step: AnchorPointerStep)
## The pointed control (a `BaseButton`) was pressed while `step` was shown.
signal ev_target_pressed(step: AnchorPointerStep)

@export var registry: UiAnchorRegistry
@export var hint: TutorialHint
## Optional: dims everything except the current anchor (steps with `dim`).
@export var dim: SpotlightDim
@export var steps: Array[AnchorPointerStep] = []

var _enabled: bool = false
var _current: AnchorPointerStep
var _current_control: Control
var _pressed_source: BaseButton


func _ready() -> void:
	set_process(_enabled)
	hint.ev_button_pressed.connect(_on_hint_button)


func set_enabled(value: bool) -> void:
	_enabled = value
	set_process(value)
	if not value:
		_show(null, null)


func set_steps(new_steps: Array[AnchorPointerStep]) -> void:
	steps = new_steps
	_show(null, null)


func current_step() -> AnchorPointerStep:
	return _current


func _process(_delta: float) -> void:
	for step in steps:
		var control := registry.get_visible(step.anchor_id)
		if control == null and not step.fallback_anchor_id.is_empty():
			control = registry.get_visible(step.fallback_anchor_id)
		if control != null:
			_show(step, control)
			return
	_show(null, null)


func _show(step: AnchorPointerStep, control: Control) -> void:
	if step == _current and control == _current_control:
		return
	_current = step
	_current_control = control
	_watch_press(control as BaseButton)
	hint.set_active(false)
	if step == null:
		if dim != null:
			dim.set_active(false)
		ev_step_changed.emit(null)
		return
	hint.point_at(control, step.anchor_point, step.points_up, step.text, step.button_text)
	hint.set_active(true)
	if dim != null:
		if step.dim:
			dim.follow(control, step.hole_rect, step.hole_margin)
		dim.set_active(step.dim)
	ev_step_changed.emit(step)


func _watch_press(button: BaseButton) -> void:
	if is_instance_valid(_pressed_source) and _pressed_source.pressed.is_connected(_on_target_pressed):
		_pressed_source.pressed.disconnect(_on_target_pressed)
	_pressed_source = button
	if button != null:
		button.pressed.connect(_on_target_pressed)


func _on_target_pressed() -> void:
	if _current != null:
		ev_target_pressed.emit(_current)


func _on_hint_button() -> void:
	if _current != null:
		ev_step_confirmed.emit(_current)
