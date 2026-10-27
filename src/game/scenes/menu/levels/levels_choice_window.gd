extends Control

@export var carousel: LevelsPackCarousel
@export var level_container_scene: PackedScene
@export var levelsConfig: LevelsConfig
@export var progress: ProgressController
@export var windows_stack_manager: WindowStackManager
@export var level_selection_window: Control
@export var background_host: BackgroundHost
## Monetization hook: paid valleys (default board = none).
@export var offer_board: OfferBoard

var _container_ids: Array[String] = []
var _listener: EventListener = EventListener.new()


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	if carousel != null:
		carousel.ev_pack_activated.connect(_on_pack_activated)
		carousel.ev_selection_changed.connect(_on_selection_changed)
	if offer_board != null:
		_listener.add(offer_board.ev_changed, _on_offers_changed)
	_update_window()


func _exit_tree() -> void:
	_listener.deinit()


func on_window_enter() -> void:
	_set_pack_chrome_visible(true)
	_update_window()


func _update_window() -> void:
	var previous_id := progress.get_last_container_id()

	if carousel != null:
		carousel.clear_packs()
	_container_ids.clear()

	var levels = levelsConfig.levels
	if not levels.has("containers") or not (levels["containers"] is Array):
		push_error("[PacksMenu] Error: Invalid levels configuration data.")
		return

	for container_data in levels["containers"]:
		var container_id: String = container_data.get("container_id", "")
		if container_id.is_empty():
			continue

		var container_instance: LevelContainer = level_container_scene.instantiate()
		var is_unlocked: bool = progress.is_container_unlocked(container_id)
		var container: Dictionary = levelsConfig.find_container_in_config(container_id)
		var completed_count := progress.completed_levels_count(container_id)
		var total_count := _total_levels(container)
		var exam_level_id := levelsConfig.get_exam_level_id(container_id)
		var exam_stars := 0
		if exam_level_id > 0:
			exam_stars = progress.get_level_stars(container_id, exam_level_id)
		container_instance.initialize(
			container_id,
			container["name"],
			is_unlocked,
			completed_count,
			total_count,
			exam_stars,
		)
		container_instance.set_paywalled(_is_paywalled(container_id))
		container_instance.set_record(progress.pdata.statistics.endless_best(container_id)
				if progress.is_valley_record_unlocked(container_id) else -1)
		container_instance.set_expert(progress.is_expert_unlocked(container_id), progress.is_expert(container_id))
		if is_unlocked:
			progress.mark_container_seen(container_id)
		carousel.add_pack(container_instance)
		_container_ids.append(container_id)

	var start_index := 0
	if not previous_id.is_empty():
		var found := _container_ids.find(previous_id)
		if found >= 0:
			start_index = found
	carousel.finalize(start_index)
	_update_background_for_index(start_index)


func _total_levels(container: Dictionary) -> int:
	var levels_list: Variant = container.get("levels", [])
	if levels_list is Array:
		return levels_list.size()
	return 0


func _on_pack_activated(index: int) -> void:
	if index < 0 or index >= _container_ids.size():
		return
	var container_id := _container_ids[index]
	if _is_paywalled(container_id):
		offer_board.ev_paywall_requested.emit(&"valley", container_id)
		return
	if not progress.is_container_unlocked(container_id):
		return
	_on_pack_enter_requested(container_id)


func _on_pack_enter_requested(container_id: String) -> void:
	progress.set_last_container_id(container_id)
	_update_background_for_container(container_id)
	_set_pack_chrome_visible(false)
	level_selection_window.initialize(container_id)
	windows_stack_manager.open_stacked_window(level_selection_window)


func open_level_select(container_id: String) -> void:
	windows_stack_manager.open_stacked_window(self)
	_on_pack_enter_requested(container_id)


func _is_paywalled(container_id: String) -> bool:
	return offer_board != null and offer_board.is_container_paywalled(container_id, StringName(progress.pdata.difficulty))


## Purchase / store state changed while the carousel is open → redraw locks.
func _on_offers_changed() -> void:
	if is_visible_in_tree():
		_update_window()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_update_window()


func _on_selection_changed(index: int) -> void:
	_update_background_for_index(index)
	if index >= 0 and index < _container_ids.size():
		progress.set_last_container_id(_container_ids[index])


func _update_background_for_index(index: int) -> void:
	if index < 0 or index >= _container_ids.size():
		return
	_update_background_for_container(_container_ids[index])


func _update_background_for_container(container_id: String) -> void:
	if background_host == null:
		return
	background_host.force_variant(ValleyBackgroundArt.get_scene(container_id))


func _set_pack_chrome_visible(show_chrome: bool) -> void:
	for child in get_children():
		if child == background_host or child == level_selection_window:
			continue
		if child is CanvasItem:
			(child as CanvasItem).visible = show_chrome
