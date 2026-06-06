class_name ProgressController
extends Node

@export var pdata: PDataProgress
@export var levels_config: LevelsConfig
@export var conditions: Script


func save() -> void:
	ResourceUtils.save_resource_to_disk(pdata, pdata.SAVE_PATH)

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


func is_level_unlocked(container_id: String, level_id: int) -> bool:
	if not is_container_unlocked(container_id):
		return false
		
	var container_progress = pdata.progress["levels"].get(container_id, {})
	
	if container_progress.get("exam_passed", false):
		return true
		
	if level_id == 1:
		return true
	
	if levels_config.is_level_exam(container_id, level_id):
		return true
		
	var prev_level_id = level_id - 1
	var completed_levels = container_progress.get("completed_levels", {})
	
	if completed_levels.has(prev_level_id):
		var stars = completed_levels[prev_level_id]
		return stars >= 1
		
	return false

func are_all_regular_levels_completed(container_id: String) -> bool:
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	if container_config.is_empty():
		return false

	var completed_levels: Dictionary = pdata.progress["levels"].get(container_id, {}).get("completed_levels", {})
	for level in container_config["levels"]:
		if level.get("is_exam", false):
			continue
		var level_id: int = level["level_id"]
		if completed_levels.get(level_id, 0) < 1:
			return false
	return true


func get_level_stars(container_id: String, level_id: int) -> int:
	var container_progress = pdata.progress["levels"].get(container_id, {})
	var stars = container_progress.get("completed_levels", {}).get(level_id, 0)
	return stars

func pass_level(container_id: String, level_id: int, stars: int) -> void:
	var levels = pdata.progress["levels"]
	if not levels.has(container_id):
		levels[container_id] = {"completed_levels": {}, "exam_passed": false}
	
	var container_data = levels[container_id]
	var prev_stars: int = container_data["completed_levels"].get(level_id, 0)
	container_data["completed_levels"][level_id] = max(prev_stars, stars)

func pass_exam(container_id: String, stars: int) -> void:
	var levels = pdata.progress["levels"]
	if not levels.has(container_id):
		levels[container_id] = {"completed_levels": {}, "exam_passed": false}
		
	var container_data = levels[container_id]
	container_data["exam_passed"] = true
	
	var config_levels = levels_config.find_container_in_config(container_id).get("levels", [])
	for config_level in config_levels:
		var level_id: int = config_level['level_id']
		var prev_stars: int = container_data["completed_levels"].get(level_id, 0)
		container_data["completed_levels"][level_id] = max(prev_stars, stars)
