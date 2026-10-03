---
description: Quizmatik architecture map — where code lives and how systems connect
---

# Architecture (Quizmatik / Godot 4.7)

Math-quiz arcade shooter. Prefer the smallest change that fits existing patterns. Do not invent parallel systems.

Godot 4.x only: `@export`/`@onready`, `signal.connect(cb)`, `instantiate()`, typed GDScript, `Input` actions.

## Stable references (critical)

Avoid hardcoded `res://` strings that break when files move.

- Prefer `class_name` + typed use over `preload("res://path/script.gd")`
- Prefer `@export` / `@export_file` / PackedScene assigned in the editor
- Do not add new path constants for scripts/resources unless no other option (document why)

## Target platforms (critical)

Ship and play well on **all three**: **Mobile** (Android/iOS), **Steam** (desktop), **HTML5** (web).

- Design every feature/control/UI for comfortable play on touch **and** mouse/keyboard — not PC-first with mobile as afterthought.
- Prefer InputMap actions (`shoot`, `ui_*`) over hard-coded keys; add touch controls (on-screen buttons / gestures) without breaking desktop/web.
- UI: readable at phone landscape, safe areas, hit targets large enough for fingers; still clean on 16:9 desktop and browser.
- Performance: mobile renderer / mid-range phones and browsers matter — avoid heavy one-platform-only effects unless gated.
- Particles: `CPUParticles2D` only, never `GPUParticles2D` — GPU `preprocess` re-simulates on every new instance (WebGL/ANGLE: 0.3–2.7 s frozen frame + audio stall on each scene mount).
- Platform-specific code: only in HFSM platform contexts/scenes — `godot-paradigm.md` → Platform code. Never fork gameplay per platform.
- Before merging a feature, ask: *playable with touch, with keyboard/mouse, and in browser?*

## #1 Scene isolation (critical)

See `godot-paradigm.md` (context scene, resource defaults, HFSM override, resource events).

## Entry & folders

| Path | Role |
|------|------|
| `main.tscn` → `src/game/main.gd` | HFSM bootstrap host |
| `src/game/scenes/` | Screens / orchestration: `app_root`, `menu`, `game`, `post_battle` |
| `src/features/` | Isolated gameplay features (own almost all deps) |
| `src/common/` | Project-shared Resources (`GameConfig`, `BattleDifficulty`, `LevelsConfig`, settings) |
| `src/ui/` | Shared UI widgets (dialogs, buttons, loading, backgrounds) |
| `src/levels/{container}/` | Campaign `level_N.tres` (canonical) |
| `core/` | Project-agnostic code only (no Quizmatik types/scenes) |
| `tools/` | Offline generators (e.g. levels) |
| `assets/` | Runtime shared art — see layout below |
| `concepts/` | AI style reference only (`ART_DIRECTION.md` + frames) — game and tools never use it; see `concepts.md` |
| `src/dev/` | Editor/dev utilities — not the game entry. `training_room_lab/` = frozen snapshot of full practice UI (editor-only menu button) |

### `assets/` layout

| Path | Contents |
|------|----------|
| `assets/audio/music/` | Looping BGM streams (OGG/MP3, not WAV) |
| `assets/effects/` | FX sprites (e.g. starlight) |
| `assets/ui/icons/` | Shared UI icons (stars, mute, movement, gold coin `coin_gold.svg`, timed-level `clock.svg`) |
| `assets/ui/stamps/` | Ink stamps for daily / post-battle / level grid (`stamp_empty`, `stamp_sun`, …) |
| `assets/ui/hud/` | Battle HUD frames (score, question banner) |
| `assets/ui/backgrounds/` | Shared menu/paper/sky textures used by scenes |
| `assets/ui/backgrounds/valleys/` | Campaign valley landscapes (one set: `valley_addition` … `valley_mix`) |
| `assets/fonts/` | Runtime fonts only: Nunito Bold + Rubik Doodle Shadow |

Ignore for gameplay work: `addons/`, `.godot/`, `bin/`, legacy `src/levels/level_*.tres` (root).
Export never packs: `concepts/`, `tools/`, `bin/`, `.cursor/`, `.claude/`, `.vscode/`, `.godot/`, `.git/` — see `export_presets.cfg` `exclude_filter`, `concepts/.gdignore`, `tools/.gdignore`, `.claude/.gdignore`.

## Layer contracts

### `src/features/` — isolated features
- One folder = one feature (`plane`, `answer`, `shot`, `explosion`, `ink_blot`, …).
- Keep **almost all dependencies inside** the feature: scripts, scenes, local helpers, feature-specific assets refs.
- Talk to the outside via a **small public surface** (signals `ev_*`, `initialize`/`setup`, exported PackedScenes).
- Features must **not** import other features' internals or scene scripts.
- Scenes **compose/spawn** features; they do not reimplement feature logic.

