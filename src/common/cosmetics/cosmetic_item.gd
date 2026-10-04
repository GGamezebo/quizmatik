class_name CosmeticItem
extends Resource

## One look item bought with gold. Pure visuals: never changes speed, aim or damage.
## Price 0 = owned by every profile (slot default).

enum Slot { PAINT, TRAIL, SHOT, STICKER, FRAME, COVER }

## Save keys per slot (`PData.cosmetics.equipped`). Never rename.
const SLOT_KEYS: Array[String] = ["paint", "trail", "shot", "sticker", "frame", "cover"]

@export var id: String = ""
@export var title: String = ""
@export var gold_cost: int = 0
## Optional card preview (stickers / covers). Paint / trail / shot cards draw their own preview.
@export var icon: Texture2D


func get_slot() -> Slot:
	return Slot.PAINT


static func slot_key(slot: Slot) -> String:
	return SLOT_KEYS[slot]
