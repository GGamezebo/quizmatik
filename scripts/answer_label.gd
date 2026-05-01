extends Label


func _on_game_manager_ev_question_changed(question) -> void:
	text = question.text
