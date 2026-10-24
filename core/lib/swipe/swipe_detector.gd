class_name SwipeDetector
extends Node

## Horizontal swipe / mouse wheel over `area` (mouse drag, or touch via emulated mouse).
## Never consumes input: buttons under the finger still get their events, so the host ignores the tap
## that follows a swipe while `is_swiping()` is true (set on release, cleared by the end of that frame).

## `direction` +1 = content moves left (next page), -1 = right (previous page).
signal ev_swiped(direction: int)
## Left button / finger went down inside `area` (before any child gets it).
signal ev_pressed

@export var area: Control
@export var min_distance: float = 64.0
## Swipe must be mostly horizontal: |dx| >= |dy| * ratio.
@export var horizontal_ratio: float = 1.5
## Wheel over `area` also emits `ev_swiped` (down = next).
@export var use_wheel: bool = true

var _origin: Vector2 = Vector2.ZERO
var _tracking: bool = false
var _swiping: bool = false


func is_swiping() -> bool:
	return _swiping


func _input(event: InputEvent) -> void:
	if area == null or not area.is_visible_in_tree():
		_tracking = false
		return
	if event is InputEventMouseButton:
		_on_button(event as InputEventMouseButton)


func _on_button(button: InputEventMouseButton) -> void:
	if not button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_finish(button.position)
		return
	if not button.pressed or not _inside(button):
		return
	match button.button_index:
		MOUSE_BUTTON_LEFT:
			_swiping = false
			_tracking = true
			_origin = button.position
			ev_pressed.emit()
		MOUSE_BUTTON_WHEEL_DOWN:
			if use_wheel:
				ev_swiped.emit(1)
		MOUSE_BUTTON_WHEEL_UP:
			if use_wheel:
				ev_swiped.emit(-1)


func _finish(release: Vector2) -> void:
	if not _tracking:
		return
	_tracking = false
	var delta := release - _origin
	if absf(delta.x) < min_distance or absf(delta.x) < absf(delta.y) * horizontal_ratio:
		return
	_swiping = true
	ev_swiped.emit(-int(signf(delta.x)))
	# Stays true until this release has reached the controls under the finger, then clears.
	set_deferred("_swiping", false)


func _inside(event: InputEventMouse) -> bool:
	var local := area.make_input_local(event) as InputEventMouse
	return Rect2(Vector2.ZERO, area.size).has_point(local.position)
