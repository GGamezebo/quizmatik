class_name GameEvents
extends Resource

@warning_ignore("unused_signal") signal ev_game_state_changed(from_state: String, to_state: String)
@warning_ignore("unused_signal") signal ev_explosion(answer: Answer, hit_point: Vector2)
@warning_ignore("unused_signal") signal ev_shoot
@warning_ignore("unused_signal") signal ev_correct_answer
@warning_ignore("unused_signal") signal ev_mistake
@warning_ignore("unused_signal") signal ev_win
@warning_ignore("unused_signal") signal ev_lose
