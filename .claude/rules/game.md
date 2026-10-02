---
description: Battle loop, combat, and GameScene change rules
paths:
  - "src/game/scenes/game/**/*"
---

# Game scene / battle

## Ownership

- Orchestration: `game.gd` resolves scenario → `ResourceUtils.update_resource` into live `GameConfig`
- Live `game_config.tres` on the scene = **standalone defaults** (scene must run alone); parent overrides via `ev_start_game` → `initialize(data)`
- States: `GameManager` FSM only (`CountDown` / `Game` / `EndGame`)
- Round: `round/round_controller.gd`, `answer_spawner.gd`, `combat_resolver.gd`
- Questions: `question_generator.gd` (`QuizQuestion`)
- Features: spawn/compose from `src/features/` — keep feature logic inside the feature; scene only wires and reacts to `ev_*`

## Change guide

| Goal | Touch |
|------|--------|
| Win/lose / transitions | FSM states + `FSMGameEvents` |
| Scoring / health | `Player` + `CombatResolver` |
| Streak | `Player.streak` (+1 in `apply_correct`, 0 in `apply_damage`); heal every `GameConfig.streak_heal_every` ≤ `streak_heal_max_health`; HUD `ui/streak_chip.gd` from `streak_feedback_min`; `GameState` emits `ev_streak(n)` / `ev_health_restored` |
| Spawn layout / lanes | `GameArea` + `AnswerSpawner` |
| Question math | `QuizQuestion` + `GameConfig` fields; hidden operand `? + 3 = 7` via `missing_operand_chance` gated by `missing_operand_start_progress` (`missing_operand_chance_at(score)`; `RoundController` passes `player.score`) (`_hide_operand` / `_fill_close_options`) |
| Wrong options | +/−: `_generate_close_fake_add_sub`; ×/÷: `_generate_plausible_fake` (table neighbours, ±1–2, ±10, `a+b`; × keeps only within `max(3, correct/2)`; ÷ = quotient ±1–3 + divisor). Never random ranges (kids guess by size) |
| Weak-example review | Every `Question` has `fact_key` (`MathFact`: `add:x:y` covers +/−, `mul:x:y` covers ×/÷). `GameConfig.review_facts` (runtime, from payload `review_facts` set in `game.gd`) + `review_chance`: `_pick_review` re-asks a weighted fact only via allowed ops inside `get_operation_range`. `GameState._report_fact` emits `ev_fact_answered(key, ok)` once per question: wrong **shot** = false, clean correct = true; collisions never count |
| HUD only | `ui/` — listen to `GameEvents`, don't own combat |
| SFX | AppRoot `SfxController` via `GameEvents` (`ev_shoot`, `ev_explosion`, `ev_correct_answer`, `ev_mistake`, `ev_bonus_collected`, `ev_win`, `ev_lose`, state change); plane thrust/crash/whoosh stay on the plane |
| Vibration | AppRoot `VibrationController` via same `GameEvents` (+ `ev_streak` double tick, `ev_health_restored` 3 rising pulses) + `RootEvents` + UI presses; plane crash = long multi-pulse on `ev_lose` |
| Touch plane | `AirPlane`: left half drag = move, right half tap = shoot (`mobile` / web+touchscreen); keyboard/mouse unchanged on desktop |
| Tutorial | Not in this scene — `scenes/tutorial/` `BattleCoach` talks via `GameEvents` only. Battle exposes: info `ev_answers_spawned(answers, correct, lanes)`, `ev_plane_lane_changed(lane, centered)` (`LineSelector`); commands `ev_pause_answers` (`GameState` → `Answer.frozen`), `ev_lock_shoot` (`ShotManager`); `HUD/QuestionAnchor` (`battle.question`). Touch scheme: `AirPlane.is_touch_scheme()` (static) |
| Equipped plane | `PlaneCatalog` + `ProfileController`: planes differ **only** by `speed_mult` (`AirPlane`) and `shot_speed_mult` (`GameState` → `AirPlane.shot_speed_mult` → `ShotManager` scales each shot), + tint; never add perks (blast, shield, hint) (isolated F6 → starter) |
| Bonus balloon | `round/bonus_controller.gd` (`BonusController`: ≤1 per battle, rolled from `GameConfig.bonus_gold_chance`, spawned on `RoundController.ev_round_started` at a random score in `1..questions_count-2`, random lane, `answer_speed × bonus_gold_speed_mult` ahead of answers) + `features/answer/bonus_balloon.tscn` (`BonusBalloon extends Answer`). `GameState` calls `try_collect` first in shot/ram handlers → never reaches `CombatResolver` (no mistake/correct/stats). Collect → `Player.bonus_gold` + `ev_bonus_collected` (SFX/vibration) → payload `bonus_gold` |
| Miss hint | Wrong shot → correct balloon `show_hint()` for **every** plane (learning aid; never a plane perk) |

## Constraints

- Exit battle via `root_events.ev_exit_game` with post-battle payload
- Answers: respect `is_hittable()` during entry tween
- Speed ramp / health / question count come from `GameConfig`, not hardcode
- Prefer small `RefCounted` helpers over growing `GameState` further
- Combat controls/HUD must work on Mobile (touch), Steam (KBM), and HTML — no platform-locked input
