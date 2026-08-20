extends Button

## Wide parchment CTA: icon + title + optional subtitle.

@export var icon_rect: TextureRect
@export var caption: Label
@export var subtitle: Label
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_apply_visuals()
@export var caption_text: String = "":
	set(value):
		caption_text = value
		_apply_visuals()
@export var subtitle_text: String = "":
	set(value):
		subtitle_text = value
		_apply_visuals()
@export var caption_color: Color = Color(0.165, 0.2, 0.251, 1):
	set(value):
		caption_color = value
		_apply_visuals()


func _ready() -> void:
	HoverScaleButton.bind(self)
	text = ""
	icon = null
	clip_text = false
	_apply_visuals()


func _apply_visuals() -> void:
	var has_icon := icon_texture != null
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = has_icon
	var hbox := get_node_or_null("Margin/HBox") as HBoxContainer
	if hbox != null:
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN if has_icon else BoxContainer.ALIGNMENT_CENTER
	var texts := get_node_or_null("Margin/HBox/Texts") as Control
	if texts != null:
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL if has_icon else Control.SIZE_SHRINK_CENTER
	if caption != null:
		caption.text = caption_text
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if has_icon else HORIZONTAL_ALIGNMENT_CENTER
		if caption.label_settings != null:
			var settings: LabelSettings = caption.label_settings.duplicate()
			settings.font_color = caption_color
			caption.label_settings = settings
		else:
			caption.add_theme_color_override("font_color", caption_color)
	if subtitle != null:
		subtitle.text = subtitle_text
		subtitle.visible = not subtitle_text.is_empty()
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if has_icon else HORIZONTAL_ALIGNMENT_CENTER
