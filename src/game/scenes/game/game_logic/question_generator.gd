class_name QuizQuestion
extends RefCounted


class Question:
	var text: String
	var options: Array
	var correct_answer: int
	## `MathFact` key of the underlying example (same for `7 x 8`, `56 / 8`, `? x 8 = 56`).
	var fact_key: String = ""


## `score` = correct answers so far (gates `missing_operand_start_progress`).
## With `review_chance` re-asks one of `review_facts` (past mistakes) when it fits the level.
static func generate_question(gameConfig: GameConfig, score: int = 0) -> Question:
	var active_operations: Array[int] = _active_operations(gameConfig)
	var picked: Array = []
	if not gameConfig.review_facts.is_empty() and randf() < gameConfig.review_chance:
		picked = _pick_review(gameConfig, active_operations)
	if picked.is_empty():
		var operation: int = active_operations.pick_random()
		var operand_range: Vector2i = gameConfig.get_operation_range(operation)
		picked = [
			operation,
			randi_range(operand_range.x, operand_range.y),
			randi_range(operand_range.x, operand_range.y),
		]
	return _build_question(gameConfig, score, picked[0], picked[1], picked[2])


static func _active_operations(gameConfig: GameConfig) -> Array[int]:
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
	return active_operations


## Weighted pick among `review_facts` that can be phrased with an allowed operation inside its
## operand range. Returns `[operation, a, b]` in generator terms, or `[]` when nothing fits.
static func _pick_review(gameConfig: GameConfig, active_operations: Array[int]) -> Array:
	var candidates: Array = []
	var total_weight: int = 0
	for fact_key in gameConfig.review_facts:
		var parsed: Array = MathFact.parse(String(fact_key))
		if parsed.is_empty():
			continue
		var variants: Array = []
		for operation in active_operations:
			variants.append_array(_review_variants(operation, parsed, gameConfig.get_operation_range(operation)))
		if variants.is_empty():
			continue
		var weight: int = maxi(1, int(gameConfig.review_facts[fact_key]))
		candidates.append([weight, variants])
		total_weight += weight
	if total_weight == 0:
		return []
	var roll: int = randi() % total_weight
	for entry in candidates:
		roll -= entry[0]
		if roll < 0:
			return (entry[1] as Array).pick_random()
	return []


## Ways to ask fact `[family, x, y]` with `operation`, as raw operands
## (subtraction: minuend, subtrahend; division: divisor, quotient) — all within `operand_range`.
static func _review_variants(operation: int, parsed: Array, operand_range: Vector2i) -> Array:
	var family: String = parsed[0]
	var x: int = parsed[1]
	var y: int = parsed[2]
	var fits := func(value: int) -> bool: return value >= operand_range.x and value <= operand_range.y
	var result: Array = []
	match operation:
		GameConfig.Operations.ADDITION, GameConfig.Operations.MULTIPLICATION:
			var expected: String = MathFact.FAMILY_ADD if operation == GameConfig.Operations.ADDITION else MathFact.FAMILY_MUL
			if family == expected and fits.call(x) and fits.call(y):
				result.append([operation, x, y])
				result.append([operation, y, x])
		GameConfig.Operations.SUBTRACTION:
			if family == MathFact.FAMILY_ADD and fits.call(x + y):
				for subtrahend in [x, y]:
					if fits.call(subtrahend):
						result.append([operation, x + y, subtrahend])
		GameConfig.Operations.DIVISION:
			if family == MathFact.FAMILY_MUL and fits.call(x) and fits.call(y):
				for divisor_and_quotient in [[x, y], [y, x]]:
					if divisor_and_quotient[0] >= 1:
						result.append([operation, divisor_and_quotient[0], divisor_and_quotient[1]])
	return result


