class_name LevelsConfig
extends Resource

@export_dir var levels_dir = "res://src/levels"

var levels = {
   "containers": [
		{
			"container_id": "container_1_addition",
			"pack_name": "Долина Сложения",
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
	],
}


func _init() -> void:
	for container in levels["containers"]:
		for level_data in container["levels"]:
			var config_name = level_data["config"]
			var file_name = config_name + ".tres"
			var full_path = levels_dir.path_join(file_name)
			
			if ResourceLoader.exists(full_path):
				level_data["config"] = ResourceLoader.load(full_path)
				print("[Loader] Level config loaded successfully for level", level_data["level_id"], ": ", full_path)
			else:
				assert(false, "[Loader] Файл конфигурации не найден по пути: " + full_path)
