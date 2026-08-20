extends HBoxContainer
class_name TrainingStepper

signal value_changed(value: float)

@export var step: float = 1.0
@export var min_value: float = 0.0
@export var max_value: float = 9999.0
@export var decimals: int = 0

@export var minus_button: Button
@export var value_label: Label
@export var plus_button: Button

var _value: float = 0.0


func _ready() -> void:
	if minus_button != null:
		minus_button.pressed.connect(_on_minus)
	if plus_button != null:
		plus_button.pressed.connect(_on_plus)
	_update_display()


func set_value(value: float) -> void:
	_value = clampf(value, min_value, max_value)
	_update_display()


func get_value() -> float:
	return _value


func _on_minus() -> void:
	set_value(_value - step)
	value_changed.emit(_value)


func _on_plus() -> void:
	set_value(_value + step)
	value_changed.emit(_value)


func _update_display() -> void:
	if value_label == null:
		return
	if decimals > 0:
		value_label.text = ("%0." + str(decimals) + "f") % _value
	else:
		value_label.text = str(int(round(_value)))
