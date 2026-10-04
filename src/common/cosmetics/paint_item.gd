class_name PaintItem
extends CosmeticItem

## Procedural pattern over the plane body (`plane_body.gdshader`). Outline + sticker edge stay.

enum Pattern { NONE, STRIPES, DOTS, CHECKER, STARS, ZIGZAG, WATERCOLOR, RAINBOW }

@export var pattern: Pattern = Pattern.NONE
## Alpha 0 = plane keeps its own color there.
@export var color_a: Color = Color(1, 1, 1, 0)
@export var color_b: Color = Color(1, 1, 1, 1)
## Pattern cell size in sprite pixels.
@export_range(4.0, 64.0, 1.0) var cell_px: float = 18.0
@export_range(0.0, 1.0, 0.05) var strength: float = 0.75


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.PAINT
