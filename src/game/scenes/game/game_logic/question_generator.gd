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
	var operand_range: Vector2i = gameConfig.get_operation_range(chosen_operation)
	var a = randi_range(operand_range.x, operand_range.y)
	var b = randi_range(operand_range.x, operand_range.y)
	
	# Build question text and correct answer for the chosen operation
	var sign: String = ""
	# Operands the classic wrong-answer generators expect (division: divisor, quotient).
	var fake_a: int
	var fake_b: int
	match chosen_operation:
		GameConfig.Operations.ADDITION:
			sign = "+"
			q.correct_answer = a + b
			
		GameConfig.Operations.SUBTRACTION:
			# Ensure a >= b so the result is never negative
			if a < b:
				var temp = a
				a = b
				b = temp
			sign = "-"
			q.correct_answer = a - b
			
		GameConfig.Operations.MULTIPLICATION:
			sign = "x"
			q.correct_answer = a * b
			
		GameConfig.Operations.DIVISION:
			# Division without remainder: build dividend as a * b
			# Example: a = 5, b = 3 → 15 / 5 = ? (answer 3)
			var divisor: int = maxi(a, 1)  # never `x / 0`
			var quotient: int = b
			q.correct_answer = quotient
			a = divisor * quotient
			b = divisor
			sign = "/"
			fake_a = divisor
			fake_b = quotient
	if chosen_operation != GameConfig.Operations.DIVISION:
		fake_a = a
		fake_b = b
	
	q.text = "%d %s %d = ?" % [a, sign, b]
	if randf() < gameConfig.missing_operand_chance and _hide_operand(q, chosen_operation, a, b, sign):
		_fill_close_options(q, chosen_operation, a, b, gameConfig.answer_lines_count)
		return q
	
	# Generate wrong answer options
	var options_set = [q.correct_answer]
	var use_close_fakes: bool = chosen_operation == GameConfig.Operations.ADDITION \
		or chosen_operation == GameConfig.Operations.SUBTRACTION
	
	while options_set.size() < gameConfig.answer_lines_count:
		var fake_answer: int
		if use_close_fakes:
			fake_answer = _generate_close_fake_add_sub(fake_a, fake_b, q.correct_answer, chosen_operation, options_set)
		else:
			fake_answer = _generate_plausible_fake(fake_a, fake_b, q.correct_answer)
		
		if not fake_answer in options_set:
			options_set.append(fake_answer)
	
	# Shuffle options
	options_set.shuffle()
	q.options = options_set
	
	return q

## Turns `a op b = r` into `? op b = r` or `a op ? = r`. False when the hidden value would be ambiguous.
static func _hide_operand(q: Question, operation: int, a: int, b: int, sign: String) -> bool:
	var result: int = q.correct_answer
	var hide_left: bool = randi() % 2 == 0
	match operation:
		GameConfig.Operations.MULTIPLICATION:
			# `? x 0 = 0` has no single answer
			if (hide_left and b == 0) or (not hide_left and a == 0):
				hide_left = not hide_left
			if (hide_left and b == 0) or (not hide_left and a == 0):
				return false
		GameConfig.Operations.DIVISION:
			# `? / b = 0` / `a / ? = 0` / divisor 0 are ambiguous
			if result == 0 or b == 0:
				return false
	if hide_left:
		q.correct_answer = a
		q.text = "? %s %d = %d" % [sign, b, result]
	else:
		q.correct_answer = b
		q.text = "%d %s ? = %d" % [a, sign, result]
	return true


## Wrong options near the hidden operand: ±1..3, plus ±divisor for a hidden dividend.
static func _fill_close_options(q: Question, operation: int, a: int, b: int, count: int) -> void:
	var correct: int = q.correct_answer
	var min_value: int = 1 if operation == GameConfig.Operations.DIVISION and correct == b else 0
	var candidates: Array[int] = []
	for offset in [-1, 1, -2, 2, -3, 3]:
		candidates.append(correct + offset)
	if operation == GameConfig.Operations.DIVISION and correct == a:
		candidates.append_array([correct - b, correct + b])
	candidates.shuffle()
	var options: Array = [correct]
	for candidate in candidates:
		if options.size() >= count:
			break
		if candidate >= min_value and not candidate in options:
			options.append(candidate)
	var extra: int = correct + 4
	while options.size() < count:
		if not extra in options:
			options.append(extra)
		extra += 1
	options.shuffle()
	q.options = options


static func _generate_close_fake_add_sub(
	a: int,
	b: int,
	correct: int,
	operation: int,
	existing: Array,
) -> int:
	var candidates: Array[int] = []
	for offset in [-1, 1, -2, 2, -3, 3]:
		candidates.append(correct + offset)
	
	if operation == GameConfig.Operations.ADDITION:
		candidates.append_array([(a - 1) + b, (a + 1) + b, a + (b - 1), a + (b + 1)])
	else:
		candidates.append_array([(a - 1) - b, (a + 1) - b, a - (b - 1), a - (b + 1)])
	
	var valid: Array[int] = []
	for candidate in candidates:
		if candidate < 0 or candidate == correct or candidate in existing or candidate in valid:
			continue
		valid.append(candidate)
	
	if not valid.is_empty():
		return valid.pick_random()
	
	return maxi(0, correct + [-1, 1, 2, -2].pick_random())


# Generate plausible wrong answers for multiplication and division
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
