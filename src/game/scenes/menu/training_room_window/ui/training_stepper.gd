extends HBoxContainer
class_name TrainingStepper

## − value + stepper; holding −/+ repeats the step.

signal value_changed(value: float)

@export var step: float = 1.0
@export var min_value: float = 0.0
@export var max_value: float = 9999.0
@export var decimals: int = 0

@export var minus_button: Button
@export var value_label: Label
@export var plus_button: Button
## Drives hold-to-repeat: first tick after `repeat_delay`, then every `repeat_interval`.
@export var repeat_timer: Timer
@export var repeat_delay: float = 0.4
@export var repeat_interval: float = 0.07

var _value: float = 0.0
var _held_dir: float = 0.0


func _ready() -> void:
	if minus_button != null:
		minus_button.button_down.connect(_on_hold_start.bind(-1.0))
		minus_button.button_up.connect(_on_hold_end)
	if plus_button != null:
		plus_button.button_down.connect(_on_hold_start.bind(1.0))
		plus_button.button_up.connect(_on_hold_end)
	if repeat_timer != null:
		repeat_timer.timeout.connect(_on_repeat)
	visibility_changed.connect(_on_hold_end)
	_update_display()


func set_value(value: float) -> void:
	_value = clampf(value, min_value, max_value)
	_update_display()


func get_value() -> float:
	return _value


func _on_hold_start(dir: float) -> void:
	_held_dir = dir
	_step_by(dir)
	if repeat_timer != null:
		repeat_timer.start(repeat_delay)


func _on_hold_end() -> void:
	_held_dir = 0.0
	if repeat_timer != null:
		repeat_timer.stop()


func _on_repeat() -> void:
	if _held_dir == 0.0 or not _step_by(_held_dir):
		_on_hold_end()
		return
	repeat_timer.start(repeat_interval)


func _step_by(dir: float) -> bool:
	var before := _value
	set_value(_value + step * dir)
	if is_equal_approx(before, _value):
		return false
	value_changed.emit(_value)
	return true


func _update_display() -> void:
	if value_label == null:
		return
	if decimals > 0:
		value_label.text = ("%0." + str(decimals) + "f") % _value
	else:
		value_label.text = str(int(round(_value)))
