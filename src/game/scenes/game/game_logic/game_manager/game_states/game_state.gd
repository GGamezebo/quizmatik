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

var _round_controller: RoundController
var __components: Array[Variant] = []
var _blast_lanes: int = 0
var _hint_on_miss: bool = false


func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	var plane_def: Dictionary = PlaneCatalog.get_def(PlaneCatalog.STARTER_ID)
	var profiles := ProfileController.find_in_tree(get_tree())
	if profiles != null:
		plane_def = PlaneCatalog.get_def(profiles.equipped_plane_id())
	_blast_lanes = int(plane_def.get("blast_lanes", 0))
	_hint_on_miss = bool(plane_def.get("hint_on_miss", false))
	var plane_speed: float = game_config.player_air_plane_speed * float(plane_def.get("speed_mult", 1.0))
	air_plane.initialize(plane_speed, user_settings.movement_mode)
	air_plane.apply_tint(plane_def.get("tint", Color.WHITE) as Color)

	var answer_spawner: AnswerSpawner = AnswerSpawner.new(area, answerScene, game_manager.owner)
	_round_controller = RoundController.new(game_config, player, answer_spawner, game_manager.get_tree(), ev_question_changed)
		
	__components.append_array([
		answer_spawner,
		_round_controller,
	])
	
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

func _process(_delta: float) -> void:
	if _round_controller:
		_round_controller.update_answer_acceleration(player.acceleration)

func _on_explosion(answer: Answer, _hit_point: Vector2) -> void:
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, false)
	var blasted := _blast_correct_answer(answer)
	if action != CombatResolver.HitAction.CORRECT and blasted != null:
		action = CombatResolver.HitAction.CORRECT
		answer = blasted
	_apply_combat(action, answer)

func _on_air_plane_collided(collided_plane: AirPlane, answer: Answer) -> void:
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, true)
	if action == CombatResolver.HitAction.WRONG_COLLISION:
		Explosion.spawn_attached(explosion_scene, answer, collided_plane.get_contact_point_with(answer))
	_apply_combat(action, answer)

func _apply_combat(action: CombatResolver.HitAction, answer: Answer) -> void:
	match action:
		CombatResolver.HitAction.CORRECT:
			game_events.ev_correct_answer.emit()
			answer.right()
			if _round_controller.on_correct_answer(answer):
				_end_game()
		CombatResolver.HitAction.WRONG_SHOT:
			game_events.ev_mistake.emit()
			_round_controller.remove_answer(answer)
			answer.fail()
			answer.take_damage()
			_hint_correct_if_needed()
			if CombatResolver.apply_damage(player):
				_end_game()
		CombatResolver.HitAction.WRONG_COLLISION:
			if _round_controller.has_answer(answer):
				game_events.ev_mistake.emit()
				answer.fail()
				_round_controller.kill_all_answers(answer)
				if CombatResolver.apply_damage(player):
					_end_game()

func _end_game() -> void:
	_round_controller.stop()
	add_event(FSMGameEvents.END_GAME)


func _blast_correct_answer(hit: Answer) -> Answer:
	if _blast_lanes <= 0 or _round_controller == null or hit == null:
		return null
	var correct_value: int = _round_controller.question.correct_answer
	for option in _round_controller.options:
		if option == null:
			continue
		if absi(option.lane_index - hit.lane_index) <= _blast_lanes and option.value == correct_value:
			return option
	return null


func _hint_correct_if_needed() -> void:
	if not _hint_on_miss or _round_controller == null:
		return
	var correct_value: int = _round_controller.question.correct_answer
	for option in _round_controller.options:
		if option != null and option.value == correct_value:
			option.show_hint()
			return
