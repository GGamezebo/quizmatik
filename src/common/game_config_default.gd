class_name GameConfig
extends Resource

class BattleInfo:
	var container_id: String = ""
	var level_id: int = 0
	var is_exam: bool = false
	var is_early_exam: bool = false
	
	func _init(
		_container_id: String,
		_level_id: int,
		_is_exam: bool,
		_is_early_exam: bool = false,
	) -> void:
		container_id = _container_id
		level_id = _level_id
		is_exam = _is_exam
		is_early_exam = _is_early_exam
	
var battle_info: BattleInfo = null
var custom_battle: GameConfig = null

enum Operations {
	ADDITION = 1,       # 1 << 0
	SUBTRACTION = 2,    # 1 << 1
	MULTIPLICATION = 4, # 1 << 2
	DIVISION = 8        # 1 << 3
}

enum CarryMode {
	ANY = 0,
	NONE = 1,
	REQUIRED = 2,
}

## Keys a `generate_number_round_ranges` stage may override besides min/max.
const STAGE_KEYS: Array[String] = [
	"allowed_operations",
	"operation_ranges",
	"second_operand_ranges",
	"result_ranges",
	"carry_mode",
]

@export_category("Global Game Settings")
@export var answer_lines_count: int = 4
@export var health: int = 3
@export var questions_count: int = 5
@export_flags("Addition:1", "Subtraction:2", "Multiplication:4", "Division:8") var allowed_operations: int = Operations.ADDITION | Operations.SUBTRACTION
@export var min_generate_number: int = 2
@export var max_generate_number: int = 9
@export var answer_speed: float = 80.0
## Answer speed multipliers after score N, e.g. {4: 1.2, 10: 1.4}
@export var answer_speed_round_coeffs: Dictionary = {}
## Question stages after score N, e.g. {6: {"min_generate_number": 10, "max_generate_number": 40}}.
## min/max missing in the reached stage → base values. `STAGE_KEYS` (per-op ranges, carry, ops)
## replace the current value and stay until a later stage replaces them (exam = climb through the valley).
## Empty → keep the start setup for the whole battle.
@export var generate_number_round_ranges: Dictionary = {}
## Per-operation first operand range (+: first addend, −: minuend, ×: first factor, ÷: divisor),
## e.g. {Operations.MULTIPLICATION: Vector2i(2, 3)}. Operations missing here use min/max_generate_number.
@export var operation_ranges: Dictionary = {}
## Per-operation second operand range (+: addend, −: subtrahend, ×: second factor, ÷: quotient).
## Operations missing here reuse the first operand range. ×/+ are shown in random order.
@export var second_operand_ranges: Dictionary = {}
## Per-operation allowed answer of the full example (+ sum, − difference, × product, ÷ quotient),
## e.g. {Operations.ADDITION: Vector2i(11, 18)} = «с переходом через десяток». Missing → any.
@export var result_ranges: Dictionary = {}
## +/− only: units carry (+) / borrow (−) across the ten. ANY / NONE = «без перехода» / REQUIRED = «с переходом».
@export var carry_mode: CarryMode = CarryMode.ANY
## Share of questions with a hidden operand instead of the result: `? + 3 = 7`, `8 - ? = 5`.
@export_range(0.0, 1.0, 0.05) var missing_operand_chance: float = 0.0
## Hidden-operand questions start once this share of `questions_count` is answered (0 = from the start).
@export_range(0.0, 1.0, 0.05) var missing_operand_start_progress: float = 0.0
## Share of questions re-asking a past mistake from `review_facts` (only facts that fit allowed ops + ranges).
@export_range(0.0, 1.0, 0.05) var review_chance: float = 0.25
## Runtime: `MathFact` key → weight from the active profile (payload `review_facts`); not authored on `.tres`.
var review_facts: Dictionary = {}

@export_category("Streak")
## Correct answers in a row before the HUD shows «СЕРИЯ ×N».
@export var streak_feedback_min: int = 3
## Every N correct answers in a row restore one heart (0 = off).
@export var streak_heal_every: int = 5
## Streak healing never raises health above this.
@export var streak_heal_max_health: int = 3

@export_category("Timed")
## > 0 = timed level: survive this many seconds (endless questions, `questions_count` ignored);
## a correct balloon flying off-screen costs a heart. 0 = regular «answer N questions».
@export var time_limit_sec: float = 0.0

@export_category("Bonus")
## Chance that one golden bonus balloon flies by during the battle (0 = never; practice / exams keep 0).
@export_range(0.0, 1.0, 0.05) var bonus_gold_chance: float = 0.0
## Bonus balloon speed relative to the answers (> 1 keeps it ahead of the round's balloons).
@export var bonus_gold_speed_mult: float = 1.25

