@tool
extends Button
class_name TrainingOptionButton

## Cream pill option; selected = soft green fill (sketch practice UI).

signal option_selected(option_id: StringName)

@export var option_id: StringName = &""
@export var caption: String = "":
	set(value):
		caption = value
		text = value
		_refresh_style()

var _selected: bool = false


func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	text = caption if not caption.is_empty() else text
	toggled.connect(_on_toggled)
	_refresh_style()
	HoverScaleButton.bind(self)


func set_selected(is_on: bool) -> void:
	_selected = is_on
	set_pressed_no_signal(is_on)
	_refresh_style()


func is_option_selected() -> bool:
	return _selected


func _on_toggled(pressed_on: bool) -> void:
	if pressed_on:
		_selected = true
		_refresh_style()
		option_selected.emit(option_id)
	else:
		# Radio groups: keep at least one pressed visually via parent.
		set_pressed_no_signal(_selected)
		_refresh_style()


func _refresh_style() -> void:
	var fill := Color(0.72, 0.82, 0.62, 1.0) if _selected else Color(0.98, 0.95, 0.90, 1.0)
	var border := Color(0.45, 0.58, 0.38, 0.55) if _selected else Color(0.165, 0.2, 0.251, 0.14)
	var font_col := Color(0.22, 0.32, 0.20, 1.0) if _selected else Color(0.165, 0.2, 0.251, 1.0)
	add_theme_stylebox_override("normal", _make_box(fill, border))
	add_theme_stylebox_override("hover", _make_box(fill.lightened(0.04), border))
	add_theme_stylebox_override("pressed", _make_box(fill, border))
	add_theme_stylebox_override("focus", _make_box(fill, border))
	add_theme_constant_override("outline_size", 0)
	add_theme_color_override("font_color", font_col)
	add_theme_color_override("font_pressed_color", font_col)
	add_theme_color_override("font_hover_color", font_col)
	add_theme_color_override("font_focus_color", font_col)


func _make_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
