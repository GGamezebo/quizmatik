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
	
	# Generate base operands
	var a = randi_range(gameConfig.min_generate_number, gameConfig.max_generate_number)
	var b = randi_range(gameConfig.min_generate_number, gameConfig.max_generate_number)
	
	# Build question text and correct answer for the chosen operation
	match chosen_operation:
		GameConfig.Operations.ADDITION:
			q.correct_answer = a + b
			q.text = str(a) + " + " + str(b) + " = ?"
			
		GameConfig.Operations.SUBTRACTION:
			# Ensure a >= b so the result is never negative
			if a < b:
				var temp = a
				a = b
				b = temp
			q.correct_answer = a - b
			q.text = str(a) + " - " + str(b) + " = ?"
			
		GameConfig.Operations.MULTIPLICATION:
			# Multiplication
			q.correct_answer = a * b
			q.text = str(a) + " x " + str(b) + " = ?"
			
		GameConfig.Operations.DIVISION:
			# Division without remainder: build dividend as a * b
			# Example: a = 5, b = 3 → 15 / 5 = ? (answer 3)
			var product = a * b
			q.correct_answer = b
			q.text = str(product) + " / " + str(a) + " = ?"
			
	# Generate wrong answer options
	var options_set = [q.correct_answer]
	
	while options_set.size() < gameConfig.answer_lines_count:
		# Plausible wrong answers based on operands and the correct result
		var fake_answer = _generate_plausible_fake(a, b, q.correct_answer)
		
		if not fake_answer in options_set:
			options_set.append(fake_answer)
	
	# Shuffle options
	options_set.shuffle()
	q.options = options_set
	
	return q

# Generate plausible wrong answers
static func _generate_plausible_fake(a: int, b: int, correct: int) -> int:
	var strategy = randi() % 3
	var fake = 0
	
	match strategy:
		0: # Off-by-one on one operand
			fake = (a + [-1, 1].pick_random()) * b
		1: # Off-by-one/two/ten on the result
			fake = correct + [-1, 1, 2, -2, 10, -10].pick_random()
		2: # Random number in a reasonable range
			fake = randi_range(4, 81)
			
	# Avoid negative values and zero
	return abs(fake) if fake != 0 else correct + 5
