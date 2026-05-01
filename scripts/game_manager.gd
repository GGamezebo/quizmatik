extends Node2D

class_name GameManager

signal ev_selected_lane_changed
signal ev_question_changed

var time:float = 0.0

var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()
				
var question: QuizQuestion:
	set(new_question):
		question = new_question
		ev_question_changed.emit(question)


@export var player: Node2D
@export var area: GameArea
@export var gameConfig: GameConfig
@export var answerScene: PackedScene


func _ready() -> void:
	makeNewRound()

	
func _process(delta: float) -> void:
	time += delta
	selected_lane = area.getLine(player.position)
	
	
func makeNewRound():
	self.question = generate_question()
	self.makeAnswers()
	

# Структура для хранения вопроса
class QuizQuestion:
	var text: String
	var options: Array
	var correct_answer: int


func generate_question() -> QuizQuestion:
	var q = QuizQuestion.new()
	
	# 1. Выбираем случайные множители
	var a = randi_range(2, 9)
	var b = randi_range(2, 9)
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
		var answer = answerScene.instantiate()
		var line: Rect2 = lines[index]
		var x:float = area.gameplay_area.end.x + 120
		var y:float = line.position.y + line.size.y / 2.0
		answer.position.x = x
		answer.position.y = x
		answer.setup(x, y, option)
		get_tree().root.add_child.call_deferred(answer)
			
			
