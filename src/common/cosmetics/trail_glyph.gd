class_name TrailGlyph
extends RefCounted

## Sign-shaped trail dots for `TrailItem.Style.SIGNS` (battle `PlaneFlyerTrail` + hangar `CosmeticSwatch`).
## Signs: `+` `−` `×` `÷` `=` `★`, Halloween `b` bat / `g` ghost; any other char → round dot. Each part is one flat polygon,
## so see-through ink never darkens where two strokes would overlap. `TrailItem.sign_textures` (white silhouettes) win over chars.

## Half stroke width, in sign radii.
const STROKE: float = 0.25
const ARC_STEPS: int = 5
const CIRCLE_STEPS: int = 12

static var _shapes: Dictionary[String, Array] = {}
## Triangle indices of each `_shapes` part.
static var _triangles: Dictionary[String, Array] = {}


## Many flat shapes of one redraw as a single triangle array (one GPU buffer, not one per shape).
class Batch:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	func add(shape: PackedVector2Array, shape_indices: PackedInt32Array, color: Color) -> void:
		var shape_colors := PackedColorArray()
		shape_colors.resize(shape.size())
		shape_colors.fill(color)
		add_colored(shape, shape_colors, shape_indices)

	func add_colored(shape: PackedVector2Array, shape_colors: PackedColorArray, shape_indices: PackedInt32Array) -> void:
		var base := points.size()
		points.append_array(shape)
		colors.append_array(shape_colors)
		for index in shape_indices:
			indices.append(base + index)

	func flush(canvas: CanvasItem) -> void:
		if indices.is_empty():
			return
		RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
		points.clear()
		colors.clear()
		indices.clear()


## Glyph of running dot `index` from a `TrailItem.signs` string.
static func pick(signs: String, index: int) -> String:
	if signs.is_empty():
		return ""
	return signs[posmod(index, signs.length())]


## Stable hand-drawn tilt of dot `index`; small enough that + never reads as ×.
static func tilt(index: int) -> float:
	return (float(posmod(index * 37, 13)) / 12.0 - 0.5) * 0.35


## Dot `index` of a `SIGNS` trail: the next of `textures` if any, else the next char of `signs`; tilted by `tilt`.
static func draw_sign(canvas: CanvasItem, signs: String, textures: Array[Texture2D], index: int, center: Vector2,
		radius: float, color: Color) -> void:
	if textures.is_empty():
		draw(canvas, pick(signs, index), center, radius, color, tilt(index))
		return
	var texture: Texture2D = textures[posmod(index, textures.size())]
	if texture == null:
		return
	var tex_size := texture.get_size()
	var half := Vector2(radius, radius * tex_size.y / maxf(tex_size.x, 1.0))
	canvas.draw_set_transform(center, tilt(index))
	canvas.draw_texture_rect(texture, Rect2(-half, half * 2.0), false, color)
	canvas.draw_set_transform(Vector2.ZERO)


## `radius` = half the sign width; `angle` tilts the whole sign.
static func draw(canvas: CanvasItem, glyph: String, center: Vector2, radius: float, color: Color, angle: float = 0.0) -> void:
	var xform := Transform2D(angle, Vector2(radius, radius), 0.0, center)
	for part: PackedVector2Array in _parts(glyph):
		canvas.draw_colored_polygon(xform * part, color)


## Same sign as `draw`, added to `batch` — for per-frame redraws.
static func add_to_batch(batch: Batch, glyph: String, center: Vector2, radius: float, color: Color, angle: float = 0.0) -> void:
	var xform := Transform2D(angle, Vector2(radius, radius), 0.0, center)
	var parts := _parts(glyph)
	if not _triangles.has(glyph):
		var triangles: Array[PackedInt32Array] = []
		for part: PackedVector2Array in parts:
			triangles.append(Geometry2D.triangulate_polygon(part))
		_triangles[glyph] = triangles
	var triangles: Array = _triangles[glyph]
	for i in parts.size():
		batch.add(xform * (parts[i] as PackedVector2Array), triangles[i], color)


static func _parts(glyph: String) -> Array:
	if not _shapes.has(glyph):
		_shapes[glyph] = _build(glyph)
	return _shapes[glyph]


