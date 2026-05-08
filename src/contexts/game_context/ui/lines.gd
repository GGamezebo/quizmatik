extends Node2D

@export var line_color: Color = Color(1, 1, 1, 0.3) # Белый цвет с прозрачностью
@export var line_width: float = 2.0
@export var glow_color: Color = Color(0.0, 0.8, 1.0) # Яркий голубой
@export var line_thickness: float = 3.0
@export var glow_intensity: int = 3 # Количество слоев свечения
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
		
		# Проверяем, является ли эта линия выбранной
		var selected_lane = lineSelector.selected_lane
		var is_selected = (i == selected_lane or i == selected_lane + 1)
		
		_draw_glowing_gradient_line(start_pos, end_pos, is_selected)

func _draw_glowing_gradient_line(start: Vector2, end: Vector2, highlighted: bool):
	var points = PackedVector2Array([start, start.lerp(end, 0.5), end])
	
	# Настройки яркости
	var base_alpha = 1.0 if highlighted else 0.3
	var thickness = line_thickness * (2.0 if highlighted else 1.0)

	var color_transparent = glow_color
	color_transparent.a = 0.0
	
	var color_main = glow_color
	color_main.a = base_alpha

	# 1. Свечение (делаем его намного сильнее, если линия выбрана)
	var layers = 6 if highlighted else 2
	for layer in range(layers, 0, -1):
		var layer_color = glow_color
		layer_color.a = (0.15 / layer) * base_alpha
		var layer_width = thickness * (layer * (3.0 if highlighted else 2.0))
		
		draw_polyline_colors(points, PackedColorArray([color_transparent, layer_color, color_transparent]), layer_width, true)

	# 2. Основная линия
	draw_polyline_colors(points, PackedColorArray([color_transparent, color_main, color_transparent]), thickness, true)
