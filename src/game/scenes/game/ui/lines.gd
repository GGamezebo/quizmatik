extends Node2D

## White paper ribbon lane guides — match concepts/gameplay_preview/02_battle.png.
## Soft cut-paper strips with a faint drop shadow (not graphite dashes).
## Visible only while battle FSM is in GameState.

@export var paper_color: Color = Color(0.98, 0.97, 0.94, 0.92)
@export var selected_paper_color: Color = Color(1.0, 0.995, 0.98, 0.98)
@export var edge_color: Color = Color(0.86, 0.84, 0.80, 0.55)
@export var shadow_color: Color = Color(0.22, 0.26, 0.34, 0.22)
@export var ribbon_half_height: float = 3.4
@export var selected_half_height: float = 4.2
@export var shadow_offset: Vector2 = Vector2(1.5, 2.5)
@export var edge_wobble: float = 0.85
@export var segment_length: float = 28.0
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
	var spacing := area.size.y / float(lines_count)
	var selected_lane := lineSelector.selected_lane

	for i in range(lines_count + 1):
		var y_pos := area.position.y + (i * spacing)
		var start := Vector2(area.position.x + end_margin, y_pos)
		var end := Vector2(area.end.x - end_margin, y_pos)
		var selected := i == selected_lane or i == selected_lane + 1
		_draw_paper_ribbon(
			start,
			end,
			selected_paper_color if selected else paper_color,
			selected_half_height if selected else ribbon_half_height,
			i
		)


func _draw_paper_ribbon(
	start: Vector2,
	end: Vector2,
	fill: Color,
	half_h: float,
	line_index: int,
) -> void:
	var length := end.x - start.x
	if length <= 1.0:
		return

	var top := _build_edge(start, length, -half_h, line_index, 0)
	var bottom := _build_edge(start, length, half_h, line_index, 1)
	# Polygon: top L→R, then bottom R→L.
	var poly: PackedVector2Array = PackedVector2Array()
	poly.append_array(top)
	for i in range(bottom.size() - 1, -1, -1):
		poly.append(bottom[i])

	# Soft shadow under the strip (sticker depth).
	var shadow_poly := PackedVector2Array()
	for p in poly:
		shadow_poly.append(p + shadow_offset)
	draw_colored_polygon(shadow_poly, shadow_color)

	draw_colored_polygon(poly, fill)

	# Hairline cut edge — reads as layered paper, not a flat vector bar.
	var edge := edge_color
	if fill.a > 0.95:
		edge.a = minf(edge.a + 0.12, 1.0)
	_stroke_polyline(top, edge, 1.1)
	_stroke_polyline(bottom, edge, 1.1)


func _build_edge(
	start: Vector2,
	length: float,
	base_y: float,
	line_index: int,
	edge_id: int,
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(int(ceil(length / segment_length)), 2)
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var x := start.x + length * t
		var h := _hash01(line_index * 113 + edge_id * 47 + s * 19)
		var wobble := (h - 0.5) * 2.0 * edge_wobble
		# Ends slightly tapered / torn so the strip does not look machine-cut.
		var end_fade := 1.0
		if t < 0.02 or t > 0.98:
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
