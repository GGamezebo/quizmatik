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
## Answer speed multipliers after round N, e.g. {4: 1.2, 10: 1.4}
@export var answer_speed_round_coeffs: Dictionary = {}

@export_category("Early Exam")
## Applied when the player starts the exam before completing all regular levels in the block.
@export var early_exam_questions_multiplier: float = 1.0
@export var early_exam_answer_speed_multiplier: float = 1.0

@export_category("AirPlane")
@export var player_air_plane_speed: float = 600.0
const PLAYER_ACCELERATION_DEFAULT: float = 1.0  # default acceleration coefficient
@export var player_acceleration_min: float = 0.5  # min acceleration coefficient
@export var player_acceleration_max: float = 2.0  # max acceleration coefficient
@export var player_acceleration_speed: float = 1.0  # acceleration coefficient per second


func apply_early_exam_modifiers() -> void:
	if early_exam_questions_multiplier > 1.0:
		questions_count = ceili(float(questions_count) * early_exam_questions_multiplier)
	if early_exam_answer_speed_multiplier > 1.0:
		answer_speed *= early_exam_answer_speed_multiplier


func apply_answer_speed_after_round(completed_rounds: int, base_speed: float) -> void:
	var coeff: float = 1.0
	var best_threshold: int = -1
	for threshold_key in answer_speed_round_coeffs.keys():
		var threshold: int = int(threshold_key)
		if completed_rounds >= threshold and threshold > best_threshold:
			best_threshold = threshold
			coeff = float(answer_speed_round_coeffs[threshold_key])
	answer_speed = base_speed * coeff
