class_name PlaneFlyerTrail
extends Node2D

## Pencil dots behind a hovering plane. Points live in global space (`top_level`) and
## drift left so a plane standing still still reads as flying right.

@export var color: Color = Color(0.165, 0.2, 0.251, 0.75)
@export var drift_speed: float = 260.0
@export var dot_spacing: float = 22.0
@export var dot_radius: float = 4.0
@export var max_length: float = 520.0

var _points: PackedVector2Array = []


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO


func push_point(global_point: Vector2) -> void:
	if _points.is_empty() or _points[_points.size() - 1].distance_to(global_point) >= dot_spacing:
		_points.append(global_point)


func clear() -> void:
	_points.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _points.is_empty():
		return
	var shift := Vector2(drift_speed * delta, 0.0)
	var head := _points[_points.size() - 1]
	var kept: PackedVector2Array = []
	for point in _points:
		var moved := point - shift
		if head.x - moved.x <= max_length:
			kept.append(moved)
	_points = kept
	queue_redraw()


func _draw() -> void:
	var count := _points.size()
	if count == 0:
		return
	var head := _points[count - 1]
	for i in count:
		var point := _points[i]
		var t := clampf((head.x - point.x) / max_length, 0.0, 1.0)
		var dot_color := color
		dot_color.a *= 1.0 - t
		draw_circle(point, dot_radius * (1.0 - t * 0.5), dot_color)
