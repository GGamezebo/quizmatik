extends Node2D

## Graphite pencil dashed lane borders (notebook concept).
## 5 lines form 4 lanes; the two borders of the active lane are highlighted.
@export var dash_color: Color = Color(0.22, 0.27, 0.34, 0.55)
@export var selected_color: Color = Color(0.18, 0.22, 0.28, 0.92)
@export var dash_length: float = 22.0
@export var gap_length: float = 14.0
@export var line_thickness: float = 2.5
@export var selected_thickness: float = 3.8
@export var gameArea: GameArea
@export var lineSelector: LineSelector


func _ready() -> void:
	lineSelector.ev_selected_lane_changed.connect(queue_redraw)
	gameArea.boundary_changed.connect(queue_redraw.unbind(1))


func _draw() -> void:
	var area := gameArea.gameplay_area
	var lines_count := gameArea.getLinesSize()
	var spacing := area.size.y / float(lines_count)
	var selected_lane := lineSelector.selected_lane

	for i in range(lines_count + 1):
		var y_pos := area.position.y + (i * spacing)
		var start := Vector2(area.position.x + 8.0, y_pos)
		var end := Vector2(area.end.x - 8.0, y_pos)
		var selected := i == selected_lane or i == selected_lane + 1
		_draw_dashed_line(
			start,
			end,
			selected_color if selected else dash_color,
			selected_thickness if selected else line_thickness,
			selected
		)


func _draw_dashed_line(start: Vector2, end: Vector2, color: Color, thickness: float, selected: bool) -> void:
	var direction := end - start
	var length := direction.length()
	if length <= 0.001:
		return
	var unit := direction / length
	if selected:
		var glow := color
		glow.a *= 0.22
		_stroke_dashes(start, unit, length, glow, thickness * 2.4)
	_stroke_dashes(start, unit, length, color, thickness)


func _stroke_dashes(start: Vector2, unit: Vector2, length: float, color: Color, thickness: float) -> void:
	var cursor := 0.0
	var draw_dash := true
	while cursor < length:
		var segment := dash_length if draw_dash else gap_length
		var next_cursor := minf(cursor + segment, length)
		if draw_dash:
			var a := start + unit * cursor
			var b := start + unit * next_cursor
			var wobble := sin(cursor * 0.085) * 0.6
			a += Vector2(0.0, wobble)
			b += Vector2(0.0, wobble * 0.85)
			draw_line(a, b, color, thickness, true)
		cursor = next_cursor
		draw_dash = not draw_dash
