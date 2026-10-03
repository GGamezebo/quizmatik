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
## Operand ranges after score N, e.g. {6: {"min_generate_number": 10, "max_generate_number": 40}}
## Empty → keep min/max_generate_number for the whole battle.
@export var generate_number_round_ranges: Dictionary = {}
## Per-operation operand range, e.g. {Operations.MULTIPLICATION: Vector2i(1, 10)}.
## Operations missing here use min/max_generate_number.
@export var operation_ranges: Dictionary = {}
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
		questions_count = ceili(float(questions_count) * early_exam_questions_multiplier)
	if early_exam_answer_speed_multiplier > 1.0:
		answer_speed *= early_exam_answer_speed_multiplier


func get_operation_range(operation: int) -> Vector2i:
	var entry: Variant = operation_ranges.get(operation)
	if entry is Vector2i:
		return Vector2i(mini(entry.x, entry.y), maxi(entry.x, entry.y))
	return Vector2i(min_generate_number, max_generate_number)


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
	for threshold_key in generate_number_round_ranges.keys():
		var threshold: int = int(threshold_key)
		if completed_rounds >= threshold and threshold > best_threshold:
			var entry: Variant = generate_number_round_ranges[threshold_key]
			if entry is Dictionary:
				best_threshold = threshold
				min_n = int(entry.get("min_generate_number", min_n))
				max_n = int(entry.get("max_generate_number", max_n))
	min_generate_number = mini(min_n, max_n)
	max_generate_number = maxi(min_n, max_n)


## Hidden-operand share for the next question at the current `score`.
func missing_operand_chance_at(score: int) -> float:
	if score < ceili(questions_count * missing_operand_start_progress):
		return 0.0
	return missing_operand_chance
