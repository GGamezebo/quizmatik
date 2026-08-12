extends Node2D

## White paper ribbon lane guides as a dashed strip.
## Soft cut-paper dashes with a faint drop shadow.
## Visible only while battle FSM is in GameState.

@export var paper_color: Color = Color(0.98, 0.97, 0.94, 0.92)
@export var selected_paper_color: Color = Color(1.0, 0.995, 0.98, 0.98)
@export var edge_color: Color = Color(0.86, 0.84, 0.80, 0.55)
@export var shadow_color: Color = Color(0.22, 0.26, 0.34, 0.22)
@export var ribbon_half_height: float = 3.4
@export var selected_half_height: float = 4.2
@export var shadow_offset: Vector2 = Vector2(1.5, 2.5)
@export var edge_wobble: float = 0.7
@export var dash_length: float = 22.0
@export var gap_length: float = 14.0
@export var dash_length_jitter: float = 5.0
@export var gap_length_jitter: float = 4.0
@export var end_margin: float = 6.0
@export var gameArea: GameArea
@export var lineSelector: LineSelector
@export var game_events: GameEvents


func _ready() -> void:
	visible = false
	if lineSelector:
		lineSelector.ev_selected_lane_changed.connect(queue_redraw)
	if gameArea:
		gameArea.boundary_changed.connect(queue_redraw.unbind(1))
	if game_events:
		game_events.ev_game_state_changed.connect(_on_game_state_changed)


func _exit_tree() -> void:
	if game_events and game_events.ev_game_state_changed.is_connected(_on_game_state_changed):
		game_events.ev_game_state_changed.disconnect(_on_game_state_changed)


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	visible = to_state == FSMGameStates.GAME
	if visible:
		queue_redraw()


func _draw() -> void:
	if not visible or gameArea == null or lineSelector == null:
		return
	var area := gameArea.gameplay_area
	var lines_count := gameArea.getLinesSize()
	if lines_count <= 0:
		return
	var spacing := area.size.y / float(lines_count)
	var selected_lane := lineSelector.selected_lane

	for i in range(lines_count + 1):
		var y_pos := area.position.y + (i * spacing)
		var start := Vector2(area.position.x + end_margin, y_pos)
		var end := Vector2(area.end.x - end_margin, y_pos)
		var selected := i == selected_lane or i == selected_lane + 1
		_draw_dashed_paper_ribbon(
			start,
			end,
			selected_paper_color if selected else paper_color,
			selected_half_height if selected else ribbon_half_height,
			i
		)


func _draw_dashed_paper_ribbon(
	start: Vector2,
	end: Vector2,
	fill: Color,
	half_h: float,
	line_index: int,
) -> void:
	var total_len := end.x - start.x
	if total_len <= 1.0:
		return

	var cursor := 0.0
	var dash_i := 0
	var draw_dash := true
	while cursor < total_len:
		var seed_base := line_index * 997 + dash_i * 131
		var r0 := _hash01(seed_base)
		var r1 := _hash01(seed_base + 3)

		var segment: float
		if draw_dash:
			segment = dash_length + (r0 - 0.5) * 2.0 * dash_length_jitter
		else:
			segment = gap_length + (r1 - 0.5) * 2.0 * gap_length_jitter
		segment = maxf(segment, 3.0)
		var next_cursor := minf(cursor + segment, total_len)

		if draw_dash:
			var a := Vector2(start.x + cursor, start.y)
			var b := Vector2(start.x + next_cursor, start.y)
			_draw_paper_dash(a, b, fill, half_h, line_index, dash_i)

		cursor = next_cursor
		draw_dash = not draw_dash
		dash_i += 1


func _draw_paper_dash(
	start: Vector2,
	end: Vector2,
	fill: Color,
	half_h: float,
	line_index: int,
	dash_i: int,
) -> void:
	var length := end.x - start.x
	if length <= 1.0:
		return

	var top := _build_edge(start, length, -half_h, line_index, dash_i * 2)
	var bottom := _build_edge(start, length, half_h, line_index, dash_i * 2 + 1)
	var poly: PackedVector2Array = PackedVector2Array()
	poly.append_array(top)
	for i in range(bottom.size() - 1, -1, -1):
		poly.append(bottom[i])

	var shadow_poly := PackedVector2Array()
	for p in poly:
		shadow_poly.append(p + shadow_offset)
	draw_colored_polygon(shadow_poly, shadow_color)
	draw_colored_polygon(poly, fill)

	var edge := edge_color
	if fill.a > 0.95:
		edge.a = minf(edge.a + 0.12, 1.0)
	_stroke_polyline(top, edge, 1.0)
	_stroke_polyline(bottom, edge, 1.0)


func _build_edge(
	start: Vector2,
	length: float,
	base_y: float,
	line_index: int,
	edge_id: int,
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(int(ceil(length / 10.0)), 2)
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var x := start.x + length * t
		var h := _hash01(line_index * 113 + edge_id * 47 + s * 19)
		var wobble := (h - 0.5) * 2.0 * edge_wobble
		var end_fade := 1.0
		if t < 0.08 or t > 0.92:
			end_fade = 0.55 + h * 0.35
		points.append(Vector2(x, start.y + base_y * end_fade + wobble))
	return points


func _stroke_polyline(points: PackedVector2Array, color: Color, thickness: float) -> void:
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, thickness, true)


func _hash01(n: int) -> float:
	## Stable 0..1 hash so wobble does not flicker on redraw.
	var x: int = n * 1103515245 + 12345
	x = (x ^ (x >> 16)) & 0x7fffffff
	return float(x % 10000) / 10000.0
