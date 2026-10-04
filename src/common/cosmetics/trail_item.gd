class_name TrailItem
extends CosmeticItem

## Line behind the plane (`PlaneFlyerTrail`), battle and showcases.

enum Style { NONE, DOTS, CRAYON, DASH, RAINBOW }

@export var style: Style = Style.NONE
## Extra colors cycle per dot (colored pencils). Empty → `color` only.
@export var color: Color = Color(0.165, 0.2, 0.251, 0.75)
@export var palette: PackedColorArray = PackedColorArray()
@export_range(1.0, 16.0, 0.5) var width: float = 4.0
@export_range(6.0, 60.0, 1.0) var spacing: float = 22.0


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.TRAIL
