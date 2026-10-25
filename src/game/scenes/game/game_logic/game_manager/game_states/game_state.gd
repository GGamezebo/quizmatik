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
## Endless battle extra-life balloon.
@export var heart_scene: PackedScene
@export var boss_scene: PackedScene
## Golden flight final pick (coin balloons reuse `bonus_scene`).
@export var golden_choice_scene: PackedScene
## Royal «chief» boss look when `GameConfig.boss_royal` (falls back to `boss_scene`).
@export var exam_boss_scene: PackedScene

var _round_controller: RoundController
var _bonus: BonusController
var _heart: HeartController
var _boss: BossController
var _time_limit: BattleTimeLimit
var _endless: EndlessDirector
var _golden: GoldenFlightController
var _chase: ChaseController
var _pair: PairAnswerController
## Expert miss: seconds the solved example stays on the banner before the next question.
const PAIR_SOLUTION_SEC: float = 2.4

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
	air_plane.apply_plane(plane_id)
	air_plane.shot_speed_mult = float(plane_def.get("shot_speed_mult", 1.0))

	var answer_spawner: AnswerSpawner = AnswerSpawner.new(area, answerScene, game_manager.owner)
	_round_controller = RoundController.new(game_config, player, answer_spawner, game_manager.get_tree(), ev_question_changed)
	_bonus = BonusController.new(game_config, area, bonus_scene, game_manager.owner)
	_heart = HeartController.new(game_config, area, heart_scene, game_manager.owner)
	var boss_packed: PackedScene = exam_boss_scene if game_config.boss_royal and exam_boss_scene != null else boss_scene
	_boss = BossController.new(game_config, area, boss_packed, game_manager.owner, exam_boss_scene)
	_time_limit = BattleTimeLimit.new(game_config.time_limit_sec)
	_endless = EndlessDirector.new(game_config)
	_golden = GoldenFlightController.new(game_config, area, bonus_scene, golden_choice_scene, game_manager.owner, game_manager.get_tree())
	# Chase level: royal chief + two regular airships behind the plane (same art as the boss fight).
	_chase = ChaseController.new(game_config, area, air_plane, player, exam_boss_scene, boss_scene, game_manager.owner)
	_pair = PairAnswerController.new(game_config)
		
	__components.append_array([
		answer_spawner,
		_round_controller,
		_bonus,
		_heart,
		_boss,
		_time_limit,
		_endless,
		_golden,
		_chase,
		_pair,
	])
	
	_round_controller.ev_answers_spawned.connect(_on_answers_spawned)
	_round_controller.ev_round_started.connect(_bonus.on_round_started)
	_bonus.ev_collected.connect(_on_bonus_collected)
	_heart.ev_collected.connect(_on_heart_collected)
	_round_controller.ev_correct_missed.connect(_on_correct_missed)
	_boss.ev_appeared.connect(game_events.ev_boss_appeared.emit)
	_boss.ev_ready.connect(_round_controller.release_rounds)
	_boss.ev_hit.connect(game_events.ev_boss_hit.emit)
	_boss.ev_enraged.connect(game_events.ev_boss_enraged.emit)
	_boss.ev_shot.connect(game_events.ev_boss_shot.emit)
	_boss.ev_defeated.connect(_on_boss_defeated)
	_time_limit.ev_tick.connect(game_events.ev_time_left.emit)
	_time_limit.ev_expired.connect(_on_time_expired)
	_golden.ev_collected.connect(_on_bonus_collected)
	_golden.ev_choice_started.connect(game_events.ev_golden_choice.emit)
	_golden.ev_finished.connect(_end_game)
	_endless.ev_tick.connect(_on_endless_tick)
	_endless.ev_boss_due.connect(_on_endless_boss_due)
	_endless.ev_heart_due.connect(_on_endless_heart_due)
	_chase.ev_started.connect(game_events.ev_chase_started.emit)
	_chase.ev_caught.connect(_on_chase_caught)
	_chase.ev_danger.connect(game_events.ev_chase_danger.emit)
	_chase.ev_drain.connect(game_events.ev_chase_drain.emit)
	event_listener.add(game_events.ev_pause_answers, _on_pause_answers)
	event_listener.add(game_events.ev_explosion, _on_explosion)
	event_listener.add(game_events.ev_target_shot, _boss.shoot)
	event_listener.add(air_plane.ev_air_plane_colladed, _on_air_plane_collided)
	event_listener.add(area.boundary_changed, _on_area_resized)
	
	_round_controller.start()
	_chase.start()

