class_name GameArea
extends Node

signal boundary_changed(new_rect)

@export var game_config: GameConfig

var gameplay_area: Rect2

@onready var lines = Lines.new(game_config.answer_lines_count, gameplay_area)

func _ready() -> void:
	get_tree().root.size_changed.connect(update_boundaries)
	update_boundaries()

func update_boundaries() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	
	# Margins for HUD and screen edges
	var margin_top = 160.0
	var margin_bottom = 20.0
	var margin_side = 20.0
	
	gameplay_area = Rect2(
		margin_side, 
		margin_top, 
		screen_size.x - (margin_side * 2), 
		screen_size.y - margin_top - margin_bottom
	)
	lines.update(gameplay_area)
	boundary_changed.emit(gameplay_area)


func getLine(position:Vector2) -> int:
	return lines.getLine(position)
	
	
func getLinesSize() -> int:
	return lines.getSize()
	
func getLines() -> Array[Rect2]:
	return lines.getLines()
	
	
class Lines extends RefCounted:
	var lines: Array[Rect2] = []
	
	func _init(answer_lines_count:int, gameplay_area:Rect2) -> void:
		for i in range(answer_lines_count):
			lines.append(Rect2())
		update(gameplay_area)
		
	func update(gameplay_area:Rect2):
		var spacing = gameplay_area.size.y / (lines.size())
		var area_position = gameplay_area.position
		for i in lines.size():
			var y_pos: float = area_position.y + (i * spacing)
			lines[i].position.x = area_position.x
			lines[i].position.y = y_pos
			lines[i].size = Vector2(gameplay_area.size.x, spacing)
			
	func getLine(position:Vector2) -> int:
		for i in lines.size():
			if lines[i].has_point(position):
				return i
		return 0
	
	func getSize() -> int:
		return lines.size()
		
	func getLines() -> Array[Rect2]:
		return self.lines
