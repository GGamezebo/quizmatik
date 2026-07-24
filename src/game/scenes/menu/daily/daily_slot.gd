class_name DailySlot
extends PanelContainer

## Display-only daily challenge slot (not interactive).

@export var mark: TextureRect

const EMPTY_MODULATE := Color(0.35, 0.4, 0.55, 0.4)
const FILLED_MODULATE := Color(1.0, 0.92, 0.55, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_filled(filled: bool) -> void:
	mark.modulate = FILLED_MODULATE if filled else EMPTY_MODULATE
