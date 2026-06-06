class_name LevelsConfig
extends Resource

@export_dir var levels_dir = "res://src/levels"

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
				{ "level_id": 6, "config": 'level_6', 'is_exam': true },
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
				{ "level_id": 6, "config": 'level_6', 'is_exam': true },
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
				{ "level_id": 6, "config": 'level_6', 'is_exam': true },
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
				{ "level_id": 6, "config": 'level_6', 'is_exam': true },
			]
		},
		{
			"container_id": "mix",
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
				{ "level_id": 6, "config": 'level_6', 'is_exam': true },
			]
		},
	],
}

func _init() -> void:
	for container in levels["containers"]:
		var container_id: String = container["container_id"]
		for level_data in container["levels"]:
			var config_name = level_data["config"]
			var file_name = config_name + ".tres"
			var full_path = levels_dir.path_join(container_id).path_join(file_name)
			
			if ResourceLoader.exists(full_path):
				level_data["config"] = ResourceLoader.load(full_path)
				print("[Loader] Level config loaded successfully for level", level_data["level_id"], ": ", full_path)
			else:
				assert(false, "[Loader] Файл конфигурации не найден по пути: " + full_path)

func find_container_in_config(container_id: String) -> Dictionary:
	if not levels.has("containers") or not (levels["containers"] is Array):
		push_error("[ProgressManager] Error: Invalid level configuration format.")
		return {}

	for container in levels["containers"]:
		if container.get("container_id") == container_id:
			return container

	push_warning("[ProgressManager] Warning: Container '" + container_id + "' not found in configuration.")
	return {}
	
func get_level_config(container_id: String, level_id: int) -> GameConfig:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return null
	
	for level in container["levels"]:
		if level.get("level_id") == level_id:
			return level['config']
	
	push_warning("[ProgressManager] Warning: Level '" + str(level_id) + "' not found in container '" + container_id + "'.")
	return null
	

func is_level_exam(container_id: String, level_id: int) -> bool:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return false
	
	for level in container["levels"]:
		if level.get("level_id") == level_id:
			return level.get('is_exam', false)
	
	push_warning("[ProgressManager] Warning: Level '" + str(level_id) + "' not found in container '" + container_id + "'.")
	return false
