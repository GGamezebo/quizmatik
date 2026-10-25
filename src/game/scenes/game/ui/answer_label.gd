extends MathLabel

## Question banner text; during the angry-boss shoot-out (no questions) shows `rage_text`,
## at the golden flight final pick `golden_choice_text`. Roots («√144 = ?») drawn bold by `MathLabel`.
## Expert «? + ? = 9»: each shot number flies from its balloon into its blank (`pair_fly_labels`), the verdict
## flashes after the second lands; a miss shows the solved example (`ev_pair_result` solution) in its place.

@export var game_events: GameEvents
@export var rage_text: String = "Огонь!"
@export var golden_choice_text: String = "Выбери шарик!"
## Font size for the long golden-choice line (questions use the scene size).
@export var golden_choice_font_size: int = 38

@export_group("Expert pair")
## One flying number per blank (slot 0 / 1), editor-made, `top_level`, hidden until a pick.
@export var pair_fly_labels: Array[Label] = []
@export var pair_fly_sec: float = 0.5
@export var pair_right_color: Color = Color(0.2, 0.55, 0.3)
@export var pair_wrong_color: Color = Color(0.78, 0.25, 0.22)
## How long the wrong numbers stay red before the solution replaces them.
@export var pair_wrong_sec: float = 0.55

const BLANK := "?"

var _listener: EventListener = EventListener.new()
var _ink: Color
var _flights: Array[Tween] = [null, null]
var _flash: Tween
## Verdict waiting for the second number to land: [correct, solution].
var _pending_result: Array = []
var _home_x: float = 0.0


func _ready() -> void:
	_ink = get_theme_color("font_color")
	_home_x = position.x
	for fly in pair_fly_labels:
		fly.hide()
	if game_events:
		_listener.add(game_events.ev_boss_enraged, _on_boss_enraged)
		_listener.add(game_events.ev_golden_choice, _on_golden_choice)
		_listener.add(game_events.ev_pair_pick, _on_pair_pick)
		_listener.add(game_events.ev_pair_result, _on_pair_result)


func _exit_tree() -> void:
	_listener.deinit()


func _on_game_state_ev_question_changed(question: QuizQuestion.Question) -> void:
	_reset_pair()
	set_math_text(question.text)


func _on_boss_enraged(_hits: int) -> void:
	set_math_text(rage_text)


func _on_golden_choice() -> void:
	add_theme_font_size_override("font_size", golden_choice_font_size)
	set_math_text(golden_choice_text)


func _on_pair_pick(slot: int, value: int, from_global: Vector2) -> void:
	if slot < 0 or slot >= pair_fly_labels.size():
		return
	var fly: Label = pair_fly_labels[slot]
	var target: Vector2 = _blank_center(slot)
	if is_nan(target.x):
		return
	fly.text = str(value)
	fly.reset_size()
	fly.pivot_offset = fly.size * 0.5
	fly.global_position = from_global - fly.size * 0.5
	fly.scale = Vector2.ONE * 1.4
	fly.show()
	if _flights[slot]:
		_flights[slot].kill()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fly, "global_position", target - fly.size * 0.5, pair_fly_sec)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fly, "scale", Vector2.ONE, pair_fly_sec).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(fly, "rotation", TAU, pair_fly_sec).from(0.0)
	tween.chain().tween_callback(_land.bind(slot, value))
	_flights[slot] = tween


func _on_pair_result(correct: bool, solution: String) -> void:
	if _flights[1] != null and _flights[1].is_running():
		_pending_result = [correct, solution]
		return
	_show_result(correct, solution)


## The number takes its blank: the label text gets it, the flying copy hides.
func _land(slot: int, value: int) -> void:
	pair_fly_labels[slot].hide()
	_flights[slot] = null
	var index: int = text.find(BLANK) if slot == 0 else text.rfind(BLANK)
	if index >= 0:
		set_math_text(text.substr(0, index) + str(value) + text.substr(index + BLANK.length()))
	_pop(1.12)
	if slot == 1 and not _pending_result.is_empty():
		var result: Array = _pending_result
		_pending_result = []
		_show_result(result[0], result[1])


func _show_result(correct: bool, solution: String) -> void:
	if _flash:
		_flash.kill()
	if correct:
		_set_ink(pair_right_color)
		_pop(1.2)
		return
	_set_ink(pair_wrong_color)
	_flash = create_tween()
	for i in 3:
		_flash.tween_property(self, "position:x", _home_x + 9.0, 0.05)
		_flash.tween_property(self, "position:x", _home_x - 9.0, 0.05)
	_flash.tween_property(self, "position:x", _home_x, 0.05)
	_flash.tween_interval(pair_wrong_sec)
	_flash.tween_callback(func() -> void:
		set_math_text(solution)
		_set_ink(_ink)
		_pop(1.15)
	)


func _reset_pair() -> void:
	for slot in _flights.size():
		if _flights[slot]:
			_flights[slot].kill()
			_flights[slot] = null
	for fly in pair_fly_labels:
		fly.hide()
	if _flash:
		_flash.kill()
	_pending_result = []
	scale = Vector2.ONE
	position.x = _home_x
	_set_ink(_ink)


func _set_ink(color: Color) -> void:
	add_theme_color_override("font_color", color)


func _pop(size: float) -> void:
	pivot_offset = self.size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * size, 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Screen center of blank `slot` (0 = first «?», 1 = last) in the current text; NAN when it is filled already.
func _blank_center(slot: int) -> Vector2:
	var index: int = text.find(BLANK) if slot == 0 else text.rfind(BLANK)
	if index < 0:
		return Vector2(NAN, NAN)
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var full: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var before: float = font.get_string_size(text.substr(0, index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var blank: float = font.get_string_size(BLANK, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x0: float = (size.x - full) * 0.5 if horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER else 0.0
	return get_global_transform() * Vector2(x0 + before + blank * 0.5, size.y * 0.5)
