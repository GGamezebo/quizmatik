class_name ExpertScenario
extends RefCounted

## Builds a valley expert trial: `template` (5 min countdown, «? ⊕ ? = N» answers, heart balloon every minute, no boss)
## with one stage per `endless_step_sec` (30 s) climbing through the valley's own levels (`STAGE_LEVELS`, the profile's level set), balloon pace
## scaled like the campaign (`BattleDifficulty` answer speed).

## Valley levels whose examples make the stages, in order (one per `endless_step_sec`).
const STAGE_LEVELS: Array[int] = [2, 4, 6, 8, 10, 12, 14, 16, 18, 19]


static func build(template: GameConfig, levels_config: LevelsConfig, container_id: String, difficulty: StringName) -> GameConfig:
	var config: GameConfig = template.duplicate(true)
	config.expert_valley_id = container_id
	var stages: Array[Dictionary] = []
	for level_id in STAGE_LEVELS:
		var level: GameConfig = levels_config.get_level_config(container_id, level_id, difficulty)
		if level == null:
			continue
		var stage: Dictionary = {
			"min_generate_number": level.min_generate_number,
			"max_generate_number": level.max_generate_number,
			"missing_operand_chance": 0.0,
		}
		for key in GameConfig.STAGE_KEYS:
			var value: Variant = level.get(key)
			stage[key] = value.duplicate(true) if value is Dictionary else value
		stages.append(stage)
	config.endless_stages = stages
	var preset: Dictionary = BattleDifficulty.PRESETS.get(BattleDifficulty.sanitize(difficulty), {}) as Dictionary
	var speed: float = float(preset.get("answer_speed", 1.0))
	config.endless_speed_start *= speed
	config.endless_speed_max *= speed
	config.answer_speed = config.endless_speed_start
	return config
