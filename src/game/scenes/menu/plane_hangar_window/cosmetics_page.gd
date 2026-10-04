class_name CosmeticsPage
extends Control

## Hangar «ПОКРАСКА» tab: category chips → item cards → try-on preview → one buy / equip button.
## Mutations go through `CosmeticsController`; isolated run (no AppRoot) = read-only showcase.

@export var pdata: PData
@export var catalog: CosmeticCatalog
@export var card_scene: PackedScene
## One toggle button per `CosmeticItem.Slot`, same order.
@export var category_buttons: Array[Button] = []
@export var grid: GridContainer
@export_group("Preview")
@export var flyer_view: Control
@export var flyer: PlaneFlyer
@export var shot_swatch: CosmeticSwatch
@export var photo_box: Control
@export var photo_frame: PanelContainer
@export var photo: TextureRect
@export var photo_sticker: TextureRect
@export var cover_icon: TextureRect
@export var item_name: Label
@export var action_button: Button
@export var coin_icon: Texture2D

var _slot: CosmeticItem.Slot = CosmeticItem.Slot.PAINT
var _selected: CosmeticItem = null
var _cards: Array[CosmeticCard] = []
var _card_group: ButtonGroup = ButtonGroup.new()


func _ready() -> void:
	for index in category_buttons.size():
		category_buttons[index].pressed.connect(_select_slot.bind(index))
	if action_button:
		action_button.pressed.connect(_on_action)


func refresh() -> void:
	if catalog == null:
		return
	if _selected == null or _selected.get_slot() != _slot:
		_selected = _equipped(_slot)
	_rebuild_cards()
	_update_preview()


func _select_slot(slot: int) -> void:
	_slot = slot as CosmeticItem.Slot
	_selected = _equipped(_slot)
	_rebuild_cards()
	_update_preview()


func _controller() -> CosmeticsController:
	return CosmeticsController.find_in_tree(get_tree())


func _equipped(slot: CosmeticItem.Slot) -> CosmeticItem:
	return catalog.equipped_item(slot, pdata.cosmetics.equipped)


func _is_owned(item: CosmeticItem) -> bool:
	return item.gold_cost <= 0 or pdata.cosmetics.owned.has(item.id)


## Current slot shows the tried-on item; other slots show what the pilot wears.
func _shown(slot: CosmeticItem.Slot) -> CosmeticItem:
	if slot == _slot and _selected != null:
		return _selected
	return _equipped(slot)


func _rebuild_cards() -> void:
	if grid == null or card_scene == null:
		return
	for index in category_buttons.size():
		category_buttons[index].set_pressed_no_signal(index == _slot)
	var items := catalog.items_for(_slot)
	while _cards.size() < items.size():
		var card: CosmeticCard = card_scene.instantiate()
		card.button_group = _card_group
		card.ev_selected.connect(_on_card_selected)
		grid.add_child(card)
		_cards.append(card)
	for index in _cards.size():
		var card := _cards[index]
		card.visible = index < items.size()
		if not card.visible:
			continue
		var item := items[index]
		card.setup(item, pdata.equipped_plane_id, _is_owned(item), item == _equipped(_slot))
		card.set_pressed_no_signal(item == _selected)


func _on_card_selected(item: CosmeticItem) -> void:
	if _selected == item:
		return
	_selected = item
	_update_preview()


func _update_preview() -> void:
	var plane_id := pdata.equipped_plane_id
	var on_plane := _slot in [CosmeticItem.Slot.PAINT, CosmeticItem.Slot.TRAIL, CosmeticItem.Slot.SHOT]
	flyer_view.visible = on_plane
	shot_swatch.visible = _slot == CosmeticItem.Slot.SHOT
	photo_box.visible = _slot in [CosmeticItem.Slot.STICKER, CosmeticItem.Slot.FRAME]
	cover_icon.visible = _slot == CosmeticItem.Slot.COVER
	if on_plane:
		flyer.apply_plane(plane_id)
		flyer.apply_paint(_shown(CosmeticItem.Slot.PAINT) as PaintItem)
		flyer.apply_trail(_shown(CosmeticItem.Slot.TRAIL) as TrailItem)
		shot_swatch.set_item(_shown(CosmeticItem.Slot.SHOT))
	if photo_box.visible:
		PlaneCatalog.apply_preview(photo, plane_id, _shown(CosmeticItem.Slot.PAINT) as PaintItem)
		var frame := _shown(CosmeticItem.Slot.FRAME) as FrameItem
		if frame != null and frame.style != null:
			photo_frame.add_theme_stylebox_override("panel", frame.style)
		var sticker := _shown(CosmeticItem.Slot.STICKER) as StickerItem
		photo_sticker.visible = sticker != null and sticker.texture != null
		if photo_sticker.visible:
			photo_sticker.texture = sticker.texture
	if cover_icon.visible and _selected != null:
		cover_icon.texture = _selected.icon
	_update_action()


func _update_action() -> void:
	if _selected == null:
		return
	item_name.text = _selected.title
	action_button.icon = null
	if _is_owned(_selected):
		var worn := _selected == _equipped(_slot)
		action_button.text = "НАДЕТО" if worn else "НАДЕТЬ"
		action_button.disabled = worn
		return
	action_button.icon = coin_icon
	var missing := _selected.gold_cost - pdata.gold
	if missing > 0:
		action_button.text = "НУЖНО ЕЩЁ %d" % missing
		action_button.disabled = true
	else:
		action_button.text = "КУПИТЬ ЗА %d" % _selected.gold_cost
		action_button.disabled = _controller() == null


func _on_action() -> void:
	var controller := _controller()
	if controller == null or _selected == null:
		return
	var changed := controller.try_buy(_selected) if not _is_owned(_selected) else controller.equip(_selected)
	if changed:
		_pop(action_button)
		# Window rebuild follows `ev_profiles_changed`; refresh now so the button reacts at once.
		refresh()


func _pop(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12)