static func _build(glyph: String) -> Array:
	match glyph:
		"+":
			return [_cross(0.0)]
		"×", "x":
			return [_cross(PI * 0.25)]
		"−", "-":
			return [_capsule(Vector2(-1.0 + STROKE, 0.0), Vector2(1.0 - STROKE, 0.0), STROKE)]
		"÷":
			var bar := STROKE * 0.85
			return [
				_capsule(Vector2(-1.0 + bar, 0.0), Vector2(1.0 - bar, 0.0), bar),
				_circle(Vector2(0.0, -0.64), STROKE * 1.15),
				_circle(Vector2(0.0, 0.64), STROKE * 1.15),
			]
		"=":
			var bar := STROKE * 0.8
			return [
				_capsule(Vector2(-1.0 + bar, -0.36), Vector2(1.0 - bar, -0.36), bar),
				_capsule(Vector2(-1.0 + bar, 0.36), Vector2(1.0 - bar, 0.36), bar),
			]
		"★", "*":
			return [_star(1.2, 0.52)]
		"b":
			return [_bat()]
		"g":
			return [_ghost()]
	return [_circle(Vector2.ZERO, 0.6)]


## Halloween bat silhouette: ears, scalloped wings.
static func _bat() -> PackedVector2Array:
	var outline := [
		Vector2(-3, -8), Vector2(-1, -4), Vector2(1, -4), Vector2(3, -8), Vector2(5, -5), Vector2(10, -9),
		Vector2(16, -11), Vector2(22, -6), Vector2(19, -2), Vector2(16, 1), Vector2(13, -1), Vector2(10, 3),
		Vector2(7, 1), Vector2(4, 6), Vector2(0, 8), Vector2(-4, 6), Vector2(-7, 1), Vector2(-10, 3), Vector2(-13, -1),
		Vector2(-16, 1), Vector2(-19, -2), Vector2(-22, -6), Vector2(-16, -11), Vector2(-10, -9), Vector2(-5, -5),
	]
	var points := PackedVector2Array()
	for point: Vector2 in outline:
		points.append(point / 20.0)
	return points


## Halloween ghost silhouette: round head, wavy hem.
static func _ghost() -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in CIRCLE_STEPS + 1:
		points.append(Vector2.from_angle(PI + PI * float(step) / CIRCLE_STEPS) * 0.8 + Vector2(0.0, -0.1))
	for point: Vector2 in [Vector2(0.8, 0.8), Vector2(0.53, 0.6), Vector2(0.27, 0.85), Vector2(0.0, 0.6),
			Vector2(-0.27, 0.85), Vector2(-0.53, 0.6), Vector2(-0.8, 0.8)]:
		points.append(point)
	return points


## Plus as one outline: 4 arms with round ends, turned by `turn` (× = 45°).
static func _cross(turn: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for arm in 4:
		var a := turn + float(arm) * PI * 0.5
		points.append(Vector2(STROKE, -STROKE).rotated(a))
		var tip := Vector2(1.0 - STROKE, 0.0).rotated(a)
		for step in ARC_STEPS + 1:
			points.append(tip + Vector2.from_angle(a - PI * 0.5 + PI * float(step) / ARC_STEPS) * STROKE)
	return points


static func _capsule(from: Vector2, to: Vector2, half_width: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var dir := (to - from).angle()
	for step in ARC_STEPS + 1:
		points.append(to + Vector2.from_angle(dir - PI * 0.5 + PI * float(step) / ARC_STEPS) * half_width)
	for step in ARC_STEPS + 1:
		points.append(from + Vector2.from_angle(dir + PI * 0.5 + PI * float(step) / ARC_STEPS) * half_width)
	return points


static func _circle(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in CIRCLE_STEPS:
		points.append(center + Vector2.from_angle(TAU * float(step) / CIRCLE_STEPS) * radius)
	return points


static func _star(outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in 10:
		var r := outer if step % 2 == 0 else inner
		points.append(Vector2.from_angle(-PI * 0.5 + PI * float(step) / 5.0) * r)
	return points
