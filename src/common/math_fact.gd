class_name MathFact
extends RefCounted

## Math fact family shared by inverse operations — the unit we remember mistakes by.
## `add:3:5` = 3 + 5, 5 + 3, 8 - 3, 8 - 5 (and their `?` forms); `mul:7:8` = 7 x 8, 56 / 7, 56 / 8.

const FAMILY_ADD: String = "add"
const FAMILY_MUL: String = "mul"


static func make_key(family: String, x: int, y: int) -> String:
	return "%s:%d:%d" % [family, mini(x, y), maxi(x, y)]


## `[family, x, y]` or `[]` for a malformed key.
static func parse(key: String) -> Array:
	var parts: PackedStringArray = key.split(":")
	if parts.size() != 3 or not (parts[0] in [FAMILY_ADD, FAMILY_MUL]):
		return []
	if not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return []
	return [parts[0], parts[1].to_int(), parts[2].to_int()]


## Human form for UI: `7 × 8`, `3 + 5`.
static func display(key: String) -> String:
	var parsed: Array = parse(key)
	if parsed.is_empty():
		return ""
	var op_sign: String = "×" if parsed[0] == FAMILY_MUL else "+"
	return "%d %s %d" % [parsed[1], op_sign, parsed[2]]


## `7 × 8 = 56`, `3 + 5 = 8`.
static func display_with_answer(key: String) -> String:
	var parsed: Array = parse(key)
	if parsed.is_empty():
		return ""
	var answer: int = parsed[1] * parsed[2] if parsed[0] == FAMILY_MUL else parsed[1] + parsed[2]
	return "%s = %d" % [display(key), answer]
