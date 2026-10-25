class_name QuizQuestion
extends RefCounted


class Question:
	var text: String
	var options: Array
	var correct_answer: int
	## `MathFact` key of the underlying example (same for `7 x 8`, `56 / 8`, `? x 8 = 56`).
	var fact_key: String = ""
	## `? + 3 = 7` / `4 + ? = 7` — the answer is a hidden operand, not the result.
	var missing_operand: bool = false
	## Expert `? + ? = 9`: both hidden operands in order (`correct_answer` = the first); empty = one answer.
	var pair: Array[int] = []
	var pair_operation: int = 0
	var pair_result: int = 0
	## The solved example («4 + 5 = 9») shown after a miss.
	var pair_solution: String = ""

	## Expert pair: `first ⊕ second` gives the result (order matters for − and ÷).
	func is_pair_solution(first: int, second: int) -> bool:
		return QuizQuestion.pair_solves(pair_operation, first, second, pair_result)

	## A balloon this round can't do without: the answer, or one of the hidden pair.
	func is_key_value(value: int) -> bool:
		return value == correct_answer or value in pair


## Random operand pairs tried per question before falling back to the last one.
const PICK_ATTEMPTS: int = 40
## Re-rolls when the example repeats the previous one (`avoid_fact_key`).
const REPEAT_ATTEMPTS: int = 4


## `score` = correct answers so far (gates `missing_operand_start_progress`).
## With `review_chance` re-asks one of `review_facts` (past mistakes) when it fits the level.
## `avoid_fact_key` = previous question's fact: never the same example twice in a row.
static func generate_question(gameConfig: GameConfig, score: int = 0, avoid_fact_key: String = "") -> Question:
	var active_operations: Array[int] = _active_operations(gameConfig)
	var picked: Array = []
	if not gameConfig.review_facts.is_empty() and randf() < gameConfig.review_chance:
		picked = _pick_review(gameConfig, active_operations, avoid_fact_key)
	if picked.is_empty():
		for attempt in REPEAT_ATTEMPTS:
			picked = _pick_random(gameConfig, active_operations.pick_random())
			if avoid_fact_key.is_empty() or _fact_key_of(picked) != avoid_fact_key:
				break
	if gameConfig.hidden_pair:
		return _generate_pair(gameConfig, active_operations, picked)
	return _build_question(gameConfig, score, picked[0], picked[1], picked[2])


## Expert `? ⊕ ? = r`: re-picks until the pair reads well (two different operands; × / ÷ by 1 only as a last resort).
static func _generate_pair(gameConfig: GameConfig, active_operations: Array[int], picked: Array) -> Question:
	var fallback: Question = null
	for attempt in PICK_ATTEMPTS:
		var question: Question = _build_pair_question(gameConfig, picked[0], picked[1], picked[2])
		if question != null:
			var trivial: bool = question.pair[1] == 1 and question.pair_operation in [
				GameConfig.Operations.MULTIPLICATION, GameConfig.Operations.DIVISION]
			if question.pair[0] != question.pair[1] and not trivial:
				return question
			if fallback == null or fallback.pair[0] == fallback.pair[1]:
				fallback = question
		picked = _pick_random(gameConfig, active_operations.pick_random())
	if fallback != null:
		return fallback
	return _build_question(gameConfig, 0, picked[0], picked[1], picked[2])


## Same raw operands as `_build_question` (division: divisor, quotient); null for ops without a pair (², √) or a 0 result.
static func _build_pair_question(gameConfig: GameConfig, operation: int, a: int, b: int) -> Question:
	var left: int = a
	var right: int = b
	var sign: String
	match operation:
		GameConfig.Operations.ADDITION, GameConfig.Operations.MULTIPLICATION:
			if randi() % 2 == 0:
				left = b
				right = a
			sign = "+" if operation == GameConfig.Operations.ADDITION else "x"
		GameConfig.Operations.SUBTRACTION:
			left = maxi(a, b)
			right = mini(a, b)
			sign = "-"
		GameConfig.Operations.DIVISION:
			right = maxi(a, 1)
			left = right * b
			sign = "/"
		_:
			return null
	var q := Question.new()
	q.pair_operation = operation
	match operation:
		GameConfig.Operations.ADDITION:
			q.pair_result = left + right
			q.fact_key = MathFact.make_key(MathFact.FAMILY_ADD, left, right)
		GameConfig.Operations.SUBTRACTION:
			q.pair_result = left - right
			q.fact_key = MathFact.make_key(MathFact.FAMILY_ADD, left - right, right)
		GameConfig.Operations.MULTIPLICATION:
			q.pair_result = left * right
			q.fact_key = MathFact.make_key(MathFact.FAMILY_MUL, left, right)
		GameConfig.Operations.DIVISION:
			q.pair_result = b
			q.fact_key = MathFact.make_key(MathFact.FAMILY_MUL, right, b)
	if q.pair_result <= 0 or left <= 0 or right <= 0:
		return null
	q.pair = [left, right]
	q.correct_answer = left
	q.text = "? %s ? = %d" % [sign, q.pair_result]
	q.pair_solution = "%d %s %d = %d" % [left, sign, right, q.pair_result]
	q.options = _pair_options(operation, left, right, q.pair_result, gameConfig.answer_lines_count)
	return q


