class_name QuizQuestion
extends RefCounted


class Question:
	var text: String
	var options: Array
	var correct_answer: int


static func generate_question(gameConfig: GameConfig) -> Question:
	var q = QuizQuestion.Question.new()
	
	var active_operations: Array[int] = []
	if gameConfig.allowed_operations & GameConfig.Operations.ADDITION:
		active_operations.append(GameConfig.Operations.ADDITION)
	if gameConfig.allowed_operations & GameConfig.Operations.SUBTRACTION:
		active_operations.append(GameConfig.Operations.SUBTRACTION)
	if gameConfig.allowed_operations & GameConfig.Operations.MULTIPLICATION:
		active_operations.append(GameConfig.Operations.MULTIPLICATION)
	if gameConfig.allowed_operations & GameConfig.Operations.DIVISION:
		active_operations.append(GameConfig.Operations.DIVISION)
		
	if active_operations.is_empty():
		active_operations.append(GameConfig.Operations.MULTIPLICATION)
		
	var chosen_operation = active_operations.pick_random()
	
	# Генерируем базовые числа
	var a = randi_range(gameConfig.min_generate_number, gameConfig.max_generate_number)
	var b = randi_range(gameConfig.min_generate_number, gameConfig.max_generate_number)
	
	# 2. Логика генерации в зависимости от выбранной операции
	match chosen_operation:
		GameConfig.Operations.ADDITION:
			q.correct_answer = a + b
			q.text = str(a) + " + " + str(b) + " = ?"
			
		GameConfig.Operations.SUBTRACTION:
			# Чтобы не было отрицательных ответов, гарантируем, что 'a' больше или равно 'b'
			if a < b:
				var temp = a
				a = b
				b = temp
			q.correct_answer = a - b
			q.text = str(a) + " - " + str(b) + " = ?"
			
		GameConfig.Operations.MULTIPLICATION:
			# Ваш оригинальный код умножения (без изменений)
			q.correct_answer = a * b
			q.text = str(a) + " x " + str(b) + " = ?"
			
		GameConfig.Operations.DIVISION:
			# Для деления без остатка мы сначала перемножаем числа, 
			# делая результат деления красивым целым числом.
			# Пример: a = 5, b = 3. Делаем делимое (a * b) = 15. Вопрос: 15 / 5 = ? (ответ 3)
			var product = a * b
			q.correct_answer = b
			q.text = str(product) + " / " + str(a) + " = ?"
			
	# 3. Генерируем варианты ответов (общая логика для всех операций)
	var options_set = [q.correct_answer]
	
	while options_set.size() < gameConfig.answer_lines_count:
		# Передаем в генератор фейков текущие числа и правильный ответ
		# (Вам может потребоваться адаптировать _generate_plausible_fake под другие знаки, 
		# но структура вызова остается прежней)
		var fake_answer = _generate_plausible_fake(a, b, q.correct_answer)
		
		if not fake_answer in options_set:
			options_set.append(fake_answer)
	
	# 4. Перемешиваем ответы
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
