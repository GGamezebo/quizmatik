class_name GoldenFlightScenario
extends RefCounted

## Builds the «Золотой полёт» battle: examples of the player's campaign frontier level (furthest
## unlocked regular level of the latest unlocked valley) scaled by the profile difficulty, wrapped in
## the golden-flight rules of `template` (no boss / bonus balloon, own time). No progress → `template` as is.


static func build(template: GameConfig, progress: ProgressController, time_sec: float) -> GameConfig:
	var config: GameConfig = null
	var frontier: Array = find_frontier(progress)
	if not frontier.is_empty():
		var level: GameConfig = progress.levels_config.get_level_config(frontier[0], frontier[1])
		if level != null:
			config = level.duplicate(true)
			BattleDifficulty.apply(config, BattleDifficulty.sanitize(StringName(progress.pdata.difficulty)))
	if config == null:
		config = template.duplicate(true)
	config.golden_flight = true
	config.golden_coin_speed_mult = template.golden_coin_speed_mult
	config.golden_coin_gap_sec = template.golden_coin_gap_sec
	config.golden_choice_gold = template.golden_choice_gold.duplicate()
	config.time_limit_sec = time_sec
	config.health = template.health
	config.streak_heal_every = 0
	config.bonus_gold_chance = 0.0
	config.boss_chance = 0.0
	config.boss_royal = false
	config.endless = false
	return config


## `[container_id, level_id]` of the furthest unlocked regular level, `[]` without progress.
static func find_frontier(progress: ProgressController) -> Array:
	if progress == null or progress.levels_config == null:
		return []
	var containers: Variant = progress.levels_config.levels.get("containers", [])
	if not containers is Array:
		return []
	var result: Array = []
	for container: Dictionary in containers:
		var container_id: String = container.get("container_id", "")
		if not progress.is_container_unlocked(container_id):
			continue
		var best: int = -1
		for level: Dictionary in container.get("levels", []):
			var level_id: int = int(level.get("level_id", -1))
			if level.get("is_exam", false) or level_id <= best:
				continue
			if progress.is_level_unlocked(container_id, level_id):
				best = level_id
		if best > 0:
			result = [container_id, best]
	return result