func leave(_event_data: Dictionary) -> void:
	event_listener.clear()
	
	__components.reverse()
	for component in __components:
		component.deinit()
	__components.clear()
	
	_round_controller = null
	_bonus = null
	_heart = null
	_boss = null
	_time_limit = null
	_endless = null
	_golden = null
	_chase = null
	_pair = null
	_missed_question = null

func _process(delta: float) -> void:
	if _time_limit:
		_time_limit.update(delta)
	if _endless:
		_endless.update(delta)
	if _golden:
		_golden.update(delta)
	if _chase:
		_chase.update(delta)
	if _round_controller:
		_round_controller.update_answer_acceleration(player.acceleration)
		_bonus.update_acceleration(player.acceleration)
		_heart.update_acceleration(player.acceleration)
		_golden.update_acceleration(player.acceleration)

func _on_answers_spawned(options: Array[Answer]) -> void:
	_boss.release_answers(options)
	_chase.release_answers(options)
	_apply_answers_paused(options)
	var question := _round_controller.question
	game_events.ev_answers_spawned.emit(options.duplicate(), question.correct_answer, area.getLines().duplicate(), question.missing_operand)
	if _pair.is_active() and not question.pair.is_empty():
		game_events.ev_pair_spawned.emit(options.duplicate(), question.pair.duplicate(), area.getLines().duplicate())


func _on_area_resized(new_rect: Rect2) -> void:
	var lines: Array[Rect2] = area.getLines()
	if _round_controller:
		for answer in _round_controller.options:
			if is_instance_valid(answer) and answer.lane_index < lines.size():
				answer.refit(lines[answer.lane_index], new_rect)
	game_events.ev_lanes_changed.emit(lines.duplicate())


func _on_pause_answers(paused: bool) -> void:
	_answers_paused = paused
	if _round_controller:
		_apply_answers_paused(_round_controller.options)
	if _bonus:
		_bonus.set_paused(paused)
	if _heart:
		_heart.set_paused(paused)
	if _time_limit:
		_time_limit.set_paused(paused)
	if _endless:
		_endless.set_paused(paused)
	if _golden:
		_golden.set_paused(paused)
	if _chase:
		_chase.set_paused(paused)


func _apply_answers_paused(options: Array[Answer]) -> void:
	for answer in options:
		if is_instance_valid(answer):
			answer.frozen = _answers_paused


func _on_explosion(answer: Answer, _hit_point: Vector2) -> void:
	if _golden.try_collect(answer) or _bonus.try_collect(answer) or _heart.try_collect(answer):
		return
	if _pair.is_active():
		_on_pair_hit(answer)
		return
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, false)
	_apply_combat(action, answer)

func _on_air_plane_collided(collided_plane: AirPlane, answer: Answer) -> void:
	if _golden.try_collect(answer) or _bonus.try_collect(answer) or _heart.try_collect(answer):
		return
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, true)
	if _pair.is_active():
		action = CombatResolver.HitAction.WRONG_COLLISION  # expert rounds: a ram never picks a number
	if action == CombatResolver.HitAction.WRONG_COLLISION:
		Explosion.spawn_attached(explosion_scene, answer, collided_plane.get_contact_point_with(answer))
	_apply_combat(action, answer)

func _apply_combat(action: CombatResolver.HitAction, answer: Answer) -> void:
	match action:
		CombatResolver.HitAction.CORRECT:
			game_events.ev_correct_answer.emit()
			_report_fact(true)
			answer.right()
			_on_correct(answer)
		CombatResolver.HitAction.WRONG_SHOT:
			game_events.ev_mistake.emit()
			_report_fact(false)
			if game_config.golden_flight:
				_fail_golden_round(answer)
				return
			_round_controller.remove_answer(answer)
			answer.fail()
			answer.take_damage()
			_hint_correct()
			_apply_damage()
		CombatResolver.HitAction.WRONG_COLLISION:
			if _round_controller.has_answer(answer):
				game_events.ev_mistake.emit()
				if game_config.golden_flight:
					_fail_golden_round(answer)
					return
				answer.fail()
				_round_controller.kill_all_answers(answer)
				_fail_pair_round()
				_apply_damage()

## Expert round: the first hit fills the left blank, the second decides (any pair that solves the example).
func _on_pair_hit(answer: Answer) -> void:
	if not _round_controller.has_answer(answer):
		return
	var question: QuizQuestion.Question = _round_controller.question
	var hit: PairAnswerController.Hit = _pair.pick(question, answer.value)
	if hit != PairAnswerController.Hit.IGNORED:
		answer.hide_number()
	match hit:
		PairAnswerController.Hit.PICKED:
			game_events.ev_pair_pick.emit(0, answer.value, answer.global_position)
			answer.take_damage(true)
		PairAnswerController.Hit.SOLVED:
			game_events.ev_pair_pick.emit(1, answer.value, answer.global_position)
			game_events.ev_pair_result.emit(true, question.pair_solution)
			game_events.ev_correct_answer.emit()
			_report_fact(true)
			answer.right()
			_on_correct(answer)
		PairAnswerController.Hit.WRONG:
			game_events.ev_pair_pick.emit(1, answer.value, answer.global_position)
			game_events.ev_pair_result.emit(false, question.pair_solution)
			game_events.ev_mistake.emit()
			_report_fact(false)
			answer.fail()
			_hold_for_solution()
			_round_controller.kill_all_answers(answer)
			_apply_damage()


