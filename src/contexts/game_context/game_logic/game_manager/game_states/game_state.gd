class_name GameState
extends StateBase

signal ev_question_changed(question: QuizQuestion.Question)

static func get_state() -> String:
	return FSMGameStates.GAME

@export var game_events: GameEvents
@export var game_config: GameConfig
@export var player: Player
@export var air_plane: AirPlane
@export var area: GameArea
@export var answerScene: PackedScene

var options: Array[Answer] = []
var question: QuizQuestion.Question:
	set(new_question):
		question = new_question
		ev_question_changed.emit(question)


func enter(_prev_state: FSMState, _event_data: Dictionary):
	event_listener.add(game_events.ev_explosion, _on_event_manager_ev_explosion)
	event_listener.add(air_plane.ev_air_plane_colladed, _on_air_plane_colladed)
	_makeNewRound()

func leave(_event_data: Dictionary) -> void:
	event_listener.deinit()
	for option in options:
		option.queue_free()
	options.clear()
	
func _process(_delta: float) -> void:
	for answer in options:
		answer.set_acceleration(player.acceleration)
	
func _makeNewRound() -> void:
	question = QuizQuestion.generate_question(game_config)
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
		answer.setup(x, y, option, game_config.answer_speed)
		answer.ev_killed.connect(_on_answer_killed)
		options.append(answer)
		game_mamager.owner.add_child.call_deferred(answer)
			

func _on_event_manager_ev_explosion(answer: Answer, _hit_point: Vector2) -> void:
	if answer.value == question.correct_answer:
		answer.right()
		_process_correct_answer()
	else:
		var index: int = options.find(answer)
		if index != -1:
			options.remove_at(index)
			_get_damage()
		answer.fail()
		answer.take_damage()

func _on_air_plane_colladed(_air_plane: AirPlane, answer: Answer) -> void:
	if answer.value == question.correct_answer:
		answer.right()
		_process_correct_answer()
	else:
		var index:int = options.find(answer)
		if index != -1:
			answer.fail()
			_get_damage()
			_kill_all_answers()

func _process_correct_answer() -> void:
	_kill_all_answers()
	player.score += 1
	if player.score == game_config.questions_count:
		add_event(FSMGameEvents.END_GAME)

func _kill_all_answers():
	for option in options.duplicate():
		option.take_damage()		

func _on_answer_killed(answer: Answer) -> void:
	options.erase(answer)
	if len(options) == 0:
		_makeNewRound()

func _get_damage() -> void:
	player.health -= 1
	if player.health == 0:
		add_event(FSMGameEvents.END_GAME)
