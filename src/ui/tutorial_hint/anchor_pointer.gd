class_name AnchorPointer
extends Node

## Drives one `TutorialHint` to the first step (in order) whose anchor is visible right now.
## Order = priority: put deeper screens first so the hint follows navigation automatically.

@export var registry: UiAnchorRegistry
@export var hint: TutorialHint
@export var steps: Array[AnchorPointerStep] = []

var _enabled: bool = false
var _current: AnchorPointerStep


func set_enabled(value: bool) -> void:
	_enabled = value
	set_process(value)
	if not value:
		_show(null, null)


func _ready() -> void:
	set_process(_enabled)


func _process(_delta: float) -> void:
	for step in steps:
		var control := registry.get_visible(step.anchor_id)
		if control != null:
			_show(step, control)
			return
	_show(null, null)


func _show(step: AnchorPointerStep, control: Control) -> void:
	if step == _current and (step == null or hint.target == control):
		return
	_current = step
	if step == null:
		hint.set_active(false)
		return
	hint.set_active(false)
	hint.point_at(control, step.anchor_point, step.points_up, step.text)
	hint.set_active(true)
