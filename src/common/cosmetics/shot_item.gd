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
@export var shot_tint: Color = Color(1, 1, 1, 1)


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.SHOT


func pick_ink_color() -> Color:
	if ink_colors.is_empty():
		return classic_ink()
	var base: Color = ink_colors[randi() % ink_colors.size()]
	return Color(base.r, base.g, base.b, base.a * randf_range(0.7, 1.0))


## Classic blue-black fountain ink, slightly uneven soak.
static func classic_ink() -> Color:
	return Color(
		randf_range(0.06, 0.14),
		randf_range(0.10, 0.18),
		randf_range(0.22, 0.38),
		randf_range(0.55, 0.88),
	)
