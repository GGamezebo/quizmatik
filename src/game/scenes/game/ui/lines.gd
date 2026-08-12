extends Node2D

## Graphite pencil lane guides — match concepts/battle_notebook_modern_v1.png.
## Dashed, slightly wobbly strokes with small "x" ticks; no neon glow.
## Visible only while battle FSM is in GameState.

@export var dash_color: Color = Color(0.28, 0.32, 0.38, 0.48)
@export var selected_color: Color = Color(0.20, 0.24, 0.30, 0.78)
@export var dash_length: float = 17.0
@export var gap_length: float = 15.0
@export var dash_length_jitter: float = 7.0
@export var gap_length_jitter: float = 6.0
@export var wobble_amp: float = 1.45
@export var line_thickness: float = 2.15
@export var selected_thickness: float = 2.85
@export var soft_pass_scale: float = 2.1
@export var soft_pass_alpha: float = 0.28
@export var x_mark_spacing: float = 88.0
@export var x_mark_size: float = 5.2
@export var end_margin: float = 10.0
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
		var color := selected_color if selected else dash_color
		var thickness := selected_thickness if selected else line_thickness
		_draw_pencil_lane(start, end, color, thickness, i)


func _draw_pencil_lane(start: Vector2, end: Vector2, color: Color, thickness: float, line_index: int) -> void:
	var direction := end - start
	var length := direction.length()
	if length <= 0.001:
		return
	var unit := direction / length
	var normal := Vector2(-unit.y, unit.x)

	# Soft graphite halo under the stroke (paper soak), then crisp core.
	var soft := color
	soft.a *= soft_pass_alpha
	_stroke_pencil_dashes(start, unit, normal, length, soft, thickness * soft_pass_scale, line_index, 0)
	_stroke_pencil_dashes(start, unit, normal, length, color, thickness, line_index, 1)

	_draw_x_marks(start, unit, normal, length, color, thickness, line_index)


func _stroke_pencil_dashes(
	start: Vector2,
	unit: Vector2,
	normal: Vector2,
	length: float,
	color: Color,
	thickness: float,
	line_index: int,
	pass_id: int,
) -> void:
	var cursor := 0.0
	var dash_i := 0
	var draw_dash := true
	while cursor < length:
		var seed_base := line_index * 997 + dash_i * 131 + pass_id * 17
		var r0 := _hash01(seed_base)
		var r1 := _hash01(seed_base + 3)
		var r2 := _hash01(seed_base + 7)
		var r3 := _hash01(seed_base + 11)

		var segment: float
		if draw_dash:
			segment = dash_length + (r0 - 0.5) * 2.0 * dash_length_jitter
		else:
			segment = gap_length + (r1 - 0.5) * 2.0 * gap_length_jitter
		segment = maxf(segment, 3.0)
		var next_cursor := minf(cursor + segment, length)

		if draw_dash:
			var wobble_a := (r2 - 0.5) * 2.0 * wobble_amp
			var wobble_b := (r3 - 0.5) * 2.0 * wobble_amp
			# Slight along-line taper / pressure change.
			var thick := thickness * (0.82 + r0 * 0.36)
			var a := start + unit * cursor + normal * wobble_a
			var b := start + unit * next_cursor + normal * wobble_b
			# Tiny second nick on longer dashes — reads as pencil grain.
			if next_cursor - cursor > dash_length * 0.85:
				var mid_t := 0.45 + (r1 - 0.5) * 0.2
				var mid := a.lerp(b, mid_t) + normal * ((r2 - 0.5) * wobble_amp * 0.55)
				draw_line(a, mid, color, thick, true)
				draw_line(mid, b, color, thick * (0.9 + r3 * 0.2), true)
			else:
				draw_line(a, b, color, thick, true)

		cursor = next_cursor
		draw_dash = not draw_dash
		dash_i += 1


func _draw_x_marks(
	start: Vector2,
	unit: Vector2,
	normal: Vector2,
	length: float,
	color: Color,
	thickness: float,
	line_index: int,
) -> void:
	var mark_color := color
	mark_color.a *= 0.85
	var positions: Array[float] = [0.0, length]
	var t := x_mark_spacing * 0.55
	while t < length - x_mark_spacing * 0.4:
		positions.append(t)
		t += x_mark_spacing + (_hash01(line_index * 41 + int(t)) - 0.5) * 18.0

	for i in positions.size():
		var along: float = positions[i]
		var mark_seed := line_index * 53 + i * 19
		var wobble := (_hash01(mark_seed) - 0.5) * wobble_amp * 1.2
		var center := start + unit * along + normal * wobble
		var size := x_mark_size * (0.85 + _hash01(mark_seed + 5) * 0.35)
		var rot := (_hash01(mark_seed + 9) - 0.5) * 0.35
		var arm_a := Vector2(cos(rot), sin(rot)) * size
		var arm_b := Vector2(-sin(rot), cos(rot)) * size
		var thick := maxf(thickness * 0.85, 1.4)
		draw_line(center - arm_a, center + arm_a, mark_color, thick, true)
		draw_line(center - arm_b, center + arm_b, mark_color, thick, true)


func _hash01(n: int) -> float:
	## Stable 0..1 hash so wobble does not flicker on redraw.
	var x: int = n * 1103515245 + 12345
	x = (x ^ (x >> 16)) & 0x7fffffff
	return float(x % 10000) / 10000.0
