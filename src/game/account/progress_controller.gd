class_name ProgressController
extends Node

signal ev_container_seen(container_id: String)
signal ev_level_seen(container_id: String, level_id: int)

@export var pdata: PData
@export var levels_config: LevelsConfig
@export var conditions: Script
@export var root_events: RootEvents


func save() -> void:
	root_events.ev_save_progress.emit()

func post_battle(battle_info: GameConfig.BattleInfo, stars: int) -> void:
	if battle_info.is_exam:
		pass_exam(battle_info.container_id, stars)
	else:
		pass_level(battle_info.container_id, battle_info.level_id, stars)
	save()

func is_container_unlocked(container_id: String) -> bool:
	var container_config = levels_config.find_container_in_config(container_id)
	if container_config:
		var unlock_condition = container_config["unlock_condition"]
		var condition_func_name = unlock_condition["name"]
		var condition_args = unlock_condition["args"]
		return conditions.call(condition_func_name, pdata, condition_args)
	return false

func is_container_seen(container_id: String) -> bool:
	if not pdata.levels.containers.has(container_id):
		return false
	return pdata.levels.containers[container_id].seen

func mark_container_seen(container_id: String) -> bool:
	if is_container_seen(container_id):
		return false
	pdata.levels.ensure_container(container_id).seen = true
	print("[Progress] Container seen: %s" % container_id)
	ev_container_seen.emit(container_id)
	save()
	return true

func is_level_seen(container_id: String, level_id: int) -> bool:
	if not pdata.levels.containers.has(container_id):
		return false
	var completed: Dictionary = pdata.levels.containers[container_id].completed_levels
	if not completed.has(level_id):
		return false
	return completed[level_id].seen

func mark_level_seen(container_id: String, level_id: int) -> bool:
	if is_level_seen(container_id, level_id):
		return false
	pdata.levels.ensure_container(container_id).ensure_level(level_id).seen = true
	print("[Progress] Level seen: %s / %d" % [container_id, level_id])
	ev_level_seen.emit(container_id, level_id)
	save()
	return true

func is_level_unlocked(container_id: String, level_id: int) -> bool:
	if not is_container_unlocked(container_id):
		return false

	var container := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	if container == null:
		container = PData.ContainerProgress.new()

	if container.exam_passed:
		return true

	if level_id == 1:
		return true

	if levels_config.is_level_exam(container_id, level_id):
		return true

	var prev_level_id := level_id - 1
	if container.completed_levels.has(prev_level_id):
		return container.completed_levels[prev_level_id].stars >= 1

	return false

func are_all_regular_levels_completed(container_id: String) -> bool:
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	if container_config.is_empty():
		return false

	var container := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	var completed: Dictionary = {}
	if container != null:
		completed = container.completed_levels
	for level in container_config["levels"]:
		if level.get("is_exam", false):
			continue
		var level_id: int = level["level_id"]
		if not completed.has(level_id) or completed[level_id].stars < 1:
			return false
	return true

func get_level_stars(container_id: String, level_id: int) -> int:
	if not pdata.levels.containers.has(container_id):
		return 0
	var completed: Dictionary = pdata.levels.containers[container_id].completed_levels
	if not completed.has(level_id):
		return 0
	return completed[level_id].stars

func pass_level(container_id: String, level_id: int, stars: int) -> void:
	var entry := pdata.levels.ensure_container(container_id).ensure_level(level_id)
	entry.stars = max(entry.stars, stars)

func pass_exam(container_id: String, stars: int) -> void:
	var container := pdata.levels.ensure_container(container_id)
	container.exam_passed = true

	var config_levels = levels_config.find_container_in_config(container_id).get("levels", [])
	for config_level in config_levels:
		var level_id: int = config_level["level_id"]
		var entry := container.ensure_level(level_id)
		entry.stars = max(entry.stars, stars)
