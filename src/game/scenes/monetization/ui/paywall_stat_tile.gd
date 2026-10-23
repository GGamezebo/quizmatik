class_name PaywallStatTile
extends PanelContainer

## One achievement of the pilot on the paywall: icon, big value, caption (icon + caption set in the editor).

@export var caption: String = ""
@export var icon: Texture2D
@export var icon_rect: TextureRect
@export var value_label: Label
@export var caption_label: Label


func _ready() -> void:
	caption_label.text = caption
	icon_rect.texture = icon


func set_value(text: String) -> void:
	value_label.text = text
