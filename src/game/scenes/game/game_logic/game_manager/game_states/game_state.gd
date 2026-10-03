class_name GameState
extends StateBase

signal ev_question_changed(question: QuizQuestion.Question)

static func get_state() -> String:
	return FSMGameStates.GAME

@export var game_events: GameEvents
@export var user_settings: UserSettings
@export var player: Player
@export var air_plane: AirPlane
@export var area: GameArea
@export var answerScene: PackedScene
@export var explosion_scene: PackedScene
@export var bonus_scene: PackedScene

var _round_controller: RoundController
var _bonus: BonusController
var _time_limit: BattleTimeLimit
var __components: Array[Variant] = []
var _answers_paused: bool = false
## Question already reported as a mistake — a later correct hit (after the hint) isn't "known".
var _missed_question: QuizQuestion.Question = null


func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	var plane_id := game_config.equipped_plane_id if game_config != null else PlaneCatalog.STARTER_ID
	if plane_id.is_empty():
		var profiles := ProfileController.find_in_tree(game_manager.get_tree() if game_manager else get_tree())
		if profiles != null:
			plane_id = profiles.equipped_plane_id()
		else:
			plane_id = PlaneCatalog.STARTER_ID
	var plane_def: Dictionary = PlaneCatalog.get_def(plane_id)
	var plane_speed: float = game_config.player_air_plane_speed * float(plane_def.get("speed_mult", 1.0))
	air_plane.initialize(plane_speed, user_settings.movement_mode)
	air_plane.apply_tint(plane_def.get("tint", Color.WHITE) as Color)
	air_plane.shot_speed_mult = float(plane_def.get("shot_speed_mult", 1.0))

	var answer_spawner: AnswerSpawner = AnswerSpawner.new(area, answerScene, game_manager.owner)
	_round_controller = RoundController.new(game_config, player, answer_spawner, game_manager.get_tree(), ev_question_changed)
	_bonus = BonusController.new(game_config, area, bonus_scene, game_manager.owner)
	_time_limit = BattleTimeLimit.new(game_config.time_limit_sec)
		
	__components.append_array([
		answer_spawner,
		_round_controller,
		_bonus,
		_time_limit,
	])
	
	_round_controller.ev_answers_spawned.connect(_on_answers_spawned)
	_round_controller.ev_round_started.connect(_bonus.on_round_started)
	_bonus.ev_collected.connect(_on_bonus_collected)
	_round_controller.ev_correct_missed.connect(_on_correct_missed)
	_time_limit.ev_tick.connect(game_events.ev_time_left.emit)
	_time_limit.ev_expired.connect(_end_game)
	event_listener.add(game_events.ev_pause_answers, _on_pause_answers)
	event_listener.add(game_events.ev_explosion, _on_explosion)
	event_listener.add(air_plane.ev_air_plane_colladed, _on_air_plane_collided)
	
	_round_controller.start()

func leave(_event_data: Dictionary) -> void:
	event_listener.clear()
	
	__components.reverse()
	for component in __components:
		component.deinit()
	__components.clear()
	
	_round_controller = null
	_bonus = null
	_time_limit = null
	_missed_question = null

func _process(delta: float) -> void:
	if _time_limit:
		_time_limit.update(delta)
	if _round_controller:
		_round_controller.update_answer_acceleration(player.acceleration)
		_bonus.update_acceleration(player.acceleration)

func _on_answers_spawned(options: Array[Answer]) -> void:
	_apply_answers_paused(options)
	game_events.ev_answers_spawned.emit(options.duplicate(), _round_controller.question.correct_answer, area.getLines().duplicate())


func _on_pause_answers(paused: bool) -> void:
	_answers_paused = paused
	if _round_controller:
		_apply_answers_paused(_round_controller.options)
	if _bonus:
		_bonus.set_paused(paused)
	if _time_limit:
		_time_limit.set_paused(paused)


func _apply_answers_paused(options: Array[Answer]) -> void:
	for answer in options:
		if is_instance_valid(answer):
			answer.frozen = _answers_paused


func _on_explosion(answer: Answer, _hit_point: Vector2) -> void:
	if _bonus.try_collect(answer):
		return
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, false)
	_apply_combat(action, answer)

func _on_air_plane_collided(collided_plane: AirPlane, answer: Answer) -> void:
	if _bonus.try_collect(answer):
		return
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, true)
	if action == CombatResolver.HitAction.WRONG_COLLISION:
		Explosion.spawn_attached(explosion_scene, answer, collided_plane.get_contact_point_with(answer))
	_apply_combat(action, answer)

func _apply_combat(action: CombatResolver.HitAction, answer: Answer) -> void:
	match action:
		CombatResolver.HitAction.CORRECT:
			game_events.ev_correct_answer.emit()
			_report_fact(true)
			answer.right()
			var health_before: int = player.health
			var is_win: bool = _round_controller.on_correct_answer(answer)
			_emit_streak_events(health_before)
			if is_win:
				_end_game()
		CombatResolver.HitAction.WRONG_SHOT:
			game_events.ev_mistake.emit()
			_report_fact(false)
			_round_controller.remove_answer(answer)
			answer.fail()
			answer.take_damage()
			_hint_correct()
			if CombatResolver.apply_damage(player):
				_end_game()
		CombatResolver.HitAction.WRONG_COLLISION:
			if _round_controller.has_answer(answer):
				game_events.ev_mistake.emit()
				answer.fail()
				_round_controller.kill_all_answers(answer)
				if CombatResolver.apply_damage(player):
					_end_game()

## Timed levels: letting the correct balloon fly away costs a heart (else waiting would win).
func _on_correct_missed() -> void:
	if not game_config.is_timed():
		return
	game_events.ev_mistake.emit()
	_round_controller.kill_all_answers()
	if CombatResolver.apply_damage(player):
		_end_game()

func _on_bonus_collected(amount: int) -> void:
	player.bonus_gold += amount
	game_events.ev_bonus_collected.emit(amount)

func _emit_streak_events(health_before: int) -> void:
	if player.streak >= game_config.streak_feedback_min:
		game_events.ev_streak.emit(player.streak)
	if player.health > health_before:
		game_events.ev_health_restored.emit()

## One `ev_fact_answered` per question: first wrong shot, or a clean correct hit.
func _report_fact(is_correct: bool) -> void:
	var question: QuizQuestion.Question = _round_controller.question
	if question == null or question.fact_key.is_empty() or question == _missed_question:
		return
	if not is_correct:
		_missed_question = question
	game_events.ev_fact_answered.emit(question.fact_key, is_correct)

func _end_game() -> void:
	_round_controller.stop()
	add_event(FSMGameEvents.END_GAME)


## After a wrong shot the correct balloon lights up (every plane — learning aid).
func _hint_correct() -> void:
	if _round_controller == null:
		return
	var correct_value: int = _round_controller.question.correct_answer
	for option in _round_controller.options:
		if option != null and option.value == correct_value:
			option.show_hint()
			return
