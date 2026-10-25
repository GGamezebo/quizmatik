class_name LevelsConfig
extends Resource

@export_dir var levels_dir = "res://src/levels"

## Grade-1 level set per valley (`tools/generate_levels.py` EASY_VALLEYS).
const EASY_FOLDER := "easy"
const EASY_CONFIG_KEY := "easy_config"
## Container key: the one `GameConfig.Operations` flag of the valley record battle (mix has none).
const RECORD_OPERATION_KEY := "record_operation"

var _containers_by_id: Dictionary = {}

var levels = {
   "containers": [
		{
			"container_id": "addition",
			"name": "Долина Сложения",
			"record_operation": GameConfig.Operations.ADDITION,
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
				{ "level_id": 17, "config": 'level_17' },
				{ "level_id": 18, "config": 'level_18' },
				{ "level_id": 19, "config": 'level_19' },
				{ "level_id": 20, "config": 'level_20', 'is_exam': true },
			]
		},
		{
			"container_id": "subtraction",
			"name": "Долина Вычитания",
			"record_operation": GameConfig.Operations.SUBTRACTION,
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
				{ "level_id": 17, "config": 'level_17' },
				{ "level_id": 18, "config": 'level_18' },
				{ "level_id": 19, "config": 'level_19' },
				{ "level_id": 20, "config": 'level_20', 'is_exam': true },
			]
		},
		{
			"container_id": "multiplication",
			"name": "Долина Умножения",
			"record_operation": GameConfig.Operations.MULTIPLICATION,
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
				{ "level_id": 17, "config": 'level_17' },
				{ "level_id": 18, "config": 'level_18' },
				{ "level_id": 19, "config": 'level_19' },
				{ "level_id": 20, "config": 'level_20', 'is_exam': true },
			]
		},
		{
			"container_id": "division",
			"name": "Долина Деления",
			"record_operation": GameConfig.Operations.DIVISION,
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
				{ "level_id": 17, "config": 'level_17' },
				{ "level_id": 18, "config": 'level_18' },
				{ "level_id": 19, "config": 'level_19' },
				{ "level_id": 20, "config": 'level_20', 'is_exam': true },
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
				{ "level_id": 17, "config": 'level_17' },
				{ "level_id": 18, "config": 'level_18' },
				{ "level_id": 19, "config": 'level_19' },
				{ "level_id": 20, "config": 'level_20', 'is_exam': true },
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
			var folder: String = levels_dir.path_join(container_id)
			level_data["config"] = _load_level(folder.path_join(file_name))
			level_data[EASY_CONFIG_KEY] = _load_level(folder.path_join(EASY_FOLDER).path_join(file_name))

func _load_level(full_path: String) -> GameConfig:
	if ResourceLoader.exists(full_path):
		return ResourceLoader.load(full_path) as GameConfig
	assert(false, "[Loader] Level config not found: " + full_path)
	return null

func find_container_in_config(container_id: String) -> Dictionary:
	if not _containers_by_id.has(container_id):
		push_warning("[LevelsConfig] Container '" + container_id + "' not found.")
		return {}
	return _containers_by_id[container_id]

## `difficulty` EASY → grade-1 set from `{container}/easy/` (same level ids, exams and progress).
func get_level_config(container_id: String, level_id: int, difficulty: StringName = BattleDifficulty.NORMAL) -> GameConfig:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return null

	for level in container["levels"]:
		if level.get("level_id") == level_id:
			if difficulty == BattleDifficulty.EASY and level.get(EASY_CONFIG_KEY) != null:
				return level[EASY_CONFIG_KEY]
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

## Valley record battle (level grid clock, opens with the exam): its only operation; 0 = the valley has none.
func get_record_operation(container_id: String) -> int:
	return int(find_container_in_config(container_id).get(RECORD_OPERATION_KEY, 0))

## Exam `level_id` of the valley (last level); -1 when it has none.
func get_exam_level_id(container_id: String) -> int:
	var container: Dictionary = find_container_in_config(container_id)
	for level in container.get("levels", []):
		if level.get("is_exam", false):
			return int(level["level_id"])
	return -1

func is_level_exam(container_id: String, level_id: int) -> bool:
	var container: Dictionary = find_container_in_config(container_id)
	if container.is_empty():
		return false

	for level in container["levels"]:
		if level.get("level_id") == level_id:
			return level.get('is_exam', false)

	push_warning("[ProgressManager] Warning: Level '" + str(level_id) + "' not found in container '" + container_id + "'.")
	return false
