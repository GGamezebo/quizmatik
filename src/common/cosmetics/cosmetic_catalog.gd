class_name CosmeticCatalog
extends Resource

## Every look item for sale. Order in `items` = order in the hangar.
## Equipped ids live per profile in `PData.cosmetics`; resolve them here.
## Seasonal event items (`events`) go on sale with the first run of their event (`shop_items_for`).

@export var items: Array[CosmeticItem] = []
@export var events: EventCalendar


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


## Shop cards of the slot: `items_for` minus event items whose event never started yet (`unix` -1 = now).
func shop_items_for(slot: CosmeticItem.Slot, unix: int = -1) -> Array[CosmeticItem]:
	var result: Array[CosmeticItem] = []
	for item in items_for(slot):
		if is_on_sale(item, unix):
			result.append(item)
	return result


func is_on_sale(item: CosmeticItem, unix: int = -1) -> bool:
	return item != null and (events == null or events.is_released(item.id, unix))


## Some paid item on sale, not in `owned`, costs at most `gold`.
func has_affordable(gold: int, owned: Array) -> bool:
	for item in items:
		if item != null and item.gold_cost > 0 and item.gold_cost <= gold and not owned.has(item.id) and is_on_sale(item):
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
