class_name LevelsConfig
extends Resource

@export var countainer1_level1: Resource

@export var levels_resource: Dictionary[String, Resource]

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
				{
					"level_id": 1,
					"config": 'level_1',
				},
				{
					"level_id": 2,
					"config": 'level_2',
				},
				{
					"level_id": 3,
					"config": 'level_3',
				},
				{
					"level_id": 4,
					"config": 'level_4',
				},
				{
					"level_id": 5,
					"config": 'level_5',
				},
				{
					"level_id": 6,
					"config": 'level_6',
				}
			]
		},
		
	],
}