## `a` / `b` are raw operands: subtraction swaps them so the result is never negative;
## division treats them as divisor / quotient.
static func _build_question(gameConfig: GameConfig, score: int, chosen_operation: int, a: int, b: int) -> Question:
	var q = QuizQuestion.Question.new()

	# Build question text and correct answer for the chosen operation
	var op_sign: String = ""
	# Operands the classic wrong-answer generators expect (division: divisor, quotient).
	var fake_a: int
	var fake_b: int
	match chosen_operation:
		GameConfig.Operations.ADDITION:
			op_sign = "+"
			q.correct_answer = a + b
			q.fact_key = MathFact.make_key(MathFact.FAMILY_ADD, a, b)

		GameConfig.Operations.SUBTRACTION:
			# Ensure a >= b so the result is never negative
			if a < b:
				var temp = a
				a = b
				b = temp
			op_sign = "-"
			q.correct_answer = a - b
			q.fact_key = MathFact.make_key(MathFact.FAMILY_ADD, a - b, b)

		GameConfig.Operations.MULTIPLICATION:
			op_sign = "x"
			q.correct_answer = a * b
			q.fact_key = MathFact.make_key(MathFact.FAMILY_MUL, a, b)

		GameConfig.Operations.DIVISION:
			# Division without remainder: build dividend as a * b
			# Example: a = 5, b = 3 → 15 / 5 = ? (answer 3)
			var divisor: int = maxi(a, 1)  # never `x / 0`
			var quotient: int = b
			q.correct_answer = quotient
			q.fact_key = MathFact.make_key(MathFact.FAMILY_MUL, divisor, quotient)
			a = divisor * quotient
			b = divisor
			op_sign = "/"
			fake_a = divisor
			fake_b = quotient
	if chosen_operation != GameConfig.Operations.DIVISION:
		fake_a = a
		fake_b = b
	
	q.text = "%d %s %d = ?" % [a, op_sign, b]
	if randf() < gameConfig.missing_operand_chance_at(score) and _hide_operand(q, chosen_operation, a, b, op_sign):
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
			fake_answer = _generate_plausible_fake(fake_a, fake_b, q.correct_answer, chosen_operation, options_set)
		
		if not fake_answer in options_set:
			options_set.append(fake_answer)
	
	# Shuffle options
	options_set.shuffle()
	q.options = options_set
	
	return q

## Turns `a op b = r` into `? op b = r` or `a op ? = r`. False when the hidden value would be ambiguous.
static func _hide_operand(q: Question, operation: int, a: int, b: int, op_sign: String) -> bool:
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
		q.text = "? %s %d = %d" % [op_sign, b, result]
	else:
		q.correct_answer = b
		q.text = "%d %s ? = %d" % [a, op_sign, result]
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


## Wrong answers a child could really get: times-table neighbours / near results.
## Multiplication: `a`, `b` = factors. Division: `a` = divisor, `b` = quotient (= `correct`).
static func _generate_plausible_fake(a: int, b: int, correct: int, operation: int, existing: Array) -> int:
	var candidates: Array[int] = []
	if operation == GameConfig.Operations.MULTIPLICATION:
		# Neighbouring times-table rows/columns, slips by 1–2, same last digit, `+` instead of `x`
		candidates.append_array([(a - 1) * b, (a + 1) * b, a * (b - 1), a * (b + 1)])
		candidates.append_array([correct - 1, correct + 1, correct - 2, correct + 2])
		candidates.append_array([correct - 10, correct + 10, a + b])
	else:
		# Quotient off by 1–3; divisor itself is a common mix-up
		for offset in [-1, 1, -2, 2, -3, 3]:
			candidates.append(correct + offset)
		candidates.append(a)

	# Multiplication: drop options that give themselves away by size (`9 x 9` → 18, `6 x 3` → 28).
	@warning_ignore("integer_division")
	var max_distance: int = maxi(3, correct / 2) if operation == GameConfig.Operations.MULTIPLICATION else 1 << 30
	var valid: Array[int] = []
	for candidate in candidates:
		if candidate < 0 or candidate == correct or candidate in existing or candidate in valid:
			continue
		if absi(candidate - correct) > max_distance:
			continue
		valid.append(candidate)

	if not valid.is_empty():
		return valid.pick_random()

	return correct + randi_range(1, 4)
