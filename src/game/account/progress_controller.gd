class_name ProgressController
extends Node

signal ev_container_seen(container_id: String)
signal ev_level_seen(container_id: String, level_id: int)

@export var pdata: PData
@export var levels_config: LevelsConfig
@export var conditions: Script
@export var root_events: RootEvents


static func find_in_tree(tree: SceneTree) -> ProgressController:
	if tree == null:
		return null
	return tree.root.find_child("ProgressController", true, false) as ProgressController


func save() -> void:
	root_events.ev_save_progress.emit()

## Whole tutorial done (pre-tutorial saves: set by SaveData v4 migration).
func is_tutorial_completed() -> bool:
	return pdata.state.tutorial_completed

func complete_tutorial() -> void:
	if pdata.state.tutorial_completed:
		return
	pdata.state.tutorial_completed = true
	save()

## Tutorial chapter flags; ids are owned by the tutorial context.
func is_tutorial_step_done(step_id: String) -> bool:
	return pdata.state.tutorial_steps.get(step_id, false)

func complete_tutorial_step(step_id: String) -> void:
	if is_tutorial_step_done(step_id):
		return
	pdata.state.tutorial_steps[step_id] = true
	save()

func post_battle(battle_info: GameConfig.BattleInfo, stars: int) -> Dictionary:
	if battle_info.is_exam:
		return pass_exam(battle_info.container_id, stars)
	var level_gold := pass_level(battle_info.container_id, battle_info.level_id, stars)
	save()
	if level_gold > 0:
		return {"level_gold": level_gold}
	return {}

func is_container_unlocked(container_id: String) -> bool:
	var progress := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	if progress != null and progress.unlocked:
		return true
	var container_config = levels_config.find_container_in_config(container_id)
	if container_config:
		var unlock_condition = container_config["unlock_condition"]
		var condition_func_name = unlock_condition["name"]
		var condition_args = unlock_condition["args"]
		return conditions.call(condition_func_name, pdata, condition_args)
	return false

## Dev lab: open every valley without its unlock exam; levels inside stay sequential.
func unlock_all_containers() -> void:
	for container_data in levels_config.levels.get("containers", []):
		pdata.levels.ensure_container(str(container_data.get("container_id", ""))).unlocked = true
	save()

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

const LEVEL_GOLD_FOR_THREE_STARS: int = 1

## Returns gold earned: first time a regular level reaches 3 stars. Caller grants it.
func pass_level(container_id: String, level_id: int, stars: int) -> int:
	var entry := pdata.levels.ensure_container(container_id).ensure_level(level_id)
	var first_three_stars: bool = entry.stars < 3 and stars >= 3
	entry.stars = max(entry.stars, stars)
	return LEVEL_GOLD_FOR_THREE_STARS if first_three_stars else 0

const EXAM_LEVEL_ID: int = 17


func is_valley_exam_completed(container_id: String) -> bool:
	if container_id.is_empty():
		return false
	var container: PData.ContainerProgress = pdata.levels.containers.get(container_id)
	if container != null and container.exam_passed:
		return true
	return get_level_stars(container_id, EXAM_LEVEL_ID) >= 1


func is_trophy_unlocked(container_id: String) -> bool:
	if is_valley_exam_completed(container_id):
		pdata.trophies.unlock(container_id)
	return pdata.trophies.is_unlocked(container_id)


func sync_all_trophies_from_exams() -> void:
	var changed := false
	var container_ids: Array[String] = []
	if levels_config != null and levels_config.levels.has("containers"):
		for container_data in levels_config.levels["containers"]:
			container_ids.append(str(container_data.get("container_id", "")))
	else:
		for container_id in pdata.levels.containers:
			container_ids.append(container_id)
	for container_id in container_ids:
		if is_valley_exam_completed(container_id) and pdata.trophies.unlock(container_id):
			changed = true
	if changed:
		save()


func pass_exam(container_id: String, stars: int) -> Dictionary:
	var container := pdata.levels.ensure_container(container_id)
	var was_first_pass := not container.exam_passed
	container.exam_passed = true

	var config_levels = levels_config.find_container_in_config(container_id).get("levels", [])
	for config_level in config_levels:
		var level_id: int = config_level["level_id"]
		var entry := container.ensure_level(level_id)
		entry.stars = max(entry.stars, stars)

	if was_first_pass:
		pdata.trophies.unlock(container_id)

	var unlocked_plane_id := ""
	if was_first_pass:
		var plane_id := PlaneCatalog.plane_id_for_exam(container_id)
		if not plane_id.is_empty():
			var profiles := ProfileController.find_in_tree(get_tree())
			if profiles != null and profiles.unlock_plane(plane_id):
				unlocked_plane_id = plane_id

	save()

	if not was_first_pass:
		return {}

	var result := {
		"first_exam_pass": true,
		"container_id": container_id,
		"next_container_id": levels_config.get_next_container_id(container_id),
	}
	if not unlocked_plane_id.is_empty():
		result["unlocked_plane_id"] = unlocked_plane_id
	return result
