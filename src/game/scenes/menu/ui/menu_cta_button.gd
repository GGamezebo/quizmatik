extends Button

## Wide parchment CTA: separate icon TextureRect + caption Label in an HBox.

@export var icon_rect: TextureRect
@export var caption: Label
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_apply_visuals()
@export var caption_text: String = "":
	set(value):
		caption_text = value
		_apply_visuals()
@export var caption_color: Color = Color(0.165, 0.2, 0.251, 1):
	set(value):
		caption_color = value
		_apply_visuals()


func _ready() -> void:
	HoverScaleButton.bind(self)
	text = ""
	icon = null
	clip_text = true
	_apply_visuals()


func _apply_visuals() -> void:
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
	if caption == null:
		return
	caption.text = caption_text
	if caption.label_settings != null:
		var settings: LabelSettings = caption.label_settings.duplicate()
		settings.font_color = caption_color
		caption.label_settings = settings
	else:
		caption.add_theme_color_override("font_color", caption_color)
