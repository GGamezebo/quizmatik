extends Control

@export var gold_label: Label
@export var cards_row: HBoxContainer
@export var card_scene: PackedScene
@export var root_events: RootEvents
@export var progress: ProgressController

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if root_events != null:
		_listener.add(root_events.ev_profiles_changed, _rebuild)


func _exit_tree() -> void:
	_listener.deinit()


func on_window_enter() -> void:
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
	if cards_row == null or card_scene == null:
		return
	_ensure_cards()
	var index := 0
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
		index += 1


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
