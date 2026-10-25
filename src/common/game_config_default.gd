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
	DIVISION = 8,       # 1 << 3
	## `n² = ?` — operand range = n.
	SQUARE = 16,        # 1 << 4
	## `√(n²) = ?` — operand range = the root n.
	ROOT = 32,          # 1 << 5
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
@export_flags("Addition:1", "Subtraction:2", "Multiplication:4", "Division:8", "Square:16", "Root:32") var allowed_operations: int = Operations.ADDITION | Operations.SUBTRACTION
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

@export_category("Endless")
## Endless survival battle (main-menu clock, unlocked after every valley exam): no question count / time
## limit, rounds until 0 hearts; score = seconds survived (`EndlessDirector`). Every `endless_step_sec` the
## next `endless_stages` entry applies; a boss flies in every `endless_boss_every_sec` of balloons.
@export var endless: bool = false
@export var endless_step_sec: float = 30.0
@export var endless_boss_every_sec: float = 120.0
## Example difficulty, one dict per step: `STAGE_KEYS` + min/max_generate_number + "missing_operand_chance"
## (absolute values — every stage lists all of them). Past the last stage it stays.
@export var endless_stages: Array[Dictionary] = []
## Answer speed per step (independent of stages): start → max at `endless_speed_max_sec`, then stays.
## Ease-in `endless_speed_curve` (> 1 = gentle start). Max: the fastest plane must still cross all lanes
## (≈405 px at 600 × 1.3 px/s ≈ 0.5 s) while a balloon flies ≈985 px to it (420 → ≈2.3 s).
@export var endless_speed_start: float = 50.0
@export var endless_speed_max: float = 420.0
@export var endless_speed_max_sec: float = 1200.0
@export var endless_speed_curve: float = 1.3
## Heart balloon (+1 heart, never above `health`) every `endless_heart_every_sec`, only when hurt; else wait again.
@export var endless_heart_every_sec: float = 300.0
## Staged battle: a heart balloon flies in after each defeated boss, only when hurt (magister trial).
@export var boss_drops_heart: bool = false
## Background paint: one step per `endless_step_sec`, reaching `endless_paint_max` at `endless_paint_sec`
## and staying there — never fully colored.
@export_range(0.0, 1.0, 0.05) var endless_paint_max: float = 0.75
@export var endless_paint_sec: float = 120.0
## Valley record battle (level grid clock, one operation — `ValleyRecordScenario`): own record per valley
## (`PData.StatisticsData.endless_best`) and the valley art. Empty = main-menu endless record.
@export var endless_valley_id: String = ""
## Runtime: active profile's best time of this record before the battle (`game.gd` from `PData.statistics`).
var endless_best_sec: int = 0

@export_category("Bonus")
## Chance that one golden bonus balloon flies by during the battle (0 = never; practice / exams keep 0).
@export_range(0.0, 1.0, 0.05) var bonus_gold_chance: float = 0.0
## Bonus balloon speed relative to the answers (> 1 keeps it ahead of the round's balloons).
@export var bonus_gold_speed_mult: float = 1.25

@export_category("Golden flight")
## Daily bonus battle («Золотой полёт», after 5/5 stamps): no hearts; each correct answer may release a
## fast coin balloon (catch = shoot or ram it); time up → pick one of the choice balloons. Gold kept win or lose.
@export var golden_flight: bool = false
## Coin balloon speed = `answer_speed` × this.
@export var golden_coin_speed_mult: float = 3.5
## Minimum seconds between coin balloons (fast answers don't flood the sky).
@export var golden_coin_gap_sec: float = 5.0
## Hidden gold of the final choice balloons (one per lane, shuffled).
@export var golden_choice_gold: Array[int] = [1, 2, 3, 4]

