class_name DailySlot
extends PanelContainer

## Display-only daily challenge slot (not interactive).

@export var mark: TextureRect
@export var star_empty: Texture2D
@export var star_filled: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_filled(filled: bool) -> void:
	mark.texture = star_filled if filled else star_empty
	mark.modulate = Color.WHITE
