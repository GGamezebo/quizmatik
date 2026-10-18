class_name UiPulse
extends Node

## Gently scales `target` around its center in a loop while active (e.g. "press me" icons).
## Pulse an inner child (icon) or a plain wrapper around a button — never a hover-scaled button itself
## (its hover tween owns `scale`). The pivot follows `target` resizes (container layout).

@export var target: Control
@export var pulse_scale: float = 1.1
@export var period: float = 1.4

var _tween: Tween


func set_active(on: bool) -> void:
	if target == null or is_active() == on:
		return
	if not on:
		_tween.kill()
		_tween = null
		target.scale = Vector2.ONE
		return
	_center_pivot()
	if not target.resized.is_connected(_center_pivot):
		target.resized.connect(_center_pivot)
	var half := period * 0.5
	_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(target, "scale", Vector2.ONE * pulse_scale, half)
	_tween.tween_property(target, "scale", Vector2.ONE, half)


func is_active() -> bool:
	return _tween != null and _tween.is_valid()


func _center_pivot() -> void:
	target.pivot_offset = target.size * 0.5
