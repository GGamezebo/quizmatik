class_name CosmeticCatalog
extends Resource

## Every look item for sale. Order in `items` = order in the hangar.
## Equipped ids live per profile in `PData.cosmetics`; resolve them here.

@export var items: Array[CosmeticItem] = []


func get_item(item_id: String) -> CosmeticItem:
	for item in items:
		if item != null and item.id == item_id:
			return item
	return null


func items_for(slot: CosmeticItem.Slot) -> Array[CosmeticItem]:
	var result: Array[CosmeticItem] = []
	for item in items:
		if item != null and item.get_slot() == slot:
			result.append(item)
	return result


## Some paid item not in `owned` costs at most `gold`.
func has_affordable(gold: int, owned: Array) -> bool:
	for item in items:
		if item != null and item.gold_cost > 0 and item.gold_cost <= gold and not owned.has(item.id):
			return true
	return false


## First free item of the slot (what a fresh profile wears).
func default_for(slot: CosmeticItem.Slot) -> CosmeticItem:
	for item in items_for(slot):
		if item.gold_cost <= 0:
			return item
	return null


## Item worn in `slot` per a profile's `PData.cosmetics.equipped` (slot key → id).
func equipped_item(slot: CosmeticItem.Slot, equipped: Dictionary) -> CosmeticItem:
	return resolve(slot, String(equipped.get(CosmeticItem.slot_key(slot), "")))


## Equipped id → item; unknown / empty / wrong slot → slot default.
func resolve(slot: CosmeticItem.Slot, item_id: String) -> CosmeticItem:
	var item := get_item(item_id)
	if item != null and item.get_slot() == slot:
		return item
	return default_for(slot)
