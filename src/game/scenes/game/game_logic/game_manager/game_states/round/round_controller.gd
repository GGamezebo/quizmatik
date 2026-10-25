class_name RoundController
extends RefCounted

signal ev_answers_spawned(options: Array[Answer])
## New round: question set, answers spawn after a short delay.
signal ev_round_started(score: int, answer_speed: float)
## The round's correct balloon (expert: one of the hidden pair) flew off-screen unanswered — once per question.
signal ev_correct_missed

var options: Array[Answer] = []
var question: QuizQuestion.Question

var _game_config: GameConfig
var _player: Player
var _spawner: AnswerSpawner
var _tree: SceneTree
var _base_answer_speed: float = 0.0
var _base_min_generate: int = 0
var _base_max_generate: int = 0
var _is_active: bool = false
## Boss fly-in / fall: answered rounds don't start a new one until `release_rounds`.
var _held: bool = false
var _ev_question_changed_callback: Signal
var _missed_question: QuizQuestion.Question = null

func _init(
	game_config: GameConfig,
	player: Player,
	spawner: AnswerSpawner,
	tree: SceneTree,
	ev_question_changed: Signal
) -> void:
	_game_config = game_config
	_player = player
	_spawner = spawner
	_tree = tree
	_ev_question_changed_callback = ev_question_changed

func deinit() -> void:
	stop()
	_game_config = null
	_player = null
	_spawner = null
	_tree = null
	_ev_question_changed_callback = Signal()

func start() -> void:
	_base_answer_speed = _game_config.answer_speed
	_base_min_generate = _game_config.min_generate_number
	_base_max_generate = _game_config.max_generate_number
	_is_active = true
	_start_round()

func stop() -> void:
	_is_active = false
	_clear_answers()

func has_answer(answer: Answer) -> bool:
	return answer in options

func remove_answer(answer: Answer) -> void:
	options.erase(answer)

func update_answer_acceleration(acceleration: float) -> void:
	for answer in options:
		answer.set_acceleration(acceleration)

func on_correct_answer(hit_answer: Answer) -> bool:
	var is_win: bool = CombatResolver.apply_correct(
		_player,
		_game_config,
		_base_answer_speed,
		_base_min_generate,
		_base_max_generate,
	)
	kill_all_answers(hit_answer)
	return is_win

## Boss phase: the hit chips the boss armor instead of the score (streak still heals).
func on_boss_hit(hit_answer: Answer) -> void:
	CombatResolver.apply_streak(_player, _game_config)
	kill_all_answers(hit_answer)

func hold_rounds() -> void:
	_held = true

func release_rounds() -> void:
	_held = false
	if _is_active and options.is_empty():
		_start_round()

## No more rounds; the current balloons fade out (golden flight time-up).
func finish() -> void:
	_is_active = false
	kill_all_answers()

## Every balloon of the round pops (golden flight miss: no second try for this round's coin).
func pop_all_answers() -> void:
	for option in options.duplicate():
		option.take_damage(true)

func kill_all_answers(hit_answer: Answer = null) -> void:
	for option in options.duplicate():
		option.take_damage(option == hit_answer)

func _start_round() -> void:
	var previous_fact: String = question.fact_key if question != null else ""
	_set_question(QuizQuestion.generate_question(_game_config, _player.score, previous_fact))
	ev_round_started.emit(_player.score, _game_config.answer_speed)
	await _tree.create_timer(1.0, false).timeout
	if not _is_active:
		return
	_spawn_answers()

func _spawn_answers() -> void:
	_clear_answers()
	options = _spawner.spawn(question, _game_config.answer_speed)
	for answer in options:
		answer.ev_killed.connect(_on_answer_killed)
		answer.ev_escaped.connect(_on_answer_escaped)
	ev_answers_spawned.emit(options)

func _clear_answers() -> void:
	for option in options:
		if option.ev_killed.is_connected(_on_answer_killed):
			option.ev_killed.disconnect(_on_answer_killed)
		option.queue_free()
	options.clear()

## Popped balloons (an expert first pick) still drift while fading — only live ones count.
func _on_answer_escaped(answer: Answer) -> void:
	if not _is_active or question == null or question == _missed_question or not answer.is_hittable():
		return
	if question.is_key_value(answer.value):
		_missed_question = question
		ev_correct_missed.emit()

func _on_answer_killed(answer: Answer) -> void:
	options.erase(answer)
	if options.is_empty() and _is_active and not _held:
		_start_round()

func _set_question(new_question: QuizQuestion.Question) -> void:
	question = new_question
	_ev_question_changed_callback.emit(question)
