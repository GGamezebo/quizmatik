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
## Endless battle: whole seconds survived (emitted when the shown value changes).
@warning_ignore("unused_signal") signal ev_endless_time(seconds: int)
## Golden bonus balloon popped (shot or ram) — `amount` gold granted after the battle.
@warning_ignore("unused_signal") signal ev_bonus_collected(amount: int)
## Boss airship flies in after the last regular answer (`armor` plates to knock off).
@warning_ignore("unused_signal") signal ev_boss_appeared(armor: int)
## A correct answer knocked a plate off the boss (0 = last one, it gets angry).
@warning_ignore("unused_signal") signal ev_boss_hit(armor_left: int)
## No armor left: the boss gets angry and creeps toward the plane — shoot it `hits` times.
@warning_ignore("unused_signal") signal ev_boss_enraged(hits: int)
## A shot hit the angry boss (0 = last one, it goes down).
@warning_ignore("unused_signal") signal ev_boss_shot(hits_left: int)
## Info: a shot hit a non-answer target (`shot_targets` group, e.g. the angry boss hull).
@warning_ignore("unused_signal") signal ev_target_shot(target: Area2D, hit_point: Vector2)
## Boss fell off-screen — the battle is won right after.
@warning_ignore("unused_signal") signal ev_boss_defeated
## Chase level: the airships fly in from the left.
@warning_ignore("unused_signal") signal ev_chase_started
## Chase level: the world is gray left of `edge_x` (screen px), reached over `duration` (0 = at once).
@warning_ignore("unused_signal") signal ev_chase_drain(edge_x: float, duration: float)
## Chase level: the airships closed in (`true`, tense music / growl) or fell back (`false`).
@warning_ignore("unused_signal") signal ev_chase_danger(close: bool)
## Info: expert «? + ? = 9» round on screen — `pair` = the hidden operands in order, `lanes` as in `ev_answers_spawned`.
@warning_ignore("unused_signal") signal ev_pair_spawned(answers: Array, pair: Array, lanes: Array)
## Expert round: a shot balloon's number flies into blank `slot` (0 / 1) of the question from `from_global`.
@warning_ignore("unused_signal") signal ev_pair_pick(slot: int, value: int, from_global: Vector2)
## Expert round decided: `correct`, or not — `solution` = the solved example to show instead.
@warning_ignore("unused_signal") signal ev_pair_result(correct: bool, solution: String)
## Golden flight time is up: no more questions, pick one of the choice balloons.
@warning_ignore("unused_signal") signal ev_golden_choice
@warning_ignore("unused_signal") signal ev_win
@warning_ignore("unused_signal") signal ev_lose

## Info for overlays (e.g. tutorial): round answers are on screen.
## `lanes` = lane rects in screen pixels (index = Answer.lane_index);
## `missing_operand` = question is `? + 3 = 7` style.
@warning_ignore("unused_signal") signal ev_answers_spawned(answers: Array, correct_value: int, lanes: Array, missing_operand: bool)
## Info: lane rects changed (window resize) — same format as `ev_answers_spawned` `lanes`.
@warning_ignore("unused_signal") signal ev_lanes_changed(lanes: Array)
## Info: plane lane changed, or it moved in/out of the lane's center band (lined up to hit).
@warning_ignore("unused_signal") signal ev_plane_lane_changed(lane: int, centered: bool)
## Command: stop / resume answer movement (plane still flies).
@warning_ignore("unused_signal") signal ev_pause_answers(paused: bool)
## Info: CountDown entered. An overlay may answer right in the handler with `ev_hold_countdown(true)`
## (the plane spawn waits a frame for it).
@warning_ignore("unused_signal") signal ev_countdown_entered
## Command: hold / release the countdown (plane spawn animation waits while held).
@warning_ignore("unused_signal") signal ev_hold_countdown(held: bool)
## Info: countdown animation actually started (after any hold).
@warning_ignore("unused_signal") signal ev_countdown_started
## Command: ignore shoot input while locked.
@warning_ignore("unused_signal") signal ev_lock_shoot(locked: bool)
