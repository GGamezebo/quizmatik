class_name LevelsConfig
extends Resource

@export_dir var levels_dir = "res://src/levels"

var _containers_by_id: Dictionary = {}

var levels = {
   "containers": [
		{
			"container_id": "addition",
			"name": "Долина Сложения",
			"unlock_condition": {
				"name": "is_unlocked_by_default",
				"args": [],
			},
			"levels": [
				{ "level_id": 1, "config": 'level_1' },
				{ "level_id": 2, "config": 'level_2' },
				{ "level_id": 3, "config": 'level_3' },
				{ "level_id": 4, "config": 'level_4' },
				{ "level_id": 5, "config": 'level_5' },
				{ "level_id": 6, "config": 'level_6' },
				{ "level_id": 7, "config": 'level_7' },
				{ "level_id": 8, "config": 'level_8' },
				{ "level_id": 9, "config": 'level_9' },
				{ "level_id": 10, "config": 'level_10' },
				{ "level_id": 11, "config": 'level_11' },
				{ "level_id": 12, "config": 'level_12' },
				{ "level_id": 13, "config": 'level_13' },
				{ "level_id": 14, "config": 'level_14' },
				{ "level_id": 15, "config": 'level_15' },
				{ "level_id": 16, "config": 'level_16' },
				{ "level_id": 17, "config": 'level_17', 'is_exam': true },
			]
		},
		{
			"container_id": "subtraction",
			"name": "Долина Вычитания",
			"unlock_condition": {
				"name": "is_unlocked_by_exam",
				"args": ["addition"],
			},
			"levels": [
				{ "level_id": 1, "config": 'level_1' },
				{ "level_id": 2, "config": 'level_2' },
				{ "level_id": 3, "config": 'level_3' },
				{ "level_id": 4, "config": 'level_4' },
				{ "level_id": 5, "config": 'level_5' },
				{ "level_id": 6, "config": 'level_6' },
				{ "level_id": 7, "config": 'level_7' },
				{ "level_id": 8, "config": 'level_8' },
				{ "level_id": 9, "config": 'level_9' },
				{ "level_id": 10, "config": 'level_10' },
				{ "level_id": 11, "config": 'level_11' },
				{ "level_id": 12, "config": 'level_12' },
				{ "level_id": 13, "config": 'level_13' },
				{ "level_id": 14, "config": 'level_14' },
				{ "level_id": 15, "config": 'level_15' },
				{ "level_id": 16, "config": 'level_16' },
				{ "level_id": 17, "config": 'level_17', 'is_exam': true },
			]
		},
		{
			"container_id": "multiplication",
			"name": "Долина Умножения",
			"unlock_condition": {
				"name": "is_unlocked_by_exam",
				"args": ["subtraction"],
			},
			"levels": [
				{ "level_id": 1, "config": 'level_1' },
				{ "level_id": 2, "config": 'level_2' },
				{ "level_id": 3, "config": 'level_3' },
				{ "level_id": 4, "config": 'level_4' },
				{ "level_id": 5, "config": 'level_5' },
				{ "level_id": 6, "config": 'level_6' },
				{ "level_id": 7, "config": 'level_7' },
				{ "level_id": 8, "config": 'level_8' },
				{ "level_id": 9, "config": 'level_9' },
				{ "level_id": 10, "config": 'level_10' },
				{ "level_id": 11, "config": 'level_11' },
				{ "level_id": 12, "config": 'level_12' },
				{ "level_id": 13, "config": 'level_13' },
				{ "level_id": 14, "config": 'level_14' },
				{ "level_id": 15, "config": 'level_15' },
				{ "level_id": 16, "config": 'level_16' },
				{ "level_id": 17, "config": 'level_17', 'is_exam': true },
			]
		},
		{
			"container_id": "division",
			"name": "Долина Деления",
			"unlock_condition": {
				"name": "is_unlocked_by_exam",
				"args": ["multiplication"],
			},
			"levels": [
				{ "level_id": 1, "config": 'level_1' },
				{ "level_id": 2, "config": 'level_2' },
				{ "level_id": 3, "config": 'level_3' },
				{ "level_id": 4, "config": 'level_4' },
				{ "level_id": 5, "config": 'level_5' },
				{ "level_id": 6, "config": 'level_6' },
				{ "level_id": 7, "config": 'level_7' },
				{ "level_id": 8, "config": 'level_8' },
				{ "level_id": 9, "config": 'level_9' },
				{ "level_id": 10, "config": 'level_10' },
				{ "level_id": 11, "config": 'level_11' },
				{ "level_id": 12, "config": 'level_12' },
				{ "level_id": 13, "config": 'level_13' },
				{ "level_id": 14, "config": 'level_14' },
				{ "level_id": 15, "config": 'level_15' },
				{ "level_id": 16, "config": 'level_16' },
				{ "level_id": 17, "config": 'level_17', 'is_exam': true },
			]
		},
		{
			"container_id": "mix",
			"name": "Долина Смешения",
			"unlock_condition": {
				"name": "is_unlocked_by_exam",
				"args": ["division"],
			},
			"levels": [
				{ "level_id": 1, "config": 'level_1' },
				{ "level_id": 2, "config": 'level_2' },
				{ "level_id": 3, "config": 'level_3' },
				{ "level_id": 4, "config": 'level_4' },
				{ "level_id": 5, "config": 'level_5' },
				{ "level_id": 6, "config": 'level_6' },
				{ "level_id": 7, "config": 'level_7' },
				{ "level_id": 8, "config": 'level_8' },
				{ "level_id": 9, "config": 'level_9' },
				{ "level_id": 10, "config": 'level_10' },
				{ "level_id": 11, "config": 'level_11' },
				{ "level_id": 12, "config": 'level_12' },
				{ "level_id": 13, "config": 'level_13' },
				{ "level_id": 14, "config": 'level_14' },
				{ "level_id": 15, "config": 'level_15' },
				{ "level_id": 16, "config": 'level_16' },
				{ "level_id": 17, "config": 'level_17', 'is_exam': true },
			]
		}
	],
}

