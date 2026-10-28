class_name ShotItem
extends CosmeticItem

## Shot look: projectile tint + ink drips it leaves on the paper (`InkBlot`) + hit flash tint.

## Drip colors picked at random. Empty → classic blue-black fountain ink.
@export var ink_colors: PackedColorArray = PackedColorArray()
## Drip sprite sheet. Null → ink blot atlas of the background.
@export var drip_texture: Texture2D
@export var drip_frames: Vector2i = Vector2i(1, 1)
@export_range(0.05, 1.0, 0.01) var drip_scale_min: float = 0.12
@export_range(0.05, 1.0, 0.01) var drip_scale_max: float = 0.38
## Max random tilt (radians) of a shaped drip. Math signs keep it low: a tilted + must not read as ×.
@export_range(0.0, 1.0, 0.01) var drip_tilt: float = 0.35
## Path distance between drips; 0 → the shot's own `ink_spacing`. Signs need gaps to stay readable.
@export_range(0.0, 120.0, 1.0) var drip_spacing: float = 0.0
@export var shot_tint: Color = Color(1, 1, 1, 1)


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.SHOT


func pick_ink_color() -> Color:
	if ink_colors.is_empty():
		return classic_ink()
	var base: Color = ink_colors[randi() % ink_colors.size()]
	return Color(base.r, base.g, base.b, base.a * randf_range(0.7, 1.0))


## Source rect of drip sheet frame `index` (wraps over `drip_frames`).
func drip_region(index: int) -> Rect2:
	var cells := Vector2i(maxi(1, drip_frames.x), maxi(1, drip_frames.y))
	var cell := drip_texture.get_size() / Vector2(cells)
	var frame := posmod(index, cells.x * cells.y)
	return Rect2(Vector2(frame % cells.x, floorf(float(frame) / cells.x)) * cell, cell)


## Classic blue-black fountain ink, slightly uneven soak.
static func classic_ink() -> Color:
	return Color(
		randf_range(0.06, 0.14),
		randf_range(0.10, 0.18),
		randf_range(0.22, 0.38),
		randf_range(0.55, 0.88),
	)
