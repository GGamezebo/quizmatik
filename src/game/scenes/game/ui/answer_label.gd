extends Label

## Question banner text; during the angry-boss shoot-out (no questions) shows `rage_text`.

@export var game_events: GameEvents
@export var rage_text: String = "Огонь!"

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if game_events:
		_listener.add(game_events.ev_boss_enraged, _on_boss_enraged)


func _exit_tree() -> void:
	_listener.deinit()


func _on_game_state_ev_question_changed(question: QuizQuestion.Question) -> void:
	text = question.text


func _on_boss_enraged(_hits: int) -> void:
	text = rage_text
