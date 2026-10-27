class_name CosmeticsPage
extends Control

## Hangar «ПОКРАСКА» tab: category chips → paged item cards → try-on preview → one buy / equip button.
## A page = `page_size` cards (swipe / wheel / arrows / dots); the slot opens on the page of what the pilot wears.
## Mutations go through `CosmeticsController`; isolated run (no AppRoot) = read-only showcase.

@export var pdata: PData
@export var catalog: CosmeticCatalog
@export var card_scene: PackedScene
## One toggle button per `CosmeticItem.Slot`, same order.
@export var category_buttons: Array[Button] = []
@export var grid: GridContainer
## Marks one card worth trying on (not selected; affordable first) for overlays (tutorial shop tour).
## Every not-selected card of the page is also marked as `<anchor_id>.<item id>` (a step can name one item).
@export var item_anchor: UiAnchor
@export_group("Pager")
## Cards per page = grid columns × rows.
@export var page_size: int = 6
## Clipping box around `grid` (the slide animation moves the grid inside it).
@export var page_area: Control
@export var swipe: SwipeDetector
@export var prev_button: BaseButton
@export var next_button: BaseButton
@export var dots_container: Control
@export var dot_scene: PackedScene
@export var slide_offset: float = 70.0
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
## Selection before the current press: a swipe that starts on a card must not leave that card selected.
var _selected_at_press: CosmeticItem = null
var _page: int = 0
var _page_count: int = 1
var _cards: Array[CosmeticCard] = []
var _dots: Array[Control] = []
var _card_group: ButtonGroup = ButtonGroup.new()
var _slide_tween: Tween = null
## Per-item card anchors registered for this page: anchor id → card.
var _card_anchors: Dictionary[String, Control] = {}


func _ready() -> void:
	for index in category_buttons.size():
		category_buttons[index].pressed.connect(_select_slot.bind(index))
	if action_button:
		action_button.pressed.connect(_on_action)
	if prev_button:
		prev_button.pressed.connect(_step_page.bind(-1))
	if next_button:
		next_button.pressed.connect(_step_page.bind(1))
	if swipe:
		swipe.ev_swiped.connect(_on_swiped)
		swipe.ev_pressed.connect(_on_press_started)


func _exit_tree() -> void:
	_clear_card_anchors()


func refresh() -> void:
	if catalog == null:
		return
	if _selected == null or _selected.get_slot() != _slot:
		_selected = _equipped(_slot)
		_page = _page_of(_selected)
	_rebuild_cards()
	_update_preview()


## Back to the first slot (each shop visit starts on «Узор»).
func reset_slot() -> void:
	_slot = CosmeticItem.Slot.PAINT
	_selected = null


## Jump to `index` (clamped). `animate` slides the cards, otherwise they swap at once.
func show_page(index: int, animate: bool = true) -> void:
	var target := clampi(index, 0, _page_count - 1)
	if target == _page:
		return
	var direction := signi(target - _page)
	_page = target
	if animate and is_visible_in_tree():
		_slide(direction)
	else:
		_kill_slide()
		_rebuild_cards()


func _select_slot(slot: int) -> void:
	_slot = slot as CosmeticItem.Slot
	_selected = _equipped(_slot)
	_page = _page_of(_selected)
	_kill_slide()
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


func _page_of(item: CosmeticItem) -> int:
	if item == null:
		return 0
	var index := catalog.items_for(_slot).find(item)
	return floori(maxi(index, 0) / float(maxi(page_size, 1)))


func _step_page(direction: int) -> void:
	show_page(_page + direction)


func _on_press_started() -> void:
	_selected_at_press = _selected


func _on_swiped(direction: int) -> void:
	if _page_count <= 1:
		return
	if swipe.is_swiping():
		# The finger went down on a card (focus = try-on): put the old selection back.
		_selected = _selected_at_press
		_update_preview()
	show_page(_page + direction)


func _rebuild_cards() -> void:
	if grid == null or card_scene == null:
		return
	for index in category_buttons.size():
		category_buttons[index].set_pressed_no_signal(index == _slot)
	var items := catalog.items_for(_slot)
	_page_count = maxi(ceili(float(items.size()) / float(page_size)), 1)
	_page = clampi(_page, 0, _page_count - 1)
	while _cards.size() < page_size:
		var card: CosmeticCard = card_scene.instantiate()
		card.button_group = _card_group
		card.ev_selected.connect(_on_card_selected)
		grid.add_child(card)
		_cards.append(card)
	var page_items: Array[CosmeticItem] = []
	for index in _cards.size():
		var card := _cards[index]
		var item_index := _page * page_size + index
		card.visible = item_index < items.size()
		if not card.visible:
			continue
		var item := items[item_index]
		page_items.append(item)
		card.setup(item, pdata.equipped_plane_id, _is_owned(item), item == _equipped(_slot))
		card.set_pressed_no_signal(item == _selected)
	_mark_item_anchor(page_items)
	_update_pager()