@export_category("Chase")
## Chase level: answers slide in and stand still; three airships chase the plane from the left and the
## world drains to gray behind them. Each correct answer moves the plane a step toward the screen middle
## (last one = there → win); the chief airship touching the plane = lost (`ChaseController`).
@export var chase: bool = false
## One correct answer buys the time a balloon needs to fly this far at `answer_speed` (pace follows difficulty).
@export var chase_answer_px: float = 550.0
## The chasers settle this many answer steps behind the plane after flying in.
@export var chase_head_start: float = 1.3
## Chance the battle becomes a chase (practice), rolled once at battle start by `roll_chase()`.
@export_range(0.0, 1.0, 0.05) var chase_chance: float = 0.0

@export_category("Expert")
## Both operands hidden «? + ? = 9» (expert trial): two shots fill the blanks in order, the verdict comes with
## the second (`PairAnswerController`); any balloon pair that solves it counts (the options keep exactly one).
@export var hidden_pair: bool = false
## Expert trial of this valley (level grid badge, `ExpertScenario`): surviving the timer = the expert award
## (`ProgressController.unlock_expert`); valley art in battle / post-battle. Empty = not an expert trial.
@export var expert_valley_id: String = ""

@export_category("Magister")
## Magister trial (menu cap, all valleys open): surviving the timer = the magister award.
@export var magister: bool = false

@export_category("Boss")
## Chance of the boss airship after the last regular answer (exam = 1; 0 = never). Ignored on timed levels.
@export_range(0.0, 1.0, 0.05) var boss_chance: float = 0.0
## Timed battles only: chance that the boss comes once the time is up (0 = never); `boss_chance` is ignored there.
@export_range(0.0, 1.0, 0.05) var timed_boss_chance: float = 0.0
## Correct answers needed to knock all armor plates off the boss.
@export_range(1, 12) var boss_armor: int = 3
## Above `boss_armor` → armor rolled per battle in `boss_armor`..`boss_armor_max` (0 = fixed).
@export_range(0, 12) var boss_armor_max: int = 0
## Chance that the boss is the royal one (on top of `boss_royal`); its armor rolls in the royal range below.
@export_range(0.0, 1.0, 0.05) var boss_royal_chance: float = 0.0
@export_range(1, 12) var boss_royal_armor_min: int = 4
@export_range(1, 12) var boss_royal_armor_max: int = 6
## After the last plate the boss gets angry and creeps toward the plane: shots needed to bring it down.
## 0 = no angry phase (the last plate brings it down).
@export_range(0, 60) var boss_rage_hits: int = 15
## Royal «chief» boss look (crown, angular hull) — set on exams; look only, same fight rules.
@export var boss_royal: bool = false

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


## Difficulty follows time (`EndlessDirector` + `endless_stages`), never score ramps: endless, magister trial.
func is_staged() -> bool:
	return endless or not endless_stages.is_empty()


func is_timed() -> bool:
	return time_limit_sec > 0.0


## Chase only fits a regular «answer N questions» battle: never timed, staged (endless, magister, expert), golden flight
## or two-blank questions.
func can_chase() -> bool:
	return not is_timed() and not is_staged() and not golden_flight and not hidden_pair


## Battle start: `chase_chance` may turn a regular battle into a chase.
func roll_chase() -> void:
	if not chase and chase_chance > 0.0 and can_chase() and randf() < chase_chance:
		chase = true


## Endless: difficulty of `step` (0 = start): examples from `endless_stages`, speed from the curve.
func apply_endless_stage(step: int) -> void:
	if endless_stages.is_empty():
		return
	var index: int = clampi(step, 0, endless_stages.size() - 1)
	var stage: Dictionary = endless_stages[index]
	var min_n: int = int(stage.get("min_generate_number", min_generate_number))
	var max_n: int = int(stage.get("max_generate_number", max_generate_number))
	min_generate_number = mini(min_n, max_n)
	max_generate_number = maxi(min_n, max_n)
	for key in STAGE_KEYS:
		if stage.has(key):
			set(key, stage[key])
	missing_operand_chance = float(stage.get("missing_operand_chance", missing_operand_chance))
	var progress: float = clampf(float(step) * endless_step_sec / maxf(endless_speed_max_sec, 1.0), 0.0, 1.0)
	answer_speed = lerpf(endless_speed_start, endless_speed_max, pow(progress, endless_speed_curve))


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