## The pair + near numbers (±1..3 of both; ÷: dividend ± divisor) that make no other solving pair with any option.
static func _pair_options(operation: int, left: int, right: int, result: int, count: int) -> Array:
	var options: Array = [left, right]
	var candidates: Array[int] = []
	for base in [left, right]:
		for offset in [-1, 1, -2, 2, -3, 3]:
			candidates.append(base + offset)
	if operation == GameConfig.Operations.DIVISION:
		candidates.append_array([left - right, left + right])
	candidates.shuffle()
	for candidate in candidates:
		if options.size() >= count:
			break
		if _pair_option_fits(operation, candidate, options, result):
			options.append(candidate)
	var extra: int = maxi(left, right) + 4
	while options.size() < count:
		if _pair_option_fits(operation, extra, options, result):
			options.append(extra)
		extra += 1
	options.shuffle()
	return options


static func _pair_option_fits(operation: int, candidate: int, options: Array, result: int) -> bool:
	if candidate < 1 or candidate in options:
		return false
	for option in options:
		if pair_solves(operation, option, candidate, result) or pair_solves(operation, candidate, option, result):
			return false
	return true


## `first ⊕ second == result` (÷ without remainder).
@warning_ignore("integer_division")
static func pair_solves(operation: int, first: int, second: int, result: int) -> bool:
	match operation:
		GameConfig.Operations.ADDITION:
			return first + second == result
		GameConfig.Operations.SUBTRACTION:
			return first - second == result
		GameConfig.Operations.MULTIPLICATION:
			return first * second == result
		GameConfig.Operations.DIVISION:
			return second != 0 and first % second == 0 and first / second == result
	return false


## `[operation, a, b]` from the op's operand ranges that passes `_fits` (last try otherwise).
static func _pick_random(gameConfig: GameConfig, operation: int) -> Array:
	var first: Vector2i = gameConfig.get_operation_range(operation)
	var second: Vector2i = gameConfig.get_second_operand_range(operation)
	var picked: Array = []
	for attempt in PICK_ATTEMPTS:
		picked = [operation, randi_range(first.x, first.y), randi_range(second.x, second.y)]
		if _fits(gameConfig, operation, picked[1], picked[2]):
			break
	return picked


## Answer range + carry rule for raw operands (−: minuend ≥ subtrahend; ÷: divisor, quotient).
static func _fits(gameConfig: GameConfig, operation: int, a: int, b: int) -> bool:
	var result: int
	match operation:
		GameConfig.Operations.ADDITION:
			result = a + b
		GameConfig.Operations.SUBTRACTION:
			result = a - b
		GameConfig.Operations.MULTIPLICATION:
			result = a * b
		GameConfig.Operations.SQUARE:
			result = a * a
		GameConfig.Operations.ROOT:
			result = a
		_:
			result = b
	if result < 0:
		return false
	var allowed: Vector2i = gameConfig.get_result_range(operation)
	if result < allowed.x or result > allowed.y:
		return false
	if gameConfig.carry_mode == GameConfig.CarryMode.ANY:
		return true
	var carries: bool
	match operation:
		GameConfig.Operations.ADDITION:
			carries = a % 10 + b % 10 >= 10
		GameConfig.Operations.SUBTRACTION:
			carries = a % 10 < b % 10
		_:
			return true
	return carries == (gameConfig.carry_mode == GameConfig.CarryMode.REQUIRED)


static func _fact_key_of(picked: Array) -> String:
	var a: int = picked[1]
	var b: int = picked[2]
	match picked[0]:
		GameConfig.Operations.ADDITION:
			return MathFact.make_key(MathFact.FAMILY_ADD, a, b)
		GameConfig.Operations.SUBTRACTION:
			return MathFact.make_key(MathFact.FAMILY_ADD, absi(a - b), mini(a, b))
		GameConfig.Operations.SQUARE, GameConfig.Operations.ROOT:
			return MathFact.make_key(MathFact.FAMILY_MUL, a, a)
	return MathFact.make_key(MathFact.FAMILY_MUL, a, b)


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
	if gameConfig.allowed_operations & GameConfig.Operations.SQUARE:
		active_operations.append(GameConfig.Operations.SQUARE)
	if gameConfig.allowed_operations & GameConfig.Operations.ROOT:
		active_operations.append(GameConfig.Operations.ROOT)
		
	if active_operations.is_empty():
		active_operations.append(GameConfig.Operations.MULTIPLICATION)
	return active_operations


