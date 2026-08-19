extends Control

@export var carousel: LevelsPackCarousel
@export var level_container_scene: PackedScene
@export var levelsConfig: LevelsConfig
@export var progress: ProgressController
@export var windows_stack_manager: WindowStackManager
@export var level_selection_window: Control

var _container_ids: Array[String] = []


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	if carousel != null:
		carousel.ev_pack_activated.connect(_on_pack_activated)
	_update_window()


func on_window_enter() -> void:
	_update_window()


func _update_window() -> void:
	var previous_id := ""
	if _selected_index_valid():
		previous_id = _container_ids[carousel.selected_index]

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
		var completed_count := _count_completed_levels(container_id)
		var total_count := _total_levels(container)
		var exam_level_id := 17
		var exam_stars := 0
		if levelsConfig.is_level_exam(container_id, exam_level_id):
			exam_stars = progress.get_level_stars(container_id, exam_level_id)
		container_instance.initialize(
			container_id,
			container["name"],
			is_unlocked,
			completed_count,
			total_count,
			exam_stars,
		)
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


func _selected_index_valid() -> bool:
	return (
		carousel != null
		and carousel.selected_index >= 0
		and carousel.selected_index < _container_ids.size()
	)


func _count_completed_levels(container_id: String) -> int:
	var container_config: Dictionary = levelsConfig.find_container_in_config(container_id)
	if container_config.is_empty():
		return 0

	var completed: Dictionary = {}
	if progress.pdata.levels.containers.has(container_id):
		completed = progress.pdata.levels.containers[container_id].completed_levels

	var count := 0
	for level in container_config["levels"]:
		var level_id: int = level["level_id"]
		if completed.has(level_id) and completed[level_id].stars >= 1:
			count += 1
	return count


func _total_levels(container: Dictionary) -> int:
	var levels_list: Variant = container.get("levels", [])
	if levels_list is Array:
		return levels_list.size()
	return 0


func _on_pack_activated(index: int) -> void:
	if index < 0 or index >= _container_ids.size():
		return
	var container_id := _container_ids[index]
	if not progress.is_container_unlocked(container_id):
		return
	_on_pack_enter_requested(container_id)


func _on_pack_enter_requested(container_id: String) -> void:
	level_selection_window.initialize(container_id)
	windows_stack_manager.open_stacked_window(level_selection_window)


func open_level_select(container_id: String) -> void:
	windows_stack_manager.open_stacked_window(self)
	_on_pack_enter_requested(container_id)


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_update_window()
