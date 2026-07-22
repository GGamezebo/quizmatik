class_name GameArea
extends Node

signal boundary_changed(new_rect)

var gameplay_area: Rect2
var _game_config: GameConfig
var _lines: Lines


func initialize(game_config: GameConfig) -> void:
	_game_config = game_config
	_lines = Lines.new(game_config.answer_lines_count, gameplay_area)
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
	_lines.update(gameplay_area)
	boundary_changed.emit(gameplay_area)

func getLine(position:Vector2) -> int:
	return _lines.getLine(position)
	
func getLinesSize() -> int:
	return _lines.getSize()
	
func getLines() -> Array[Rect2]:
	return _lines.getLines()
	
	
class Lines extends RefCounted:
	var _lines: Array[Rect2] = []
	
	func _init(answer_lines_count:int, gameplay_area:Rect2) -> void:
		for i in range(answer_lines_count):
			_lines.append(Rect2())
		update(gameplay_area)
		
	func update(gameplay_area:Rect2):
		var spacing = gameplay_area.size.y / (_lines.size())
		var area_position = gameplay_area.position
		for i in _lines.size():
			var y_pos: float = area_position.y + (i * spacing)
			_lines[i].position.x = area_position.x
			_lines[i].position.y = y_pos
			_lines[i].size = Vector2(gameplay_area.size.x, spacing)
			
	func getLine(position:Vector2) -> int:
		for i in _lines.size():
			if _lines[i].has_point(position):
				return i
		return 0
	
	func getSize() -> int:
		return _lines.size()
		
	func getLines() -> Array[Rect2]:
		return _lines
