class_name RoundController
extends RefCounted

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
var _ev_question_changed_callback: Signal

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

func on_correct_answer() -> bool:
	var is_win: bool = CombatResolver.apply_correct(
		_player,
		_game_config,
		_base_answer_speed,
		_base_min_generate,
		_base_max_generate,
	)
	kill_all_answers()
	return is_win

func kill_all_answers() -> void:
	for option in options.duplicate():
		option.take_damage()

func _start_round() -> void:
	_set_question(QuizQuestion.generate_question(_game_config))
	await _tree.create_timer(1.0).timeout
	if not _is_active:
		return
	_spawn_answers()

func _spawn_answers() -> void:
	_clear_answers()
	options = _spawner.spawn(question, _game_config.answer_speed)
	for answer in options:
		answer.ev_killed.connect(_on_answer_killed)

func _clear_answers() -> void:
	for option in options:
		if option.ev_killed.is_connected(_on_answer_killed):
			option.ev_killed.disconnect(_on_answer_killed)
		option.queue_free()
	options.clear()

func _on_answer_killed(answer: Answer) -> void:
	options.erase(answer)
	if options.is_empty() and _is_active:
		_start_round()

func _set_question(new_question: QuizQuestion.Question) -> void:
	question = new_question
	_ev_question_changed_callback.emit(question)
