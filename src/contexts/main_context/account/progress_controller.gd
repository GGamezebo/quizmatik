class_name ProgressController
extends Node

@export var pdata: PDataProgress
@export var levelsConfig: LevelsConfig
@export var conditions: Script


func save() -> void:
	ResourceUtils.save_resource_to_disk(pdata, pdata.SAVE_PATH)

func post_battle(container_id: String, level_id: int, stars: int) -> void:
	var levels = pdata.progress["levels"]
	if not levels.has(container_id):
		levels[container_id] = {"completed_levels": {}, "exam_passed": false}
	
	var container_data = levels[container_id]
	var prev_stars: int = container_data["completed_levels"].get(level_id, 0)
	container_data["completed_levels"][level_id] = max(prev_stars, stars)
	save()


func is_container_unlocked(container_id: String) -> bool:
	var container_config = find_container_in_config(container_id)
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
		
	var prev_level_id = level_id - 1
	var completed_levels = container_progress.get("completed_levels", {})
	
	if completed_levels.has(prev_level_id):
		var stars = completed_levels[prev_level_id]
		return stars >= 1
		
	return false

func get_level_stars(container_id: String, level_id: int) -> int:
	var container_progress = pdata.progress["levels"].get(container_id, {})
	var stars = container_progress.get("completed_levels", {}).get(level_id, 0)
	return stars

func pass_container_exam(container_id: String, total_levels_in_pack: int) -> void:
	var levels = pdata.progress["levels"]
	if not levels.has(container_id):
		levels[container_id] = {"completed_levels": {}, "exam_passed": false}
		
	var container_data = levels[container_id]
	container_data["exam_passed"] = true
	
	for l_id in range(1, total_levels_in_pack + 1):
		if not container_data["completed_levels"].has(l_id):
			container_data["completed_levels"][l_id] = 1 # Минимальный зачет
			
	_unlock_next_container(container_id)
	save()

func _unlock_next_container(current_id: String) -> void:
	var levels = levelsConfig.levels
	if not levels.has("containers") or not (levels["containers"] is Array):
		push_error("[ProgressManager] Error: Cannot unlock next container due to invalid config format.")
		return

	var containers_list: Array = levels["containers"]
	var current_index: int = -1

	# Find the index of the currently completed container
	for i in range(containers_list.size()):
		if containers_list[i].get("container_id") == current_id:
			current_index = i
			break

	# If the current container wasn't found, we can't determine the next one
	if current_index == -1:
		push_error("[ProgressManager] Error: Current container '" + current_id + "' not found in config.")
		return

	# Check if there is a next container available in the array
	var next_index: int = current_index + 1
	if next_index < containers_list.size():
		var next_container = containers_list[next_index]
		var next_container_id: String = next_container.get("container_id", "")

		if next_container_id.is_empty():
			push_error("[ProgressManager] Error: Next container at index " + str(next_index) + " is missing a container_id.")
			return
	else:
		# Reached the end of the line (e.g., player finished the last available pack in the game)
		print("[ProgressManager] Info: No more containers left to unlock after '", current_id, "'.")
	

func find_container_in_config(container_id: String) -> Dictionary:
	var levels = levelsConfig.levels
	if not levels.has("containers") or not (levels["containers"] is Array):
		push_error("[ProgressManager] Error: Invalid level configuration format.")
		return {}

	for container in levels["containers"]:
		if container.get("container_id") == container_id:
			return container

	push_warning("[ProgressManager] Warning: Container '" + container_id + "' not found in configuration.")
	return {}
