extends Node2D

@export var line_color: Color = Color(1, 1, 1, 0.3) # White with transparency
@export var line_width: float = 2.0
@export var glow_color: Color = Color(0.0, 0.8, 1.0) # Bright cyan
@export var line_thickness: float = 3.0
@export var glow_intensity: int = 3 # Glow layer count
@export var gameArea: GameArea
@export var lineSelector: LineSelector

func _ready():
	lineSelector.ev_selected_lane_changed.connect(queue_redraw)

func _draw():
	var area = gameArea.gameplay_area
	
	var lines_count = gameArea.getLinesSize()
	var spacing = area.size.y / lines_count
	
	for i in range(lines_count + 1):
		var y_pos = area.position.y + (i * spacing)
		var start_pos = Vector2(area.position.x, y_pos)
		var end_pos = Vector2(area.end.x, y_pos)
		
		# Highlight the selected lane borders
		var selected_lane = lineSelector.selected_lane
		var is_selected = (i == selected_lane or i == selected_lane + 1)
		
		_draw_glowing_gradient_line(start_pos, end_pos, is_selected)

func _draw_glowing_gradient_line(start: Vector2, end: Vector2, highlighted: bool):
	var points = PackedVector2Array([start, start.lerp(end, 0.5), end])
	
	# Brightness settings
	var base_alpha = 1.0 if highlighted else 0.3
	var thickness = line_thickness * (2.0 if highlighted else 1.0)

	var color_transparent = glow_color
	color_transparent.a = 0.0
	
	var color_main = glow_color
	color_main.a = base_alpha

	# 1. Glow layers (stronger when highlighted)
	var layers = 6 if highlighted else 2
	for layer in range(layers, 0, -1):
		var layer_color = glow_color
		layer_color.a = (0.15 / layer) * base_alpha
		var layer_width = thickness * (layer * (3.0 if highlighted else 2.0))
		
		draw_polyline_colors(points, PackedColorArray([color_transparent, layer_color, color_transparent]), layer_width, true)

	# 2. Main line
	draw_polyline_colors(points, PackedColorArray([color_transparent, color_main, color_transparent]), thickness, true)