## Weighted pick among `review_facts` that can be phrased with an allowed operation inside its
## operand ranges (+ answer / carry rules). Returns `[operation, a, b]` in generator terms, or `[]` when nothing fits.
static func _pick_review(gameConfig: GameConfig, active_operations: Array[int], avoid_fact_key: String = "") -> Array:
	var candidates: Array = []
	var total_weight: int = 0
	for fact_key in gameConfig.review_facts:
		var parsed: Array = MathFact.parse(String(fact_key))
		if parsed.is_empty() or MathFact.make_key(parsed[0], parsed[1], parsed[2]) == avoid_fact_key:
			continue
		var variants: Array = []
		for operation in active_operations:
			for variant in _review_variants(operation, parsed, gameConfig):
				if _fits(gameConfig, variant[0], variant[1], variant[2]):
					variants.append(variant)
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
## (subtraction: minuend, subtrahend; division: divisor, quotient) — first / second operand inside their op ranges.
static func _review_variants(operation: int, parsed: Array, gameConfig: GameConfig) -> Array:
	var family: String = parsed[0]
	var x: int = parsed[1]
	var y: int = parsed[2]
	var first: Vector2i = gameConfig.get_operation_range(operation)
	var second: Vector2i = gameConfig.get_second_operand_range(operation)
	var fits := func(a: int, b: int) -> bool:
		return a >= first.x and a <= first.y and b >= second.x and b <= second.y
	var pairs: Array = []
	match operation:
		GameConfig.Operations.ADDITION:
			if family == MathFact.FAMILY_ADD:
				pairs = [[x, y], [y, x]]
		GameConfig.Operations.MULTIPLICATION:
			if family == MathFact.FAMILY_MUL:
				pairs = [[x, y], [y, x]]
		GameConfig.Operations.SUBTRACTION:
			if family == MathFact.FAMILY_ADD:
				pairs = [[x + y, x], [x + y, y]]
		GameConfig.Operations.DIVISION:
			if family == MathFact.FAMILY_MUL:
				pairs = [[x, y], [y, x]]
		GameConfig.Operations.SQUARE, GameConfig.Operations.ROOT:
			if family == MathFact.FAMILY_MUL and x == y:
				pairs = [[x, x]]
	var result: Array = []
	for pair in pairs:
		if operation == GameConfig.Operations.DIVISION and pair[0] < 1:
			continue
		if fits.call(pair[0], pair[1]):
			var variant: Array = [operation, pair[0], pair[1]]
			if not variant in result:
				result.append(variant)
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
	# `3 + 45` / `7 x 4`: commutative ops show the ranged operands in either order.
	if (chosen_operation == GameConfig.Operations.ADDITION or chosen_operation == GameConfig.Operations.MULTIPLICATION) \
			and randi() % 2 == 0:
		var swapped: int = a
		a = b
		b = swapped
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
	if chosen_operation == GameConfig.Operations.SQUARE or chosen_operation == GameConfig.Operations.ROOT:
		return _build_power_question(q, chosen_operation, a, gameConfig.answer_lines_count)
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

## `n² = ?` / `√(n²) = ?` (fact `mul:n:n`; never a hidden operand). Wrong options a child really gives:
## square — `2n` (n² read as n×2), neighbour squares, ±1..2, ±10; root — n ± 1..3.
static func _build_power_question(q: Question, operation: int, n: int, count: int) -> Question:
	var square: int = n * n
	var candidates: Array[int] = []
	if operation == GameConfig.Operations.SQUARE:
		q.text = "%d² = ?" % n
		q.correct_answer = square
		candidates.append_array([n * 2, (n - 1) * (n - 1), (n + 1) * (n + 1), n * (n + 1), n * (n - 1)])
		candidates.append_array([square - 1, square + 1, square - 2, square + 2, square - 10, square + 10])
	else:
		q.text = "√%d = ?" % square
		q.correct_answer = n
		candidates.append_array([n - 1, n + 1, n - 2, n + 2, n - 3, n + 3])
	q.fact_key = MathFact.make_key(MathFact.FAMILY_MUL, n, n)
	# Same give-away rule as ×: nothing far off by size.
	@warning_ignore("integer_division")
	var max_distance: int = maxi(3, q.correct_answer / 2)
	candidates.shuffle()
	var options: Array = [q.correct_answer]
	for candidate in candidates:
		if options.size() >= count:
			break
		if candidate >= 0 and not candidate in options and absi(candidate - q.correct_answer) <= max_distance:
			options.append(candidate)
	var extra: int = q.correct_answer + 1
	while options.size() < count:
		if not extra in options:
			options.append(extra)
		extra += 1
	options.shuffle()
	q.options = options
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
	q.missing_operand = true
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
	# Two-digit work: a forgotten / extra carry is off by ten — kids can't pick by the last digit alone.
	if correct >= 20 or maxi(a, b) >= 20:
		candidates.append_array([correct - 10, correct + 10])

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
