class_name StickerItem
extends CosmeticItem

## Sticker on the pilot ID photo. Null texture = no sticker.

@export var texture: Texture2D


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.STICKER
