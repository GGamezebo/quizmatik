class_name CosmeticsController
extends Node

## Buy / equip look items (`CosmeticCatalog`) for the active profile (`PData.cosmetics`, gold).
## Readers resolve equipped items themselves: `catalog.equipped_item(slot, pdata.cosmetics.equipped)`.

@export var pdata: PData
@export var catalog: CosmeticCatalog
@export var root_events: RootEvents


static func find_in_tree(tree: SceneTree) -> CosmeticsController:
	if tree == null:
		return null
	return tree.root.find_child("CosmeticsController", true, false) as CosmeticsController


func is_owned(item: CosmeticItem) -> bool:
	if item == null:
		return false
	return item.gold_cost <= 0 or pdata.cosmetics.owned.has(item.id)


func equipped(slot: CosmeticItem.Slot) -> CosmeticItem:
	return catalog.equipped_item(slot, pdata.cosmetics.equipped)


func is_equipped(item: CosmeticItem) -> bool:
	return item != null and equipped(item.get_slot()) == item


func can_buy(item: CosmeticItem) -> bool:
	return item != null and not is_owned(item) and pdata.gold >= item.gold_cost


## Spends gold, keeps the item and puts it on right away.
func try_buy(item: CosmeticItem) -> bool:
	if not can_buy(item):
		return false
	pdata.gold -= item.gold_cost
	pdata.cosmetics.owned.append(item.id)
	pdata.cosmetics.equipped[CosmeticItem.slot_key(item.get_slot())] = item.id
	_save()
	return true


func equip(item: CosmeticItem) -> bool:
	if not is_owned(item) or is_equipped(item):
		return false
	pdata.cosmetics.equipped[CosmeticItem.slot_key(item.get_slot())] = item.id
	_save()
	return true


func _save() -> void:
	if root_events == null:
		return
	root_events.ev_save_progress.emit()
	# Deferred: UI must not free the card still in this call stack.
	root_events.ev_profiles_changed.emit.call_deferred()
