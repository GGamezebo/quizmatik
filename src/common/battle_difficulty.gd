class_name BattleDifficulty
extends RefCounted

## Player-facing difficulty. Scales a battle GameConfig in place; does not touch health.
## Pass `base` when re-applying (training UI). Valleys: duplicate the level, then apply once.

const EASY := &"easy"
const NORMAL := &"normal"
const HARD := &"hard"

## Multipliers vs the unmodified config (normal = 1).
const PRESETS: Dictionary = {
	EASY: {
		"questions": 0.625,
		"answer_speed": 0.5625,
		"round_speed": 0.0,
	},
	NORMAL: {
		"questions": 1.0,
		"answer_speed": 1.0,
		"round_speed": 1.0,
	},
	HARD: {
		"questions": 1.5,
		"answer_speed": 1.5,
		"round_speed": 1.5,
	},
}


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
	config.questions_count = maxi(1, roundi(float(base_questions) * questions_coeff))
	config.answer_speed = base_speed * speed_coeff
	config.answer_speed_round_coeffs = _scale_round_coeffs(base_rounds, round_coeff)


static func _scale_round_coeffs(source: Dictionary, scale: float) -> Dictionary:
	if source.is_empty() or is_zero_approx(scale):
		return {}
	var scaled: Dictionary = {}
	for key in source.keys():
		var extra: float = (float(source[key]) - 1.0) * scale
		var value: float = 1.0 + extra
		if is_equal_approx(value, 1.0):
			continue
		scaled[key] = value
	return scaled