### `core/` — project-agnostic
- May be reused in any Godot project: FSM, `EventListener`, shackers, window stack, ResourceUtils, etc.
- **Must not** depend on `src/` (no `GameConfig`, contexts, features, quiz types, project scenes).
- If code needs Quizmatik types → it belongs in `src/`, not `core/`.

### `src/game/scenes/` — orchestration only
- Wire features + shared config; own flow/FSM/UI for that screen.
- Do not dump reusable feature guts here — extract to `src/features/` or (if generic) `core/`.
- Each scene ships its own default Resources; parents override them through `RootEvents` / `initialize(data)`, never by requiring the parent to be open in the editor.

## UI — editor-first (critical)

See `godot-paradigm.md` → UI. Theme: root `Control` of each window gets `theme = core/theme/style.tres` (isolated preview otherwise shows default theme).

## Context flow

```
Menu --ev.start_game--> Battle --ev.exit_game--> PostBattle
PostBattle --ev.return_to_menu--> Menu
PostBattle --ev.start_game--> Battle (retry)
Battle --ev.start_game--> Battle (in-battle restart remount)
App/Tutorial (parallel) --ev.open_tutorial / ev.close_tutorial
```

App phases are driven by HFSM (`src/game/hfsm/app_hfsm.json`) via `src/game/main.gd`:
- `main.gd` only creates HFSM + scene host; no gameplay bridge
- Root `App` scene id `app_root` → `app_root/root.tscn` (`IScene`; RootEvents → `hfsm.add_event`)
- JSON `scene: { id, loading_screen, async_loading, on_event }` → HFSM mounts via `HfsmSceneRegistry` + `HfsmScenePaths.PATHS`
- `App` mounts `app_root`; on HTML5, AppRoot emits `ev.open_web` with `music_player`
- Nested `WEB` enters on `ev.open_web` with BoundEntity `WEBContext`; keep generic HTML5 hooks there
- Yandex Games export (`custom_features=yandex_games`): `WEBContext` emits `ev.open_yandex` → nested `Yandex` + `YandexContext` (SDK / ads)
- Scene node lifecycle: `initialize` / `deinit` / `on_event` called by HFSM
- Menu UI windows use `WindowStackManager` (not HFSM bindings)
- Battle payload: **either** `custom_battle` **or** `battle_info` — never both
- In-battle: `GameEvents` + `GameManager` FSM (not HFSM yet)

## Battle loop

`GameManager` FSM: `CountDown` → `Game` → `EndGame` (via `FSMGameEvents`).
Round logic: `RoundController` + `AnswerSpawner` + `CombatResolver` + `QuizQuestion`.
Boss airship (exam always, regular levels by chance) = extra phase inside `GameState` after the last regular answer — see `game.md`; feature `src/features/boss/`.
Do not drive win/lose with ad-hoc flags outside the FSM.
SFX: `SfxController` (`src/features/sfx/`, instanced in `app_root/root.tscn`) listens to `GameEvents` + UI `BaseButton.pressed`. Plane thrust / crash / victory whoosh stay on `plane.tscn`.
Vibration: `VibrationController` (`src/features/vibration/`, instanced in `app_root/root.tscn`) listens to `GameEvents` + `RootEvents` + UI `BaseButton.pressed` (`Input.vibrate_handheld` + joy rumble). Android export must keep `permissions/vibrate=true`.
Music: `MusicController` (`src/features/music/`) owns AppRoot `MusicPlayer` swaps — background by default; on `RootEvents.ev_exit_game` plays win/lose theme; background on `ev_return_to_menu`; `ev_start_game` plays `exam_music` (battle_info.is_exam) / `battle_music`, empty slot → background. Also listens to `GameEvents`: `ev_boss_appeared` → fade to `boss_music`; `ev_time_left` ≤ `hurry_seconds` → `pitch_scale` up; `ev_win`/`ev_lose` → fade out (result theme on `ev_exit_game`). All themes in `src/features/music/` = output of `tools/generate_music.py`; win/lose = intro + loop, their `.ogg.import` `loop_offset` must equal the printed intro length (win 4.0, lose 6.0); battle/exam/boss loop from 0. Menu + battle HUD mute icons toggle Music (`is_music_mute`) and SFX (`is_sound_mute`) buses; never mute Master.

## Placement rules

