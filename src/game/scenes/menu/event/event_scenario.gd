class_name EventScenario
extends RefCounted

## Builds a seasonal event battle (menu event banner, post-battle «repeat»): `event.battle_template` rules (hearts,
## chase pace, boss armor / rage, heart balloons) for run `window`; the boss chases the plane for
## `event.chase_minutes(wins)` minutes (timed chase), then flies in for the fight.
## Examples = the pilot's valleys: every single-op valley reached by the exam chain or with stars (same rule as the
## golden flight), mixed together; each climbs from `START_SHARE` of the way to its furthest open level up to that
## level over `STAGE_COUNT` stages (the last one just before the boss). Pace from those levels × profile difficulty,
## rising to its peak at the boss. A fresh pilot = addition level 1; no progress at all (isolated run) = the template.

const STAGE_COUNT: int = 8
const START_SHARE: float = 0.35
## Balloon pace at the chase start = this share of the start levels' pace (the chasers creep slower too).
const START_PACE: float = 0.8


static func build(event: SeasonalEvent, window: EventWindow, wins: int, progress: ProgressController) -> GameConfig:
	var config: GameConfig = event.battle_template.duplicate(true)
	config.event_id = event.id
	config.event_key = window.key()
	config.chase = true
	config.timed_chase = true
	var chase_sec: float = float(event.chase_minutes(wins)) * 60.0
	config.time_limit_sec = chase_sec
	var difficulty: StringName = BattleDifficulty.NORMAL
	if progress != null and progress.pdata != null:
		difficulty = BattleDifficulty.sanitize(StringName(progress.pdata.difficulty))
	var levels: LevelsConfig = progress.levels_config if progress != null else null
	var frontiers: Dictionary = find_frontiers(progress)
	if levels == null or frontiers.is_empty():
		return config
	var stages: Array[Dictionary] = []
	for index in STAGE_COUNT:
		stages.append(_stage(levels, frontiers, float(index) / float(STAGE_COUNT - 1), difficulty))
	config.endless_stages = stages
	config.endless_step_sec = chase_sec / float(STAGE_COUNT)
	var preset: Dictionary = BattleDifficulty.PRESETS.get(difficulty, {}) as Dictionary
	var pace: float = float(preset.get("answer_speed", 1.0))
	config.endless_speed_start = _pace(levels, frontiers, 0.0, difficulty, false) * START_PACE * pace
	config.endless_speed_max = _pace(levels, frontiers, 1.0, difficulty, true) * pace
	config.endless_speed_max_sec = chase_sec
	config.answer_speed = config.endless_speed_start
	BattleDifficulty.scale_boss_armor(config, difficulty)
	return config


## `container_id` → furthest unlocked regular level, for every single-op valley (`LevelsConfig.get_record_operation`)
## the pilot reached by the exam chain or with stars. A valley open only for the grade, with no stars, stays out.
static func find_frontiers(progress: ProgressController) -> Dictionary:
	var result: Dictionary = {}
	if progress == null or progress.levels_config == null:
		return result
	var levels: LevelsConfig = progress.levels_config
	for container: Dictionary in levels.levels.get("containers", []):
		var container_id: String = container.get("container_id", "")
		if levels.get_record_operation(container_id) == 0 or not progress.is_container_unlocked(container_id):
			continue
		if not progress.is_campaign_unlocked(container_id) and not progress.valley_has_stars(container_id):
			continue
		var best: int = -1
		for level: Dictionary in container.get("levels", []):
			var level_id: int = int(level.get("level_id", -1))
			if not level.get("is_exam", false) and level_id > best and progress.is_level_unlocked(container_id, level_id):
				best = level_id
		if best > 0:
			result[container_id] = best
	return result


## Level of `container_id` at share `t` of the climb (0 = start, 1 = frontier).
static func _level_at(frontier: int, t: float) -> int:
	var start: int = maxi(1, roundi(float(frontier) * START_SHARE))
	return clampi(roundi(lerpf(float(start), float(frontier), t)), 1, frontier)


## One `endless_stages` entry: every valley's operation with the ranges of its level at `t`.
static func _stage(levels: LevelsConfig, frontiers: Dictionary, t: float, difficulty: StringName) -> Dictionary:
	var ops: int = 0
	var first: Dictionary = {}
	var second: Dictionary = {}
	var results: Dictionary = {}
	var carry_modes: Array[int] = []
	var missing: float = 0.0
	var min_n: int = 1 << 30
	var max_n: int = 0
	for container_id: String in frontiers:
		var level: GameConfig = levels.get_level_config(container_id, _level_at(frontiers[container_id], t), difficulty)
		if level == null:
			continue
		var op: int = levels.get_record_operation(container_id)
		ops |= op
		var first_range: Vector2i = level.get_operation_range(op)
		first[op] = first_range
		second[op] = level.get_second_operand_range(op)
		var result_range: Variant = level.result_ranges.get(op)
		if result_range is Vector2i:
			results[op] = result_range
		if op == GameConfig.Operations.ADDITION or op == GameConfig.Operations.SUBTRACTION:
			carry_modes.append(level.carry_mode)
		missing += level.missing_operand_chance
		min_n = mini(min_n, first_range.x)
		max_n = maxi(max_n, first_range.y)
	var carry: int = GameConfig.CarryMode.ANY
	if not carry_modes.is_empty() and carry_modes.count(carry_modes[0]) == carry_modes.size():
		carry = carry_modes[0]
	return {
		"allowed_operations": ops,
		"operation_ranges": first,
		"second_operand_ranges": second,
		"result_ranges": results,
		"carry_mode": carry,
		"min_generate_number": mini(min_n, max_n),
		"max_generate_number": max_n,
		"missing_operand_chance": missing / float(maxi(frontiers.size(), 1)),
	}


## Mean balloon pace of the valleys' levels at `t`; `peak` = with their fastest in-level speed-up.
static func _pace(levels: LevelsConfig, frontiers: Dictionary, t: float, difficulty: StringName, peak: bool) -> float:
	var total: float = 0.0
	var count: int = 0
	for container_id: String in frontiers:
		var level: GameConfig = levels.get_level_config(container_id, _level_at(frontiers[container_id], t), difficulty)
		if level == null:
			continue
		var speed: float = level.answer_speed
		if peak:
			for coeff in level.answer_speed_round_coeffs.values():
				speed = maxf(speed, level.answer_speed * float(coeff))
		total += speed
		count += 1
	return total / float(count) if count > 0 else 60.0
