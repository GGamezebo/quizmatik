extends Label

## Question banner text; during the angry-boss shoot-out (no questions) shows `rage_text`,
## at the golden flight final pick `golden_choice_text`.

@export var game_events: GameEvents
@export var rage_text: String = "Огонь!"
@export var golden_choice_text: String = "Выбери шарик!"
## Font size for the long golden-choice line (questions use the scene size).
@export var golden_choice_font_size: int = 38

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if game_events:
		_listener.add(game_events.ev_boss_enraged, _on_boss_enraged)
		_listener.add(game_events.ev_golden_choice, _on_golden_choice)


func _exit_tree() -> void:
	_listener.deinit()


func _on_game_state_ev_question_changed(question: QuizQuestion.Question) -> void:
	text = question.text


func _on_boss_enraged(_hits: int) -> void:
	text = rage_text


func _on_golden_choice() -> void:
	add_theme_font_size_override("font_size", golden_choice_font_size)
	text = golden_choice_text
