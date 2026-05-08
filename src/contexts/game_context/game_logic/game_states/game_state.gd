class_name GameState
extends StateBase

signal ev_question_changed(question: QuizQuestion.Question)

static func get_state() -> String:
	return 'Game'

@export var player: Player
@export var area: GameArea
@export var gameConfig: GameConfig
@export var answerScene: PackedScene
@export var game_events: GameEvents
@export var root_events: RootEvents

var options: Array[Answer] = []
var question: QuizQuestion.Question:
	set(new_question):
		question = new_question
		ev_question_changed.emit(question)

@onready var health:int = gameConfig.health:
	set(new_value):
		if health != new_value:
			health = new_value
			game_events.ev_health_changed.emit(health)
			if health == 0:
				root_events.ev_exit_game.emit()

func enter(_prev_state: FSMState, _event_data: Dictionary):
	event_listener.add(game_events.ev_explosion, _on_event_manager_ev_explosion)
	event_listener.add(player.ev_player_colladed, _on_player_colladed)
	_makeNewRound()

func leave(_event_data: Dictionary) -> void:
	event_listener.deinit()
	for option in options:
		option.queue_free()
	options.clear()

func _on_event_manager_ev_explosion(answer: Answer) -> void:
	if answer.value == question.correct_answer:
		_kill_all_answers()
	else:
		var index:int = options.find(answer)
		if index != -1:
			health -= 1
			options.remove_at(index)
		answer.take_damage()
		
func _makeNewRound() -> void:
	question = QuizQuestion.generate_question(gameConfig)
	await game_mamager.get_tree().create_timer(1.0).timeout
	if game_mamager == null:
		return
	_makeAnswers()
		
func _makeAnswers() -> void:
	var lines = area.getLines()
	for index in range(len(question.options)):
		var option:int = question.options[index]
		var answer:Answer = answerScene.instantiate()
		var line: Rect2 = lines[index]
		var x:float = area.gameplay_area.end.x + 120
		var y:float = line.position.y + line.size.y / 2.0
		answer.position.x = x
		answer.position.y = x
		answer.setup(x, y, option, gameConfig.answer_speed)
		answer.ev_killed.connect(_on_answer_killed)
		options.append(answer)
		game_mamager.owner.add_child.call_deferred(answer)
		
func _kill_all_answers():
	for option in options.duplicate():
		option.take_damage()			
			
func _on_player_colladed(_player:Player, answer: Answer) -> void:
	if answer.value == question.correct_answer:
		_kill_all_answers()
	else:
		var index:int = options.find(answer)
		if index != -1:
			health -= 1
			_kill_all_answers()

func _on_answer_killed(answer:Answer):
	options.erase(answer)
	if len(options) == 0:
		_makeNewRound()
