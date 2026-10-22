extends PanelContainer
class_name TrainingRangePicker

## «Выбери сам» range under an op column: min / max steppers, min ≤ max kept here.

signal range_changed(min_value: int, max_value: int)

@export var min_stepper: TrainingStepper
@export var max_stepper: TrainingStepper
@export var limit_min: int = 1
@export var limit_max: int = 100

var _min: int = 1
var _max: int = 15


func _ready() -> void:
	for stepper: TrainingStepper in [min_stepper, max_stepper]:
		if stepper == null:
			continue
		stepper.step = 1.0
		stepper.min_value = limit_min
		stepper.max_value = limit_max
		stepper.decimals = 0
	if min_stepper != null:
		min_stepper.value_changed.connect(_on_min_changed)
	if max_stepper != null:
		max_stepper.value_changed.connect(_on_max_changed)
	_refresh()


func set_range(min_value: int, max_value: int) -> void:
	_min = clampi(min_value, limit_min, limit_max)
	_max = clampi(maxi(max_value, _min), limit_min, limit_max)
	_refresh()


func get_range() -> Vector2i:
	return Vector2i(_min, _max)


func _on_min_changed(value: float) -> void:
	_min = int(value)
	_max = maxi(_max, _min)
	_refresh()
	range_changed.emit(_min, _max)


func _on_max_changed(value: float) -> void:
	_max = int(value)
	_min = mini(_min, _max)
	_refresh()
	range_changed.emit(_min, _max)


func _refresh() -> void:
	if min_stepper != null:
		min_stepper.set_value(_min)
	if max_stepper != null:
		max_stepper.set_value(_max)
