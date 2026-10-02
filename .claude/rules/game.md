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
| HUD only | `ui/` — listen to `GameEvents`, don't own combat |
| SFX | AppRoot `SfxController` via `GameEvents` (`ev_shoot`, `ev_explosion`, `ev_correct_answer`, `ev_mistake`, `ev_win`, `ev_lose`, state change); plane thrust/crash/whoosh stay on the plane |
| Vibration | AppRoot `VibrationController` via same `GameEvents` (+ `ev_streak` double tick, `ev_health_restored` 3 rising pulses) + `RootEvents` + UI presses; plane crash = long multi-pulse on `ev_lose` |
| Touch plane | `AirPlane`: left half drag = move, right half tap = shoot (`mobile` / web+touchscreen); keyboard/mouse unchanged on desktop |
| Tutorial | Not in this scene — `scenes/tutorial/` `BattleCoach` talks via `GameEvents` only. Battle exposes: info `ev_answers_spawned(answers, correct, lanes)`, `ev_plane_lane_changed(lane, centered)` (`LineSelector`); commands `ev_pause_answers` (`GameState` → `Answer.frozen`), `ev_lock_shoot` (`ShotManager`); `HUD/QuestionAnchor` (`battle.question`). Touch scheme: `AirPlane.is_touch_scheme()` (static) |
| Equipped plane | `PlaneCatalog` + `ProfileController`: planes differ **only** by `speed_mult` (`AirPlane`) and `shot_speed_mult` (`GameState` → `AirPlane.shot_speed_mult` → `ShotManager` scales each shot), + tint; never add perks (blast, shield, hint) (isolated F6 → starter) |
| Miss hint | Wrong shot → correct balloon `show_hint()` for **every** plane (learning aid; never a plane perk) |

## Constraints

- Exit battle via `root_events.ev_exit_game` with post-battle payload
- Answers: respect `is_hittable()` during entry tween
- Speed ramp / health / question count come from `GameConfig`, not hardcode
- Prefer small `RefCounted` helpers over growing `GameState` further
- Combat controls/HUD must work on Mobile (touch), Steam (KBM), and HTML — no platform-locked input
