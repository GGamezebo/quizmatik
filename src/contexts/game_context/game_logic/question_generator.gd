class_name QuizQuestion
extends RefCounted


class Question:
	var text: String
	var options: Array
	var correct_answer: int


static func generate_question(gameConfig: GameConfig) -> Question:
	var q = QuizQuestion.Question.new()
	
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
static func _generate_plausible_fake(a: int, b: int, correct: int) -> int:
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
