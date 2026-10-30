extends Node

## Main-menu column while the seasonal event banner shows: the title margins and the gaps between the rows shrink
## so title, CTA row, banner and daily scroll fit in 720 px; the authored values come back when the banner hides.

@export var banner: Control
@export var title_margin: MarginContainer
@export var column: VBoxContainer
@export var compact_title_top: int = 0
@export var compact_title_bottom: int = 0
@export var compact_separation: int = 8

var _title_top: int = 0
var _title_bottom: int = 0
var _separation: int = 0


func _ready() -> void:
	_title_top = title_margin.get_theme_constant("margin_top")
	_title_bottom = title_margin.get_theme_constant("margin_bottom")
	_separation = column.get_theme_constant("separation")
	banner.visibility_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var compact: bool = banner.visible
	title_margin.add_theme_constant_override("margin_top", compact_title_top if compact else _title_top)
	title_margin.add_theme_constant_override("margin_bottom", compact_title_bottom if compact else _title_bottom)
	column.add_theme_constant_override("separation", compact_separation if compact else _separation)