func _init() -> void:
	if not levels.has("containers") or not (levels["containers"] is Array):
		push_error("[LevelsConfig] Invalid level configuration format.")
		return

	for container in levels["containers"]:
		var container_id: String = container["container_id"]
		_containers_by_id[container_id] = container
		for level_data in container["levels"]:
			var config_name = level_data["config"]
			var file_name = config_name + ".tres"
			var full_path = levels_dir.path_join(container_id).path_join(file_name)

			if ResourceLoader.exists(full_path):
				level_data["config"] = ResourceLoader.load(full_path)
				print("[Loader] Level config loaded successfully for level", level_data["level_id"], ": ", full_path)
			else:
				assert(false, "[Loader] Level config not found: " + full_path)

func find_container_in_config(container_id: String) -> Dictionary:
	if not _containers_by_id.has(container_id):
		push_warning("[LevelsConfig] Container '" + container_id + "' not found.")
		return {}
	return _containers_by_id[container_id]

func get_level_config(container_id: String, level_id: int) -> GameConfig:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return null

	for level in container["levels"]:
		if level.get("level_id") == level_id:
			return level['config']

	push_warning("[ProgressManager] Warning: Level '" + str(level_id) + "' not found in container '" + container_id + "'.")
	return null

func has_level(container_id: String, level_id: int) -> bool:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return false
	for level in container["levels"]:
		if level.get("level_id") == level_id:
			return true
	return false

func get_next_container_id(container_id: String) -> String:
	if not levels.has("containers") or not (levels["containers"] is Array):
		return ""
	var containers: Array = levels["containers"]
	for i in containers.size():
		if containers[i].get("container_id") == container_id:
			if i + 1 < containers.size():
				return str(containers[i + 1].get("container_id", ""))
			return ""
	return ""

func is_level_exam(container_id: String, level_id: int) -> bool:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return false

	for level in container["levels"]:
		if level.get("level_id") == level_id:
			return level.get('is_exam', false)

	push_warning("[ProgressManager] Warning: Level '" + str(level_id) + "' not found in container '" + container_id + "'.")
	return false
