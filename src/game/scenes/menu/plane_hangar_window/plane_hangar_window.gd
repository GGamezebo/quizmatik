extends Control

@export var gold_label: Label
@export var cards_row: HBoxContainer
@export var card_scene: PackedScene
@export var root_events: RootEvents
@export var progress: ProgressController
## Marks the first affordable "buy" button for overlays (tutorial).
@export var buy_anchor: UiAnchor
## «САМОЛЁТЫ» / «ПОКРАСКА» tabs. Opens on paint (shop); `planes_entry_buttons` (profile plane strip,
## tutorial `hangar.buy`) open it on planes instead.
@export var planes_tab: BaseButton
@export var paint_tab: BaseButton
@export var planes_page: Control
@export var paint_page: CosmeticsPage
@export var planes_entry_buttons: Array[BaseButton] = []

var _next_tab_paint: bool = true

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if root_events != null:
		_listener.add(root_events.ev_profiles_changed, _rebuild)
	if planes_tab:
		planes_tab.pressed.connect(_show_tab.bind(false))
	if paint_tab:
		paint_tab.pressed.connect(_show_tab.bind(true))
	for button in planes_entry_buttons:
		if button != null:
			button.pressed.connect(_open_on_tab.bind(false))


func _exit_tree() -> void:
	_listener.deinit()


func on_window_enter() -> void:
	_show_tab(_next_tab_paint)
	_next_tab_paint = true


## Entry buttons may fire before or after the stack opens the window.
func _open_on_tab(paint: bool) -> void:
	_next_tab_paint = paint
	if is_visible_in_tree():
		on_window_enter()


func _show_tab(paint: bool) -> void:
	if planes_tab:
		planes_tab.set_pressed_no_signal(not paint)
	if paint_tab:
		paint_tab.set_pressed_no_signal(paint)
	if planes_page:
		planes_page.visible = not paint
	if paint_page:
		paint_page.visible = paint
	_rebuild()


func _profiles() -> ProfileController:
	return ProfileController.find_in_tree(get_tree())


func _rebuild() -> void:
	var profiles := _profiles()
	var gold := 0
	var equipped := PlaneCatalog.STARTER_ID
	if profiles != null and profiles.pdata != null:
		gold = profiles.pdata.gold
		equipped = profiles.equipped_plane_id()
	if gold_label:
		gold_label.text = str(gold)
	if paint_page != null and paint_page.visible:
		paint_page.refresh()
	if cards_row == null or card_scene == null:
		return
	_ensure_cards()
	var index := 0
	var buy_button: Control = null
	for plane_id in PlaneCatalog.ORDER:
		var card: Control = cards_row.get_child(index)
		var unlocked := plane_id == PlaneCatalog.STARTER_ID
		if profiles != null:
			unlocked = profiles.is_plane_unlocked(plane_id)
		var exam_id := String(PlaneCatalog.get_def(plane_id).get("exam_container_id", ""))
		var exam_passed := false
		if progress != null and not exam_id.is_empty():
			exam_passed = progress.is_valley_exam_completed(exam_id)
		card.setup(plane_id, unlocked, plane_id == equipped, gold, exam_passed)
		if buy_button == null and not unlocked and not card.action_button.disabled:
			buy_button = card.action_button
		index += 1
	if buy_anchor != null:
		buy_anchor.set_target(buy_button)


func _ensure_cards() -> void:
	if cards_row.get_child_count() > 0:
		return
	for plane_id in PlaneCatalog.ORDER:
		var card: Control = card_scene.instantiate()
		card.ev_buy.connect(_on_buy)
		card.ev_equip.connect(_on_equip)
		cards_row.add_child(card)


func _on_buy(plane_id: String) -> void:
	var profiles := _profiles()
	if profiles == null:
		return
	if profiles.try_buy_plane(plane_id) and root_events != null:
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_PLANE, {"plane_id": plane_id})


func _on_equip(plane_id: String) -> void:
	var profiles := _profiles()
	if profiles == null:
		return
	profiles.equip_plane(plane_id)