@export_category("Boss")
## Chance of the boss airship after the last regular answer (exam = 1; 0 = never). Ignored on timed levels.
@export_range(0.0, 1.0, 0.05) var boss_chance: float = 0.0
## Correct answers needed to knock all armor plates off the boss.
@export_range(1, 12) var boss_armor: int = 3
## After the last plate the boss gets angry and creeps toward the plane: shots needed to bring it down.
@export_range(1, 60) var boss_rage_hits: int = 15

@export_category("Early Exam")
## Applied when the player starts the exam before completing all regular levels in the block.
@export var early_exam_questions_multiplier: float = 1.0
@export var early_exam_answer_speed_multiplier: float = 1.0

@export_category("AirPlane")
@export var player_air_plane_speed: float = 600.0
## Runtime loadout from the active profile; not authored on level `.tres`.
var equipped_plane_id: String = "starter"
const PLAYER_ACCELERATION_DEFAULT: float = 1.0  # default acceleration coefficient
@export var player_acceleration_min: float = 0.5  # min acceleration coefficient
@export var player_acceleration_max: float = 2.0  # max acceleration coefficient
@export var player_acceleration_speed: float = 1.0  # acceleration coefficient per second


func is_timed() -> bool:
	return time_limit_sec > 0.0


func apply_early_exam_modifiers() -> void:
	if early_exam_questions_multiplier > 1.0:
		var base_questions: int = questions_count
		questions_count = ceili(float(questions_count) * early_exam_questions_multiplier)
		scale_round_thresholds(float(questions_count) / float(maxi(1, base_questions)))
	if early_exam_answer_speed_multiplier > 1.0:
		answer_speed *= early_exam_answer_speed_multiplier


## Keeps mid-battle speed ramps / question stages at the same share of the battle after `questions_count` changes.
func scale_round_thresholds(factor: float) -> void:
	answer_speed_round_coeffs = scale_thresholds(answer_speed_round_coeffs, factor)
	generate_number_round_ranges = scale_thresholds(generate_number_round_ranges, factor)


## Score-keyed dict with keys × `factor` (≥ 1); on a collision the later threshold wins.
static func scale_thresholds(source: Dictionary, factor: float) -> Dictionary:
	if source.is_empty() or is_equal_approx(factor, 1.0):
		return source.duplicate(true)
	var keys: Array = source.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(a) < int(b))
	var scaled: Dictionary = {}
	for key in keys:
		scaled[maxi(1, roundi(float(key) * factor))] = source[key]
	return scaled


func get_operation_range(operation: int) -> Vector2i:
	return _range_from(operation_ranges, operation, Vector2i(min_generate_number, max_generate_number))


func get_second_operand_range(operation: int) -> Vector2i:
	return _range_from(second_operand_ranges, operation, get_operation_range(operation))


## Allowed answer of the full example; any non-negative value when the op has no entry.
func get_result_range(operation: int) -> Vector2i:
	return _range_from(result_ranges, operation, Vector2i(0, 1 << 30))


static func _range_from(ranges: Dictionary, operation: int, fallback: Vector2i) -> Vector2i:
	var entry: Variant = ranges.get(operation)
	if entry is Vector2i:
		return Vector2i(mini(entry.x, entry.y), maxi(entry.x, entry.y))
	return fallback


func apply_answer_speed_after_round(completed_rounds: int, base_speed: float) -> void:
	var coeff: float = 1.0
	var best_threshold: int = -1
	for threshold_key in answer_speed_round_coeffs.keys():
		var threshold: int = int(threshold_key)
		if completed_rounds >= threshold and threshold > best_threshold:
			best_threshold = threshold
			coeff = float(answer_speed_round_coeffs[threshold_key])
	answer_speed = base_speed * coeff


func apply_generate_number_after_round(completed_rounds: int, base_min: int, base_max: int) -> void:
	var min_n: int = base_min
	var max_n: int = base_max
	var best_threshold: int = -1
	var stage: Dictionary = {}
	for threshold_key in generate_number_round_ranges.keys():
		var threshold: int = int(threshold_key)
		if completed_rounds >= threshold and threshold > best_threshold:
			var entry: Variant = generate_number_round_ranges[threshold_key]
			if entry is Dictionary:
				best_threshold = threshold
				stage = entry
	min_n = int(stage.get("min_generate_number", min_n))
	max_n = int(stage.get("max_generate_number", max_n))
	min_generate_number = mini(min_n, max_n)
	max_generate_number = maxi(min_n, max_n)
	for key in STAGE_KEYS:
		if stage.has(key):
			set(key, stage[key])


## Hidden-operand share for the next question at the current `score`.
func missing_operand_chance_at(score: int) -> float:
	if score < ceili(questions_count * missing_operand_start_progress):
		return 0.0
	return missing_operand_chance
