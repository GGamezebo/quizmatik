class_name PlaneFlyerTrail
extends Node2D

## Line behind a plane (showcase flyer + battle). Points live in global space (`top_level`) and
## drift left so a plane standing still still reads as flying right. Look = `TrailItem`.

@export var color: Color = Color(0.165, 0.2, 0.251, 0.75)
@export var drift_speed: float = 260.0
@export var dot_spacing: float = 22.0
@export var dot_radius: float = 4.0
@export var max_length: float = 520.0
@export var style: TrailItem.Style = TrailItem.Style.DOTS
## Per-dot color cycle (colored pencils). Empty → `color`.
@export var palette: PackedColorArray = PackedColorArray()
## `SIGNS` style: glyphs cycled per dot (`TrailGlyph`).
@export var signs: String = ""
## `SIGNS` style: texture symbols instead of `signs` (`TrailItem.sign_textures`).
@export var sign_textures: Array[Texture2D] = []
## Optional emitter followed every frame (keeps drawing while the owner stops processing,
## e.g. the battle plane's victory fly-off). Null → owner calls `push_point`.
@export var source: Node2D

const MAX_FILL_DOTS: int = 24
## Soft edge of a dash, in px.
const DASH_FEATHER: float = 1.0
## 4 rows across the dash (feather, body, feather) at both ends.
const DASH_INDICES: PackedInt32Array = [0, 4, 1, 1, 4, 5, 1, 5, 2, 2, 5, 6, 2, 6, 3, 3, 6, 7]
## Redrawn every frame: dots = one texture (batched by the renderer, no GPU buffers). `draw_circle` /
## `draw_line(antialiased)` / `draw_colored_polygon` = a GPU buffer each → 20 FPS on WebGL.
const DOT_TEXTURE: Texture2D = preload("trail_dot.svg")

var _points: PackedVector2Array = []
## Running dot number → stable colors / crayon jitter while points drift.
var _first_index: int = 0
## Dashes and glyphs of one frame: a single triangle array.
var _batch := TrailGlyph.Batch.new()


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func apply_style(item: TrailItem) -> void:
	if item == null:
		return
	style = item.style
	color = item.color
	palette = item.palette
	signs = item.signs
	sign_textures = item.sign_textures
	dot_radius = item.width
	dot_spacing = item.spacing
	visible = style != TrailItem.Style.NONE
	clear()


## Fast moves (victory fly-off) fill the gap with evenly spaced dots instead of leaving holes.
func push_point(global_point: Vector2) -> void:
	if style == TrailItem.Style.NONE:
		return
	if _points.is_empty():
		_points.append(global_point)
		return
	var last := _points[_points.size() - 1]
	var steps := mini(int(last.distance_to(global_point) / dot_spacing), MAX_FILL_DOTS)
	for i in range(1, steps + 1):
		_points.append(last.lerp(global_point, float(i) / float(steps)))


func clear() -> void:
	_points.clear()
	queue_redraw()


## Owner is gone (crash): no more points, the line fades out and is removed.
func stop(fade_sec: float = 0.35) -> void:
	source = null
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_sec)
	tween.tween_callback(func() -> void:
		clear()
		modulate.a = 1.0
	)


func _process(delta: float) -> void:
	if _has_source():
		# Sampled in `_draw`: tweens move the owner after `_process`, sampling here lags a frame
		# and leaves a gap behind a fast plane.
		queue_redraw()
	if _points.is_empty():
		return
	var shift := Vector2(drift_speed * delta, 0.0)
	var head := _points[_points.size() - 1]
	var kept: PackedVector2Array = []
	for point in _points:
		var moved := point - shift
		if head.x - moved.x <= max_length:
			kept.append(moved)
		else:
			_first_index += 1
	_points = kept
	queue_redraw()


func _has_source() -> bool:
	return source != null and is_instance_valid(source)


func _draw() -> void:
	if _has_source():
		push_point(source.global_position)
	var count := _points.size()
	if count == 0:
		return
	var head := _points[count - 1]
	for i in count:
		var point := _points[i]
		var index := _first_index + i
		var t := clampf((head.x - point.x) / max_length, 0.0, 1.0)
		var dot_color := _dot_color(index)
		dot_color.a *= 1.0 - t
		var radius := dot_radius * (1.0 - t * 0.5)
		match style:
			TrailItem.Style.CRAYON:
				_draw_crayon(point, radius, dot_color, index)
			TrailItem.Style.DASH:
				if index % 2 == 0 and i + 1 < count:
					_add_dash(point, _points[i + 1], radius, dot_color)
			TrailItem.Style.SIGNS:
				if sign_textures.is_empty():
					TrailGlyph.add_to_batch(_batch, TrailGlyph.pick(signs, index), point, radius, dot_color, TrailGlyph.tilt(index))
				else:
					TrailGlyph.draw_sign(self, signs, sign_textures, index, point, radius, dot_color)
			_:
				_draw_dot(point, radius, dot_color)
	_batch.flush(self)


func _draw_dot(point: Vector2, radius: float, dot_color: Color) -> void:
	var half := Vector2(radius, radius)
	draw_texture_rect(DOT_TEXTURE, Rect2(point - half, half * 2.0), false, dot_color)


func _add_dash(from: Vector2, to: Vector2, width: float, dash_color: Color) -> void:
	var side := (to - from).orthogonal().normalized()
	var body := side * width * 0.5
	var outer := side * (width * 0.5 + DASH_FEATHER)
	var faded := Color(dash_color, 0.0)
	_batch.add_colored(
		PackedVector2Array([from + outer, from + body, from - body, from - outer, to + outer, to + body, to - body, to - outer]),
		PackedColorArray([faded, dash_color, dash_color, faded, faded, dash_color, dash_color, faded]),
		DASH_INDICES,
	)


func _dot_color(index: int) -> Color:
	if style == TrailItem.Style.RAINBOW:
		var hue := fmod(float(index) * 0.07, 1.0)
		return Color.from_hsv(hue, 0.6, 0.95, color.a)
	if not palette.is_empty():
		return palette[index % palette.size()]
	return color


## Wax crayon: a few overlapping blobs with stable jitter per dot.
func _draw_crayon(point: Vector2, radius: float, dot_color: Color, index: int) -> void:
	var soft := dot_color
	soft.a *= 0.55
	for k in 3:
		var angle := float((index * 7 + k * 13) % 17) / 17.0 * TAU
		var offset := Vector2.from_angle(angle) * radius * 0.45
		_draw_dot(point + offset, radius * (0.7 + 0.1 * k), soft)
