class_name PaintItem
extends CosmeticItem

## Procedural pattern over the plane body (`plane_body.gdshader`). Outline + sticker edge stay.
## New looks (seasonal events) need no shader code: `TEXTURE` tiles `pattern_texture`.

enum Pattern { NONE, STRIPES, DOTS, CHECKER, STARS, ZIGZAG, WATERCOLOR, RAINBOW, MATH, TIGER, GIRAFFE, DIAMONDS, SCALES, GALAXY, PUMPKIN, WEB, TEXTURE }

@export var pattern: Pattern = Pattern.NONE
## Alpha 0 = plane keeps its own color there.
@export var color_a: Color = Color(1, 1, 1, 0)
@export var color_b: Color = Color(1, 1, 1, 1)
## Pattern cell size in sprite pixels.
@export_range(4.0, 64.0, 1.0) var cell_px: float = 18.0
@export_range(0.0, 1.0, 0.05) var strength: float = 0.75
@export_group("Texture pattern")
## `TEXTURE` only: one seamless tile per `cell_px` square. White (× alpha) = `color_b`, the rest `color_a`.
@export var pattern_texture: Texture2D
## `TEXTURE`: paint the tile's own colors (its alpha = coverage) instead of the two-color mask.
@export var texture_colors: bool = false


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.PAINT
