extends VBoxContainer

## Circular notebook sticker button + caption under it.

@export var button: BaseButton
@export var icon: TextureRect
@export var caption: Label
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_apply_visuals()
@export var caption_text: String = "НАСТРОЙКИ":
	set(value):
		caption_text = value
		_apply_visuals()


func _ready() -> void:
	if button != null:
		button.focus_mode = Control.FOCUS_NONE
	_apply_visuals()


func _apply_visuals() -> void:
	if icon != null and icon_texture != null:
		icon.texture = icon_texture
	if caption != null:
		caption.text = caption_text
