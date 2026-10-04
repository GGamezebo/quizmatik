class_name FrameItem
extends CosmeticItem

## Pilot ID photo frame. Null style = the scene's own polaroid style.

@export var style: StyleBox


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.FRAME
