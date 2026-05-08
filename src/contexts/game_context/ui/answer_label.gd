extends Label

func _on_game_state_ev_question_changed(question: QuizQuestion.Question) -> void:
	text = question.text