## Expert round lost without a second pick (ram, balloon flew away): the banner shows the solution.
func _fail_pair_round() -> void:
	if not _pair.is_active() or _round_controller == null or _round_controller.question == null:
		return
	_pair.cancel(_round_controller.question)
	game_events.ev_pair_result.emit(false, _round_controller.question.pair_solution)
	_hold_for_solution()


## The next question waits a moment: the banner shows the solved example first.
func _hold_for_solution() -> void:
	_round_controller.hold_rounds()
	game_manager.get_tree().create_timer(PAIR_SOLUTION_SEC, false).timeout.connect(func() -> void:
		if _round_controller != null:
			_round_controller.release_rounds()
	)


## Last regular answer → boss fly-in (if rolled) instead of the win; during the fight a hit knocks off armor.
func _on_correct(answer: Answer) -> void:
	var health_before: int = player.health
	if _boss.is_fighting():
		var hit_from: Vector2 = answer.global_position
		_round_controller.on_boss_hit(answer)
		_emit_streak_events(health_before)
		if _boss.hit(hit_from):
			_round_controller.hold_rounds()
		return
	var is_win: bool = _round_controller.on_correct_answer(answer)
	_emit_streak_events(health_before)
	_golden.on_correct(answer.lane_index, game_config.answer_speed)
	if not is_win:
		return
	if _boss.is_waiting():
		_round_controller.hold_rounds()
		_boss.start()
	else:
		_end_game()

func _on_boss_defeated() -> void:
	game_events.ev_boss_defeated.emit()
	if _endless.is_active():
		_endless.boss_finished()
		_round_controller.release_rounds()
		if game_config.boss_drops_heart:
			_spawn_heart_if_hurt()
		return
	_end_game()


func _on_endless_tick(seconds: int) -> void:
	player.survived_sec = seconds
	game_events.ev_endless_time.emit(seconds)


## Endless: the current balloons finish, no new round until the boss is in place (`ev_ready`).
func _on_endless_boss_due() -> void:
	if not _boss.arm():
		_endless.boss_finished()
		return
	_round_controller.hold_rounds()
	_boss.start()

## Timed / endless: letting the correct balloon fly away costs a heart (else waiting would win / last).
func _on_correct_missed() -> void:
	if game_config.golden_flight or (not game_config.is_timed() and not game_config.endless):
		return
	game_events.ev_mistake.emit()
	_fail_pair_round()
	_round_controller.kill_all_answers()
	_apply_damage()


## Golden flight miss: the whole round pops — no coin balloon for it, next question follows.
func _fail_golden_round(answer: Answer) -> void:
	answer.fail()
	_round_controller.pop_all_answers()


## Golden flight never costs hearts (a miss just means no coin balloon).
func _apply_damage() -> void:
	if game_config.golden_flight:
		return
	if CombatResolver.apply_damage(player):
		_end_game()


## Timed end; golden flight first waits for the final pick (`GoldenFlightController.ev_finished`).
## A rolled boss (`timed_boss_chance`) flies in first: the balloons pop, no new round until it is in place.
func _on_time_expired() -> void:
	if not _golden.is_active():
		if _boss.is_waiting():
			_round_controller.hold_rounds()
			_round_controller.kill_all_answers()
			_boss.start()
			return
		_end_game()
		return
	_round_controller.finish()
	_golden.start_choice()

## Endless: only when hurt — full health waits for the next due.
func _on_endless_heart_due() -> void:
	_spawn_heart_if_hurt()


## Heart balloon only below max health (`game_config.health`): hearts never go above it.
func _spawn_heart_if_hurt() -> void:
	if player.health < game_config.health:
		_heart.spawn(game_config.answer_speed)


func _on_heart_collected() -> void:
	if player.health < game_config.health:
		player.health += 1
		game_events.ev_health_restored.emit()

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

## Chase level: the chief airship reached the plane — the battle is lost (crash in `EndGameState`).
func _on_chase_caught() -> void:
	player.health = 0
	_end_game()


func _end_game() -> void:
	_chase.finish(player.health > 0)
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
