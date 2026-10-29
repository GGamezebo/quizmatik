class_name DailySlot
extends Control

## Display-only daily stamp mark (empty outline / ink stamp when filled).

## A `play_stamp` slam hit the paper (sound / vibration / card shake hook).
signal ev_stamp_landed

@export var mark: TextureRect
@export var stamp_empty: Texture2D
@export var stamp_filled: Texture2D
@export var glow_color: Color = Color(1.7, 1.5, 1.05)

## How long `lift_stamp` runs after its delay. The card waits this long before the congrats.
const LIFT_SEC := 0.34

var _filled: Variant = null
var _tween: Tween


func _begin_tween() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mark != null:
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit_mark)
	_fit_mark()


## Idempotent: re-refreshing (e.g. language switch) never cuts a running `play_stamp`.
func set_filled(filled: bool) -> void:
	if mark == null or filled == _filled:
		return
	_filled = filled
	mark.texture = stamp_filled if filled else stamp_empty
	mark.modulate = Color.WHITE


## Stamp falls onto the paper after `delay` (the slot must already show the filled stamp):
## big and tilted → shrinks fast → `ev_stamp_landed` → squash bounce.
func play_stamp(delay: float) -> void:
	if mark == null:
		return
	mark.modulate.a = 0.0
	var tween := _begin_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		mark.pivot_offset = mark.size * 0.5
		mark.scale = Vector2.ONE * 2.4
		mark.rotation = -0.4)
	tween.tween_property(mark, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(mark, "scale", Vector2.ONE * 0.88, 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(mark, "rotation", 0.06, 0.2)
	tween.tween_callback(ev_stamp_landed.emit)
	tween.tween_property(mark, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mark, "rotation", 0.0, 0.22)


## Series done: the stamp lights up, then melts away (its place goes to the golden flight).
func glow_out(delay: float) -> void:
	if mark == null:
		return
	var tween := _begin_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: mark.pivot_offset = mark.size * 0.5)
	tween.tween_property(mark, "modulate", glow_color, 0.25)
	tween.parallel().tween_property(mark, "scale", Vector2.ONE * 1.18, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mark, "modulate", Color(glow_color, 0.0), 0.3)
	tween.parallel().tween_property(mark, "scale", Vector2.ONE * 0.4, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


## Reverse of `play_stamp`: a small squash, then the stamp lifts off, grows and fades.
## `ev_stamp_landed` fires as it leaves the paper.
func lift_stamp(delay: float) -> void:
	if mark == null:
		return
	mark.modulate = Color.WHITE
	mark.scale = Vector2.ONE
	mark.rotation = 0.0
	var tween := _begin_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: mark.pivot_offset = mark.size * 0.5)
	tween.tween_property(mark, "scale", Vector2.ONE * 0.86, 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mark, "rotation", 0.08, 0.1)
	tween.tween_callback(ev_stamp_landed.emit)
	tween.tween_property(mark, "scale", Vector2.ONE * 2.2, 0.24)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(mark, "rotation", -0.45, 0.24)
	tween.parallel().tween_property(mark, "modulate:a", 0.0, 0.24)


## Empty outline fades up into the resting mark (after the filled stamp has lifted off).
func reveal_empty(delay: float) -> void:
	if mark == null:
		return
	_filled = false
	mark.texture = stamp_empty
	mark.rotation = 0.0
	var tween := _begin_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		mark.pivot_offset = mark.size * 0.5
		mark.scale = Vector2.ONE * 0.72
		mark.modulate = Color(1, 1, 1, 0)
	)
	tween.tween_property(mark, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(mark, "scale", Vector2.ONE, 0.28)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Instantly shown (alpha 1) or hidden (golden flight waiting).
func set_shown(shown: bool) -> void:
	if mark == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	mark.scale = Vector2.ONE
	mark.rotation = 0.0
	mark.pivot_offset = mark.size * 0.5
	mark.modulate = Color(1, 1, 1, 1.0 if shown else 0.0)


func _fit_mark() -> void:
	if mark == null:
		return
	var side := minf(size.x, size.y)
	if side <= 1.0:
		side = custom_minimum_size.x
	var inner := clampf(side * 0.92, 64.0, 96.0)
	mark.custom_minimum_size = Vector2(inner, inner)
	mark.size = Vector2(inner, inner)
