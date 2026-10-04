class_name CoverItem
extends CosmeticItem

## Main menu background. Scene root must be `BackgroundBase` (mounted by `BackgroundHost`).

@export var scene: PackedScene


func get_slot() -> CosmeticItem.Slot:
	return CosmeticItem.Slot.COVER
