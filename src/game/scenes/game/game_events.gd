class_name GameEvents
extends Resource

@warning_ignore("unused_signal") signal ev_game_state_changed(from_state: String, to_state: String)
@warning_ignore("unused_signal") signal ev_explosion(answer: Answer, hit_point: Vector2)
@warning_ignore("unused_signal") signal ev_shoot
@warning_ignore("unused_signal") signal ev_correct_answer
@warning_ignore("unused_signal") signal ev_mistake
## Correct answer while streak >= GameConfig.streak_feedback_min.
@warning_ignore("unused_signal") signal ev_streak(streak: int)
## Heart restored by streak.
@warning_ignore("unused_signal") signal ev_health_restored
@warning_ignore("unused_signal") signal ev_win
@warning_ignore("unused_signal") signal ev_lose
