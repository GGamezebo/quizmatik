class_name BattleDifficulty
extends RefCounted

## Player-facing difficulty. Scales a battle GameConfig in place; does not touch health.
## Pass `base` when re-applying (training UI). Valleys: duplicate the level, then apply once.

const EASY := &"easy"
const NORMAL := &"normal"
const HARD := &"hard"

## Multipliers vs the unmodified config (normal = 1). Levels are tuned for an ~8-year-old on NORMAL;
## EASY = grade 1 (own level set `src/levels/{valley}/easy/` + these +40% time, no mid-battle speed-up,
## lighter boss: exam 6 → 4 plates, mini-boss 3 → 2 — each plate = one answer at the battle's hardest stage),
## HARD = grade 3-4: normal levels faster, every valley open, exams first (`ProgressController.skip_gold_for`).
const PRESETS: Dictionary = {
	EASY: {
		"questions": 0.75,
		"answer_speed": 0.7,
		"round_speed": 0.0,
		"boss_armor": 0.67,
	},
	NORMAL: {
		"questions": 1.0,
		"answer_speed": 1.0,
		"round_speed": 1.0,
		"boss_armor": 1.0,
	},
	HARD: {
		"questions": 1.25,
		"answer_speed": 1.3,
		"round_speed": 1.5,
		"boss_armor": 1.0,
	},
}

## Scaled armor never drops below this (unless authored lower): a one-plate boss is no fight.
const MIN_SCALED_ARMOR := 2


## Unknown / empty id → NORMAL.
static func sanitize(difficulty: StringName) -> StringName:
	return difficulty if PRESETS.has(difficulty) else NORMAL


static func apply(config: GameConfig, difficulty: StringName, base: GameConfig = null) -> void:
	if config == null:
		return
	var source: GameConfig = base if base != null else config
	var preset: Dictionary = PRESETS.get(difficulty, PRESETS[NORMAL]) as Dictionary
	var questions_coeff: float = float(preset.get("questions", 1.0))
	var speed_coeff: float = float(preset.get("answer_speed", 1.0))
	var round_coeff: float = float(preset.get("round_speed", 1.0))
	var base_questions: int = source.questions_count
	var base_speed: float = source.answer_speed
	var base_rounds: Dictionary = source.answer_speed_round_coeffs.duplicate(true)
	var base_stages: Dictionary = source.generate_number_round_ranges.duplicate(true)
	config.questions_count = maxi(1, roundi(float(base_questions) * questions_coeff))
	config.answer_speed = base_speed * speed_coeff
	config.answer_speed_round_coeffs = _scale_round_coeffs(base_rounds, round_coeff)
	config.generate_number_round_ranges = base_stages
	# Ramps / exam stages keep their place in a shorter or longer battle.
	config.scale_round_thresholds(float(config.questions_count) / float(maxi(1, base_questions)))
	scale_boss_armor(config, difficulty, source)


## Boss armor fields by the preset. `source` = unscaled values (default: `config` itself — call once per fresh armor,
## e.g. training UI after setting its practice armor).
static func scale_boss_armor(config: GameConfig, difficulty: StringName, source: GameConfig = null) -> void:
	if config == null:
		return
	var from: GameConfig = source if source != null else config
	var preset: Dictionary = PRESETS.get(difficulty, PRESETS[NORMAL]) as Dictionary
	var coeff: float = float(preset.get("boss_armor", 1.0))
	config.boss_armor = _scale_armor(from.boss_armor, coeff)
	config.boss_armor_max = _scale_armor(from.boss_armor_max, coeff)
	config.boss_royal_armor_min = _scale_armor(from.boss_royal_armor_min, coeff)
	config.boss_royal_armor_max = _scale_armor(from.boss_royal_armor_max, coeff)


## 0 (no armor range) stays 0.
static func _scale_armor(armor: int, coeff: float) -> int:
	if armor <= 0:
		return armor
	return maxi(mini(armor, MIN_SCALED_ARMOR), roundi(float(armor) * coeff))


## Speed-ups (> 1) scale with the preset; slow-downs (< 1, exam stages with harder examples) stay as authored.
static func _scale_round_coeffs(source: Dictionary, scale: float) -> Dictionary:
	var scaled: Dictionary = {}
	var any_change: bool = false
	for key in source.keys():
		var extra: float = float(source[key]) - 1.0
		if extra > 0.0:
			extra *= scale
		scaled[key] = 1.0 + extra
		any_change = any_change or not is_zero_approx(extra)
	return scaled if any_change else {}
