class_name GameEvents
extends Resource

@warning_ignore("unused_signal") signal ev_game_state_changed(from_state: String, to_state: String)
@warning_ignore("unused_signal") signal ev_explosion(answer: Answer, hit_point: Vector2)
@warning_ignore("unused_signal") signal ev_shoot
@warning_ignore("unused_signal") signal ev_correct_answer
@warning_ignore("unused_signal") signal ev_mistake
## Info: verdict on the current question's `MathFact` key — once per question (wrong shot = false,
## correct without a prior wrong shot = true; plane collisions don't count).
@warning_ignore("unused_signal") signal ev_fact_answered(fact_key: String, is_correct: bool)
## Correct answer while streak >= GameConfig.streak_feedback_min.
@warning_ignore("unused_signal") signal ev_streak(streak: int)
## Heart restored by streak.
@warning_ignore("unused_signal") signal ev_health_restored
## Timed level: whole seconds left (emitted when the shown value changes).
@warning_ignore("unused_signal") signal ev_time_left(seconds: int)
## Golden bonus balloon popped (shot or ram) — `amount` gold granted after the battle.
@warning_ignore("unused_signal") signal ev_bonus_collected(amount: int)
@warning_ignore("unused_signal") signal ev_win
@warning_ignore("unused_signal") signal ev_lose

## Info for overlays (e.g. tutorial): round answers are on screen.
## `lanes` = lane rects in screen pixels (index = Answer.lane_index).
@warning_ignore("unused_signal") signal ev_answers_spawned(answers: Array, correct_value: int, lanes: Array)
## Info: plane lane changed, or it moved in/out of the lane's center band (lined up to hit).
@warning_ignore("unused_signal") signal ev_plane_lane_changed(lane: int, centered: bool)
## Command: stop / resume answer movement (plane still flies).
@warning_ignore("unused_signal") signal ev_pause_answers(paused: bool)
## Command: ignore shoot input while locked.
@warning_ignore("unused_signal") signal ev_lock_shoot(locked: bool)