- New isolated gameplay unit → `src/features/{name}/` (self-contained; `.gd` + `.tscn` colocated)
- New screen / flow → `src/game/scenes/{name}/`
- Platform BoundEntity context → `src/game/contexts/` + register in `main.gd` `context` slot
- Project-shared Resource/type → `src/common/`
- Shared UI widget (button base, dialog, loading, animated title) → `src/ui/` (`animated_title/` = per-letter fall/hop intro)
- HFSM loading overlay → `src/ui/loading_screen/` (`main.tscn` `loading_screen_scene`, `min_load_time` 0.7): contract `update_progress(0..1)` + `fade_out()` only; equipped plane via `@export pdata` (`persistent_data.tres`) → `PlaneFlyer`; never pass payload / touch `core/lib/hfsm` for it
- New battle/menu sky variant → `src/ui/backgrounds/{name}/` + add PackedScene to `BackgroundHost.variants`
- Valley landscape scenes → `src/ui/backgrounds/valley_{container}/`; map `container_id` via `ValleyBackgroundArt`
- Generic reusable utility (no project deps) → `core/lib/`
- Level data → `src/levels/{container}/`; metadata → `levels_config.gd` / `tools/generate_levels.py`
- Progress mutations → `ProgressController` / `DailyChallengesController` / `StatisticsController` / `MistakesController` / `ProfileController`; disk write only via `RootEvents.ev_save_progress` → `SaveManager.save()` (debounced; suppressed during battle; force-flush at battle end / app close)
- Profiles (max 4; profile = progress) → `src/game/account/` + `menu/profile_window/`; hangar → `menu/plane_hangar_window/`; catalog → `src/features/plane/plane_catalog.gd`; plane art shared via `plane_frames.tres` / `flame_frames.tres` (battle `plane.tscn` + visual-only `PlaneFlyer` `plane_flyer.tscn`: hover + pencil trail, `apply_plane(id)`) — never instance battle `plane.tscn` for showcases
- First-run tutorial → context `src/game/scenes/tutorial/` (HFSM `App/Tutorial`, see `hfsm-app-integration.md`). All tutorial logic/texts live there: `tutorial.gd` = chapters `first_flight` → `daily_stamp` → `plane_shop` (flags `PData.state.tutorial_steps`), `MenuPointer` steps per chapter, `BattleCoach`. Other scenes only mark UI: `UiAnchor` → `tutorial/tutorial_anchors.tres` (`menu.start`, `menu.pack`, `levels.next`, `menu.daily`, `menu.profile`, `profile.plane`, `hangar.buy`, `battle.question`). Never add tutorial code/hints to menu/battle scenes
- Hint/anchor UI kit (shared UI, not core): `src/ui/tutorial_hint/` (`TutorialHint` arrow + cloud shader; look via `TutorialHintStyle` — palette `tutorial/tutorial_hint_style.tres`; `AnchorPointer` + `AnchorPointerStep`), `src/ui/ui_anchor/` (`UiAnchor`, `UiAnchorRegistry`), `src/ui/spotlight_dim/` (`SpotlightDim`: dim + clickable holes via `_has_point`, optional `ui_*` key block; hints drawn above it)
- Difficulty choice widget (easy/normal/hard cards, `ev_changed`) → `src/ui/difficulty_picker/` (`DifficultyPicker`; profile window + create overlay)
- Celebration overlays (valley / plane / daily gold) → `src/ui/celebration_splash/` (not window stack); first-run create overlay same rule
- App-root SFX → `src/features/sfx/` (`SfxController` instanced in `app_root/root.tscn`); plane-local audio stays on `plane.tscn`
- App-root vibration → `src/features/vibration/` (`VibrationController` instanced in `app_root/root.tscn`)
- App-root music → `src/features/music/` (`MusicController` + win/lose themes; drives AppRoot `MusicPlayer`)
- Editor-only practice lab (frozen full training UI) → `src/dev/training_room_lab/` — do not merge into player-facing `training_room_window/`; menu bottom-left button uses `OS.has_feature("editor")`; **+1 ЗОЛОТАЯ** / **СБРОСИТЬ ПРОГРЕСС** (wipe closes lab → first-run overlay); block «Бонус, время и босс» = `bonus_gold_chance` + `time_limit_sec` + `boss_chance` + `boss_armor` steppers (0 / 3 by default); **ОТКРЫТЬ ВСЕ ДОЛИНЫ** → `ProgressController.unlock_all_containers()`
- Player practice UI → `training_room_window/`: ops columns + `BattleDifficulty` coefficients into `GameConfig` (full steppers live only in lab); «НА ВРЕМЯ» switch (`TrainingOptionButton.is_switch`, preset `timed`) → `time_limit_sec = timed_practice_sec` (60); `? + 3 = 7` = `missing_operand_chance_by_difficulty` (normal .3, hard .4) + `missing_operand_start_by_difficulty` (normal .5 = second half) exports there, not in `BattleDifficulty` (that also drives campaign via profile `PData.difficulty`)

## Cheap-change heuristics

1. Match nearest existing file; copy its wiring (`@export`, signals `ev_*`).
2. Prefer editing one layer: data (`.tres`) → feature → scene orchestration.
3. Before adding to `core/`: confirm zero `src/` imports. Before splitting a feature: keep deps inside it.
4. New scene dependency → default `.tres` on the scene + optional runtime override from parent event.
5. Do not rename entrenched typos (`persisten_*`, `fsm game_states.gd`) unless asked.
6. Do not edit `addons/` or binary assets; reference `res://` paths.
7. Live context Resources (e.g. `game_config.tres`) are defaults/overridden at runtime — change level `.tres` or `GameConfig` schema for real content.
