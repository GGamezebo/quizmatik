extends Button

@export var icon_rect: TextureRect
@export var caption: Label
@export var is_primary: bool = false
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_apply_visuals()
@export var caption_text: String = "":
	set(value):
		caption_text = value
		_apply_visuals()


func _ready() -> void:
	HoverScaleButton.bind(self)
	text = ""
	icon = null
	_apply_style()
	_apply_visuals()


func _apply_style() -> void:
	var normal := _make_stylebox(is_primary)
	var hover := _make_stylebox(is_primary, 0.08)
	var pressed_style := _make_stylebox(is_primary, -0.06)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", normal)
	if is_primary:
		add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		add_theme_color_override("font_color", Color(0.165, 0.2, 0.251, 1))


func _make_stylebox(primary: bool, lighten: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if primary:
		style.bg_color = Color(0.42, 0.65, 0.48).lightened(lighten)
	else:
		style.bg_color = Color(0.96, 0.93, 0.87).lightened(lighten)
	style.border_color = Color(0.165, 0.2, 0.251, 0.14 if not primary else 0.0)
	style.set_border_width_all(1 if not primary else 0)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _apply_visuals() -> void:
	if caption != null:
		caption.text = caption_text
		if is_primary:
			caption.add_theme_color_override("font_color", Color.WHITE)
		else:
			caption.add_theme_color_override("font_color", Color(0.165, 0.2, 0.251, 1))
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
