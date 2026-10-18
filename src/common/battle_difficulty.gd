class_name BattleDifficulty
extends RefCounted

## Player-facing difficulty. Scales a battle GameConfig in place; does not touch health.
## Pass `base` when re-applying (training UI). Valleys: duplicate the level, then apply once.

const EASY := &"easy"
const NORMAL := &"normal"
const HARD := &"hard"

## Multipliers vs the unmodified config (normal = 1). Levels are tuned for an ~8-year-old on NORMAL;
## EASY = grade 1 (own level set `src/levels/{valley}/easy/` + these +40% time, no mid-battle speed-up),
## HARD = confident 10-year-old.
const PRESETS: Dictionary = {
	EASY: {
		"questions": 0.75,
		"answer_speed": 0.7,
		"round_speed": 0.0,
	},
	NORMAL: {
		"questions": 1.0,
		"answer_speed": 1.0,
		"round_speed": 1.0,
	},
	HARD: {
		"questions": 1.25,
		"answer_speed": 1.3,
		"round_speed": 1.5,
	},
}


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
