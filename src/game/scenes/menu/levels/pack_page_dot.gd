extends Panel

signal ev_pressed

@export var idle_color: Color = Color(0.953, 0.902, 0.784, 1)
@export var current_color: Color = Color(1.0, 0.9, 0.18, 1)
@export var outline_color: Color = Color(1, 1, 1, 1)
@export var outline_width: int = 2
@export var idle_diameter: float = 14.0
@export var current_diameter: float = 18.0


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_current(false)


func set_current(is_current: bool) -> void:
	var diameter := current_diameter if is_current else idle_diameter
	var fill := current_color if is_current else idle_color
	var side := Vector2.ONE * diameter
	custom_minimum_size = side
	size = side
	add_theme_stylebox_override("panel", _make_circle_style(fill, diameter * 0.5))


func _make_circle_style(fill: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(outline_width)
	style.border_color = outline_color
	style.set_corner_radius_all(int(round(radius)))
	style.set_content_margin_all(0)
	return style


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			ev_pressed.emit()
			accept_event()