## Not-selected card on this page: affordable not-owned → any not-owned → any.
func _mark_item_anchor(page_items: Array[CosmeticItem]) -> void:
	if item_anchor == null:
		return
	_clear_card_anchors()
	var best := -1
	var best_rank := -1
	for index in page_items.size():
		var item := page_items[index]
		if item == _selected:
			continue
		_mark_card("%s.%s" % [item_anchor.anchor_id, item.id], _cards[index])
		var rank := 0
		if not _is_owned(item):
			rank = 2 if item.gold_cost <= pdata.gold else 1
		if rank > best_rank:
			best_rank = rank
			best = index
	item_anchor.set_target(_cards[best] if best >= 0 else null)


func _mark_card(anchor_id: String, card: Control) -> void:
	if item_anchor.registry == null:
		return
	item_anchor.registry.register(anchor_id, card)
	_card_anchors[anchor_id] = card


func _clear_card_anchors() -> void:
	if item_anchor != null and item_anchor.registry != null:
		for anchor_id in _card_anchors:
			item_anchor.registry.unregister(anchor_id, _card_anchors[anchor_id])
	_card_anchors.clear()


func _update_pager() -> void:
	var paged := _page_count > 1
	# Dimmed, never `disabled`: the theme's disabled style is a plain grey box.
	if prev_button:
		prev_button.visible = paged
		prev_button.modulate.a = 0.35 if _page <= 0 else 1.0
	if next_button:
		next_button.visible = paged
		next_button.modulate.a = 0.35 if _page >= _page_count - 1 else 1.0
	if dots_container == null or dot_scene == null:
		return
	dots_container.visible = paged
	while _dots.size() < _page_count:
		var dot := dot_scene.instantiate() as Control
		dots_container.add_child(dot)
		dot.connect("ev_pressed", _dot_pressed.bind(dot))
		_dots.append(dot)
	for index in _dots.size():
		_dots[index].visible = index < _page_count
		_dots[index].call("set_current", index == _page)


func _dot_pressed(dot: Control) -> void:
	show_page(_dots.find(dot))


func _slide(direction: int) -> void:
	_kill_slide()
	_slide_tween = create_tween()
	_slide_tween.tween_property(grid, "modulate:a", 0.0, 0.07)
	_slide_tween.parallel().tween_property(grid, "position:x", -direction * slide_offset, 0.07)
	_slide_tween.tween_callback(_slide_swap.bind(direction))
	_slide_tween.tween_property(grid, "modulate:a", 1.0, 0.14)
	_slide_tween.parallel().tween_property(grid, "position:x", 0.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _slide_swap(direction: int) -> void:
	_rebuild_cards()
	grid.position.x = direction * slide_offset


func _kill_slide() -> void:
	if _slide_tween != null:
		_slide_tween.kill()
		_slide_tween = null
	if grid != null:
		grid.modulate.a = 1.0
		grid.position.x = 0.0


func _on_card_selected(item: CosmeticItem) -> void:
	if swipe != null and swipe.is_swiping():
		# Release of a swipe that started on a card, not a tap.
		_sync_cards()
		return
	if _selected == item:
		return
	_selected = item
	_update_preview()


func _sync_cards() -> void:
	for card in _cards:
		if card.visible:
			card.set_pressed_no_signal(card.item == _selected)


func _update_preview() -> void:
	var plane_id := pdata.equipped_plane_id
	var on_plane := _slot in [CosmeticItem.Slot.PAINT, CosmeticItem.Slot.TRAIL, CosmeticItem.Slot.SHOT]
	flyer_view.visible = on_plane
	shot_swatch.visible = _slot in [CosmeticItem.Slot.TRAIL, CosmeticItem.Slot.SHOT]
	photo_box.visible = _slot in [CosmeticItem.Slot.STICKER, CosmeticItem.Slot.FRAME]
	cover_icon.visible = _slot == CosmeticItem.Slot.COVER
	if on_plane:
		flyer.apply_plane(plane_id)
		flyer.apply_paint(_shown(CosmeticItem.Slot.PAINT) as PaintItem)
		flyer.apply_trail(_shown(CosmeticItem.Slot.TRAIL) as TrailItem)
		shot_swatch.set_item(_shown(CosmeticItem.Slot.TRAIL if _slot == CosmeticItem.Slot.TRAIL else CosmeticItem.Slot.SHOT))
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
	_sync_cards()
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
		action_button.text = tr("НУЖНО ЕЩЁ %d") % missing
		action_button.disabled = true
	else:
		action_button.text = tr("КУПИТЬ ЗА %d") % _selected.gold_cost
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
