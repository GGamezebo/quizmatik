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

## Per-line geometry (normal / selected look), key = `line_index * 2 + int(selected)`. A lane change
## redraws from here: one triangle array + one multiline per line. Hundreds of `draw_colored_polygon` /
## antialiased `draw_line` per redraw = a GPU buffer each → 80–130 ms frame hitch on WebGL.
var _geometry: Dictionary = {}
var _geometry_area := Rect2()
var _geometry_lines: int = -1


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
	if area != _geometry_area or lines_count != _geometry_lines:
		_geometry.clear()
		_geometry_area = area
		_geometry_lines = lines_count
	var spacing := area.size.y / float(lines_count)
	var selected_lane := lineSelector.selected_lane

	for i in range(lines_count + 1):
		var selected := i == selected_lane or i == selected_lane + 1
		var key := i * 2 + int(selected)
		if not _geometry.has(key):
			var y_pos := area.position.y + (i * spacing)
			_geometry[key] = _build_ribbon(
				Vector2(area.position.x + end_margin, y_pos),
				Vector2(area.end.x - end_margin, y_pos),
				selected_paper_color if selected else paper_color,
				selected_half_height if selected else ribbon_half_height,
				i
			)
		var ribbon: RibbonGeometry = _geometry[key]
		if ribbon.indices.is_empty():
			continue
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), ribbon.indices, ribbon.points, ribbon.colors)
		draw_multiline(ribbon.edges, ribbon.edge_color, 1.0, true)


## Dash shadows + fills (one triangle array) and their edges (line pairs) of one lane line.
class RibbonGeometry:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var edges := PackedVector2Array()
	var edge_color := Color.WHITE


func _build_ribbon(
	start: Vector2,
	end: Vector2,
	fill: Color,
	half_h: float,
	line_index: int,
) -> RibbonGeometry:
	var ribbon := RibbonGeometry.new()
	ribbon.edge_color = edge_color
	if fill.a > 0.95:
		ribbon.edge_color.a = minf(edge_color.a + 0.12, 1.0)
	var fills := RibbonGeometry.new()
	var total_len := end.x - start.x
	if total_len <= 1.0:
		return ribbon

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
			_add_paper_dash(ribbon, fills, a, b, fill, half_h, line_index, dash_i)

		cursor = next_cursor
		draw_dash = not draw_dash
		dash_i += 1

	# Fills after all shadows: same layering as shadow → fill per dash (dashes never overlap).
	var offset := ribbon.points.size()
	ribbon.points.append_array(fills.points)
	ribbon.colors.append_array(fills.colors)
	for index in fills.indices:
		ribbon.indices.append(index + offset)
	return ribbon


## Dash = band between its wobbly top and bottom edges: shadow into `shadows`, fill into `fills`.
func _add_paper_dash(
	shadows: RibbonGeometry,
	fills: RibbonGeometry,
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
	_add_band(shadows, top, bottom, shadow_offset, shadow_color)
	_add_band(fills, top, bottom, Vector2.ZERO, fill)
	for i in range(top.size() - 1):
		shadows.edges.append_array([top[i], top[i + 1], bottom[i], bottom[i + 1]])


## Triangle strip between two edges with the same point count.
func _add_band(
	geometry: RibbonGeometry,
	top: PackedVector2Array,
	bottom: PackedVector2Array,
	offset: Vector2,
	color: Color,
) -> void:
	var base := geometry.points.size()
	var count := top.size()
	for p in top:
		geometry.points.append(p + offset)
	for p in bottom:
		geometry.points.append(p + offset)
	for i in count * 2:
		geometry.colors.append(color)
	for i in range(count - 1):
		geometry.indices.append_array([base + i, base + count + i, base + i + 1])
		geometry.indices.append_array([base + i + 1, base + count + i, base + count + i + 1])


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


func _hash01(n: int) -> float:
	## Stable 0..1 hash so wobble does not flicker on redraw.
	var x: int = n * 1103515245 + 12345
	x = (x ^ (x >> 16)) & 0x7fffffff
	return float(x % 10000) / 10000.0
