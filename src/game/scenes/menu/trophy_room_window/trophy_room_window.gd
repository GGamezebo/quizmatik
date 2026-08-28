extends Control

@export var pdata: PData
@export var progress: ProgressController
@export var levels_config: LevelsConfig
@export var stats_list: VBoxContainer
@export var trophies_list: HBoxContainer
@export var extra_list: HBoxContainer
@export var stat_row_scene: PackedScene
@export var trophy_slot_scene: PackedScene
@export var extra_slot_scene: PackedScene


func on_window_enter() -> void:
	if progress != null:
		progress.sync_all_trophies_from_exams()
	_rebuild_trophies()
	_rebuild_stats()
	_rebuild_extra()


func _live_pdata() -> PData:
	if progress != null and progress.pdata != null:
		return progress.pdata
	return pdata


func _rebuild_trophies() -> void:
	if trophies_list == null or trophy_slot_scene == null:
		return

	for child in trophies_list.get_children():
		trophies_list.remove_child(child)
		child.free()

	for container_id in ValleyTrophyArt.get_container_ids():
		var is_unlocked := false
		if progress != null:
			is_unlocked = progress.is_trophy_unlocked(container_id)
		else:
			is_unlocked = _is_exam_completed_fallback(container_id)
		var slot: TrophySlot = trophy_slot_scene.instantiate() as TrophySlot
		slot.initialize(
			container_id,
			is_unlocked,
			_count_completed_levels(container_id),
			_total_levels(container_id),
		)
		trophies_list.add_child(slot)


func _is_exam_completed_fallback(container_id: String) -> bool:
	var live := _live_pdata()
	if live == null:
		return false
	var container: PData.ContainerProgress = live.levels.containers.get(container_id)
	if container != null and container.exam_passed:
		return true
	if container != null and container.completed_levels.has(17):
		return container.completed_levels[17].stars >= 1
	return false


func _rebuild_stats() -> void:
	var live := _live_pdata()
	if live == null or stats_list == null or stat_row_scene == null:
		return

	for child in stats_list.get_children():
		stats_list.remove_child(child)
		child.free()

	var stats: Dictionary = live.statistics.to_dict()
	for row_data in ProgressStatistics.DISPLAY_ROWS:
		var key: String = row_data[0]
		var title: String = row_data[1]
		var row: Control = stat_row_scene.instantiate()
		row.initialize(
			key,
			title,
			ProgressStatistics.format_stat_value(key, stats.get(key, 0), stats),
		)
		stats_list.add_child(row)


func _rebuild_extra() -> void:
	var live := _live_pdata()
	if live == null or extra_list == null or extra_slot_scene == null:
		return

	for child in extra_list.get_children():
		extra_list.remove_child(child)
		child.free()

	var stats: Dictionary = live.statistics.to_dict()
	for row_data in ProgressStatistics.EXTRA_ROWS:
		var key: String = row_data[0]
		var title: String = row_data[1]
		var subtitle_fmt: String = row_data[2]
		var value_text := ProgressStatistics.format_stat_value(key, stats.get(key, 0), stats)
		var slot: Control = extra_slot_scene.instantiate()
		slot.initialize(key, title, subtitle_fmt % value_text)
		extra_list.add_child(slot)


func _count_completed_levels(container_id: String) -> int:
	if levels_config == null:
		return 0
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	if container_config.is_empty():
		return 0

	var completed: Dictionary = {}
	var live := _live_pdata()
	if live != null and live.levels.containers.has(container_id):
		completed = live.levels.containers[container_id].completed_levels

	var count := 0
	for level in container_config["levels"]:
		var level_id: int = level["level_id"]
		if completed.has(level_id) and completed[level_id].stars >= 1:
			count += 1
	return count


func _total_levels(container_id: String) -> int:
	if levels_config == null:
		return 0
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	var levels_list: Variant = container_config.get("levels", [])
	if levels_list is Array:
		return levels_list.size()
	return 0
