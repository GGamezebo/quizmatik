class_name TrailGlyph
extends RefCounted

## Sign-shaped trail dots for `TrailItem.Style.SIGNS` (battle `PlaneFlyerTrail` + hangar `CosmeticSwatch`).
## Signs: `+` `−` `×` `÷` `=` `★`; any other char → round dot. Each part is one flat polygon,
## so see-through ink never darkens where two strokes would overlap.

## Half stroke width, in sign radii.
const STROKE: float = 0.25
const ARC_STEPS: int = 5
const CIRCLE_STEPS: int = 12

static var _shapes: Dictionary[String, Array] = {}


## Glyph of running dot `index` from a `TrailItem.signs` string.
static func pick(signs: String, index: int) -> String:
	if signs.is_empty():
		return ""
	return signs[posmod(index, signs.length())]


## Stable hand-drawn tilt of dot `index`; small enough that + never reads as ×.
static func tilt(index: int) -> float:
	return (float(posmod(index * 37, 13)) / 12.0 - 0.5) * 0.35


## `radius` = half the sign width; `angle` tilts the whole sign.
static func draw(canvas: CanvasItem, glyph: String, center: Vector2, radius: float, color: Color, angle: float = 0.0) -> void:
	var xform := Transform2D(angle, Vector2(radius, radius), 0.0, center)
	for part: PackedVector2Array in _parts(glyph):
		canvas.draw_colored_polygon(xform * part, color)


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
	return [_circle(Vector2.ZERO, 0.6)]


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
