class_name GameManager
extends Node2D

signal ev_selected_lane_changed
signal ev_question_changed

@export var player: Player
@export var area: GameArea
@export var gameConfig: GameConfig
@export var answerScene: PackedScene
@export var game_events: GameEvents
@export var root_events: RootEvents

var time:float = 0.0
var options: Array[Answer] = []

var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()
				
var question: QuizQuestion:
	set(new_question):
		question = new_question
		ev_question_changed.emit(question)

@onready var event_listener:EventListener = EventListener.new()
@onready var health:int = gameConfig.health:
	set(new_value):
		if health != new_value:
			health = new_value
			game_events.ev_health_changed.emit(health)
			if health == 0:
				root_events.ev_exit_game.emit()

func _ready() -> void:
	event_listener.add(game_events.ev_explosion, _on_event_manager_ev_explosion)
	makeNewRound()

func _exit_tree() -> void:
	event_listener.deinit()
	
func _process(delta: float) -> void:
	time += delta
	selected_lane = area.getLine(player.position)
	
	
func makeNewRound() -> void:
	self.question = generate_question()
	await get_tree().create_timer(1.0).timeout
	self.makeAnswers()
	

# Структура для хранения вопроса
class QuizQuestion:
	var text: String
	var options: Array
	var correct_answer: int


func generate_question() -> QuizQuestion:
	var q = QuizQuestion.new()
	
	# 1. Выбираем случайные множители
	var a = randi_range(gameConfig.min_generate_number, gameConfig.max_generate_number)
	var b = randi_range(gameConfig.min_generate_number, gameConfig.max_generate_number)
	q.correct_answer = a * b
	q.text = str(a) + " x " + str(b) + " = ?"
	
	# 2. Генерируем варианты ответов
	var options_set = [q.correct_answer]
	
	while options_set.size() < gameConfig.answer_lines_count:
		var fake_answer = _generate_plausible_fake(a, b, q.correct_answer)
		
		if not fake_answer in options_set:
			options_set.append(fake_answer)
	
	# 3. Перемешиваем ответы
	options_set.shuffle()
	q.options = options_set
	
	return q

# Создаем "правдоподобные" ошибки
func _generate_plausible_fake(a: int, b: int, correct: int) -> int:
	var strategy = randi() % 3
	var fake = 0
	
	match strategy:
		0: # Ошибка в одном из множителей на +/- 1
			fake = (a + [-1, 1].pick_random()) * b
		1: # Ошибка в результате на +/- 1, 2 или 10
			fake = correct + [-1, 1, 2, -2, 10, -10].pick_random()
		2: # Просто случайное число в разумных пределах
			fake = randi_range(4, 81)
			
	# Защита от отрицательных чисел и нуля
	return abs(fake) if fake != 0 else correct + 5
	
func makeAnswers() -> void:
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
		owner.add_child.call_deferred(answer)
			
			
func _on_event_manager_ev_explosion(answer: Answer) -> void:
	if answer.value == self.question.correct_answer:
		_kill_all_answers()
	else:
		var index:int = options.find(answer)
		if index != -1:
			health -= 1
			options.remove_at(index)
			answer.take_damage()

func _kill_all_answers():
	for option in options:
		option.take_damage()			
			
func _on_player_colladed(_player:Player, answer: Answer) -> void:
	if answer.value == self.question.correct_answer:
		_kill_all_answers()
	else:
		var index:int = options.find(answer)
		if index != -1:
			health -= 1
			_kill_all_answers()

func _on_answer_killed(answer:Answer):
	options.erase(answer)
	if len(options) == 0:
		self.makeNewRound()
