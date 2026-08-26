class_name DailySlot
extends Control

## Display-only daily stamp mark (empty outline / ink stamp when filled).

@export var mark: TextureRect
@export var stamp_empty: Texture2D
@export var stamp_filled: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mark != null:
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit_mark)
	_fit_mark()


func set_filled(filled: bool) -> void:
	if mark == null:
		return
	mark.texture = stamp_filled if filled else stamp_empty
	mark.modulate = Color.WHITE


func _fit_mark() -> void:
	if mark == null:
		return
	var side := minf(size.x, size.y)
	if side <= 1.0:
		side = custom_minimum_size.x
	var inner := clampf(side * 0.92, 64.0, 96.0)
	mark.custom_minimum_size = Vector2(inner, inner)
	mark.size = Vector2(inner, inner)
