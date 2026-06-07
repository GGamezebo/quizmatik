class_name GameState
extends StateBase

signal ev_question_changed(question: QuizQuestion.Question)

static func get_state() -> String:
	return FSMGameStates.GAME

@export var game_events: GameEvents
@export var game_config: GameConfig
@export var user_settings: UserSettings
@export var player: Player
@export var air_plane: AirPlane
@export var area: GameArea
@export var answerScene: PackedScene
@export var explosion_scene: PackedScene

var _round_controller: RoundController
var __components: Array[Variant] = []


func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	air_plane.initialize(game_config.player_air_plane_speed, user_settings.movement_mode)

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
	
	_round_controller = null

func _process(_delta: float) -> void:
	if _round_controller:
		_round_controller.update_answer_acceleration(player.acceleration)

func _on_explosion(answer: Answer, _hit_point: Vector2) -> void:
	_apply_combat(CombatResolver.resolve(answer, _round_controller.question, false), answer)

func _on_air_plane_collided(collided_plane: AirPlane, answer: Answer) -> void:
	var action: CombatResolver.HitAction = CombatResolver.resolve(answer, _round_controller.question, true)
	if action == CombatResolver.HitAction.WRONG_COLLISION:
		Explosion.spawn_attached(explosion_scene, answer, collided_plane.get_contact_point_with(answer))
	_apply_combat(action, answer)

func _apply_combat(action: CombatResolver.HitAction, answer: Answer) -> void:
	match action:
		CombatResolver.HitAction.CORRECT:
			answer.right()
			if _round_controller.on_correct_answer():
				_end_game()
		CombatResolver.HitAction.WRONG_SHOT:
			_round_controller.remove_answer(answer)
			answer.fail()
			answer.take_damage()
			if CombatResolver.apply_damage(player):
				_end_game()
		CombatResolver.HitAction.WRONG_COLLISION:
			if _round_controller.has_answer(answer):
				answer.fail()
				_round_controller.kill_all_answers()
				if CombatResolver.apply_damage(player):
					_end_game()

func _end_game() -> void:
	_round_controller.stop()
	add_event(FSMGameEvents.END_GAME)
