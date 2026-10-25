class_name ValleyRecordScenario
extends RefCounted

## Builds a valley record battle: the menu endless battle `template` (stages every 30 s, boss, heart balloons,
## no time limit) with every stage narrowed to the valley's one `operation` and its own record (`endless_valley_id`).


static func build(template: GameConfig, container_id: String, operation: int) -> GameConfig:
	var config: GameConfig = template.duplicate(true)
	config.endless_valley_id = container_id
	config.allowed_operations = operation
	var stages: Array[Dictionary] = []
	for stage in template.endless_stages:
		var narrowed: Dictionary = stage.duplicate(true)
		narrowed["allowed_operations"] = operation
		stages.append(narrowed)
	config.endless_stages = stages
	return config
