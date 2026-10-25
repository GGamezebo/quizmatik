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
- Stretch: `canvas_items` + aspect `keep_height` (height always 720; wider → world widens; narrower → engine bars, native only). Never `expand` — tall windows stretch lanes/balloons vs fixed-size plane. Width ≥ 1280 still changes at runtime → never cache viewport size / lane rects.
- Web presets (`Web`, `Web-Yandex`): `html/canvas_resize_policy=0` + same `html/head_include` fit script/CSS in both — page sizes `#canvas` to full width × min(height, width·9/16), centered, notebook-grid paper body behind (no black bars). Change both presets together; Yandex keeps `/sdk.js` first
- Stretch: `canvas_items` + aspect `keep_height` (height always 720; wider → world widens, narrower → bars top/bottom). Never `expand` — tall windows stretch lanes/balloons vs fixed-size plane. Layout must still handle width ≥ 1280 changing at runtime (resize).
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
| `store/` | ALL store-page media (images, banners, screenshots, videos, trailers) → `screenshots/{ru,en}/` `banners/` `videos/{ru,en}/`; never put such media in `assets/`/`docs/`; `store/.gdignore`, never packed, never referenced by game; `store/videos/` = nested repo `GGamezebo/quizmatik-store` (LFS), gitignored in the game repo — commit videos there |
| `docs/` | Public static pages for store listings (privacy policy → GitHub Pages); `docs/.gdignore`, never packed |
| `src/dev/` | Editor/dev utilities — not the game entry. `training_room_lab/` = frozen snapshot of full practice UI (editor-only menu button) |

### `assets/` layout

| Path | Contents |
|------|----------|
| `assets/app_icon/` | App icon kit (launcher / adaptive / PWA / boot splash) — output of `tools/generate_app_icon.py`, wired in `project.godot` (`config/icon`, `boot_splash`) + every `export_presets.cfg` preset; edit the script, never the PNGs. Android launcher: `adaptive_fg_432` = unframed main icon art filling the visible 72/108 square (launcher mask = shape, never draw a frame/paper there), `adaptive_bg_432` = sky bg. Launch chain: Android 12+ splash `splash_android.png` (icon inside the 2/3 safe circle, small) → Godot boot `splash.png` 1024, `boot_splash/stretch_mode=1` (big); all Android presets: gradle build, `screen/background_color` + `splash_screen/background_color` = cream `boot_splash/bg_color` (never black — dark flash). `android/build/` is gitignored: `tools/android_template/GodotApp.java` (keeps the system splash until `RunStatus.STARTED`, no black surface) → copy to `android/build/src/main/java/com/godot/game/` after reinstalling the template |
| `assets/audio/music/` | Looping BGM streams (OGG/MP3, not WAV) |
| `assets/effects/` | FX sprites (e.g. starlight) |
| `assets/ui/icons/` | Shared UI icons (stars, mute, movement, gold coin `coin_gold.svg`, timed-level `clock.svg` (countdowns: level grid, HUD timer, practice), endless stopwatch `stopwatch.png` (menu clock, HUD score-frame timer in endless (`score.gd` `endless_time_texture`), battle record plate, endless post-battle row, trophy record scroll), magister trial `magister_cap.svg`, share buttons `share.svg`, control hints `touch_hint_*` / `hint_finger` / `key_*` / `mouse_click`, `heart.png` = HUD heart + endless heart balloon) |
| `assets/ui/stamps/` | Ink stamps for daily / post-battle / level grid (`stamp_empty`, `stamp_sun`, …) |
| `assets/ui/hud/` | Battle HUD frames (score, question banner) |
| `assets/ui/backgrounds/` | Shared menu/paper/sky textures used by scenes |
| `assets/ui/backgrounds/valleys/` | Campaign valley landscapes (one set: `valley_addition` … `valley_mix`) |
| `assets/fonts/` | Runtime fonts only: Nunito Bold + Rubik Doodle Shadow |

Ignore for gameplay work: `addons/`, `.godot/`, `bin/`, legacy `src/levels/level_*.tres` (root).
Export never packs: `concepts/`, `store/`, `tools/`, `bin/`, `.cursor/`, `.claude/`, `.vscode/`, `.godot/`, `.git/` — see `export_presets.cfg` `exclude_filter`, `concepts/.gdignore`, `tools/.gdignore`, `.claude/.gdignore`.

## Layer contracts

### `src/features/` — isolated features
- One folder = one feature (`plane`, `answer`, `shot`, `explosion`, `ink_blot`, …).
- Keep **almost all dependencies inside** the feature: scripts, scenes, local helpers, feature-specific assets refs.
- Talk to the outside via a **small public surface** (signals `ev_*`, `initialize`/`setup`, exported PackedScenes).
- Features must **not** import other features' internals or scene scripts.
- Scenes **compose/spawn** features; they do not reimplement feature logic.

### `core/` — project-agnostic
- May be reused in any Godot project: FSM, `EventListener`, shackers, window stack, ResourceUtils, `ViewportSnapshot` (`core/lib/viewport_snapshot/`: hidden SubViewport → PNG once), `SwipeDetector` (`core/lib/swipe/`: horizontal drag / wheel over an `area` → `ev_swiped(±1)`, `ev_pressed`; never consumes input), `UiPulse` (`core/lib/pulse/`: looping pulse, `set_active`, pivot follows resizes; target = inner icon or a plain wrapper `Control` around the button, never a hover-scaled button itself; a pulsing button always pulses whole — wrap it, never pulse only its icon), etc.
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
App/ControlsIntro (parallel, once per session + new pilot first flight) --ev.open_controls_intro / ev.close_controls_intro
```

App phases are driven by HFSM (`src/game/hfsm/app_hfsm.json`) via `src/game/main.gd`:
- `main.gd` only creates HFSM + scene host; no gameplay bridge
- Root `App` scene id `app_root` → `app_root/root.tscn` (`IScene`; RootEvents → `hfsm.add_event`)
- JSON `scene: { id, loading_screen, async_loading, on_event }` → HFSM mounts via `HfsmSceneRegistry` + `HfsmScenePaths.PATHS`
- `App` mounts `app_root`; AppRoot emits `ev.open_platform` → `App/Platform` picks branch `WEB`(→`Yandex` / `CrazyGames` / `Poki`) / `Android`(→`GooglePlay` / `RuStore`) / `Desktop`(→`Steam`) by OS + export `custom_features` (`hfsm-app-integration.md`)
- Game ↔ platform (ads, IAP, later cloud / analytics) only via `PlatformServices` Resource (`src/common/platform/`); monetization rules in `App/Monetization`, host UI only via `OfferBoard` — `monetization.md`
- Scene node lifecycle: `initialize` / `deinit` / `on_event` called by HFSM
- Menu UI windows use `WindowStackManager` (not HFSM bindings)
- Battle payload: **either** `custom_battle` **or** `battle_info` — never both
- In-battle: `GameEvents` + `GameManager` FSM (not HFSM yet)

## Battle loop

`GameManager` FSM: `CountDown` → `Game` → `EndGame` (via `FSMGameEvents`).
Round logic: `RoundController` + `AnswerSpawner` + `CombatResolver` + `QuizQuestion`.
Boss airship (exam always, regular levels by chance) = extra phase inside `GameState` after the last regular answer — see `game.md`; feature `src/features/boss/`.
Do not drive win/lose with ad-hoc flags outside the FSM.
SFX: `SfxController` (`src/features/sfx/`, instanced in `app_root/root.tscn`) listens to `GameEvents` + `RootEvents` daily-card hooks (`ev_daily_stamp_landed`, `ev_daily_series_shown`) + UI `BaseButton.pressed`; all WAVs from `tools/generate_sfx.py` (append new sounds at the end of `pairs` so seeded output of the others stays identical). Plane thrust / crash / victory whoosh stay on `plane.tscn`. Thrust = seamless loop `plane/thrust.wav` from `tools/generate_sfx.py` `thrust()` (`loop_mode=2`); its player (`plane/audio_stream_player.gd`) only fades volume / glides pitch — never restart/stop per direction change.
Vibration: `VibrationController` (`src/features/vibration/`, instanced in `app_root/root.tscn`) listens to `GameEvents` + `RootEvents` + UI `BaseButton.pressed` (`Input.vibrate_handheld` + joy rumble). Android export must keep `permissions/vibrate=true`.
Music: `MusicController` (`src/features/music/`) owns AppRoot `MusicPlayer` swaps — background by default; on `RootEvents.ev_exit_game` plays win/lose theme; background on `ev_return_to_menu`; `ev_start_game` plays `exam_music` (battle_info.is_exam) / `battle_music`, empty slot → background. Also listens to `GameEvents`: `ev_boss_appeared` → fade to `boss_music`; `ev_time_left` ≤ `hurry_seconds` → `pitch_scale` up; `ev_win`/`ev_lose` → fade out (result theme on `ev_exit_game`). `RootEvents.ev_celebration_music(true)` (purchase thank-you) → `celebration_music` (empty = win theme), `false` → restores what played before. All themes in `src/features/music/` = output of `tools/generate_music.py`; win/lose = intro + loop, their `.ogg.import` `loop_offset` must equal the printed intro length (win 4.0, lose 4.8); battle/exam/boss loop from 0. AppRoot `MusicPlayer` = `playback_type` Stream (intro/loop + pitch); web build is non-threaded → Stream mixes on main thread, so keep `audio/driver/output_latency.web` = 150 (never back to 50 — choppy music on itch/Yandex). Menu + battle HUD mute icons toggle Music (`is_music_mute`) and SFX (`is_sound_mute`) buses; never mute Master from UI.
Background pause: `AppPauseController` (`src/features/app_pause/`, instanced in `app_root/root.tscn`, `PROCESS_MODE_ALWAYS`) — app focus-out / paused / `RootEvents.ev_app_visibility_changed(false)` → `get_tree().paused = true` + mute Master; restores on return (Yandex moderation requirement). Platform visibility sources emit that event (web: `WEBContext` `document.visibilitychange`). Nodes that must run while backgrounded need `PROCESS_MODE_ALWAYS`.

## Placement rules

- New isolated gameplay unit → `src/features/{name}/` (self-contained; `.gd` + `.tscn` colocated)
- New screen / flow → `src/game/scenes/{name}/`
- Platform BoundEntity context → `src/game/contexts/` + register in `main.gd` `context` slot
- Monetization: store `*_shop_context.gd` → `src/game/contexts/`; game rules + paywall → `src/game/scenes/monetization/`; `OfferBoard` → `src/common/monetization/`; hooks `src/ui/rewarded_gold_button/`, `src/ui/purchase_offer_button/`, `src/ui/parental_gate/` — `monetization.md`
- Project-shared Resource/type → `src/common/`
- Shared UI widget (button base, dialog, loading, animated title) → `src/ui/` (`animated_title/` = per-letter fall/hop intro)
- HFSM loading overlay → `src/ui/loading_screen/` (`main.tscn` `loading_screen_scene`, `min_load_time` 0.7; header = `AnimatedTitle`, bobbing math-glyph `drifters` decor): contract `update_progress(0..1)` + `fade_out()` only; equipped plane via `@export pdata` (`persistent_data.tres`) → `PlaneFlyer`; never pass payload / touch `core/lib/hfsm` for it
- New battle/menu sky variant → `src/ui/backgrounds/{name}/` + add PackedScene to `BackgroundHost.variants`
- Valley landscape scenes → `src/ui/backgrounds/valley_{container}/`; map `container_id` via `ValleyBackgroundArt`
- Generic reusable utility (no project deps) → `core/lib/`
- Level data → `src/levels/{container}/`; metadata → `levels_config.gd` / `tools/generate_levels.py`
- Progress mutations → `ProgressController` / `DailyChallengesController` / `StatisticsController` / `MistakesController` / `ProfileController`; disk write only via `RootEvents.ev_save_progress` → `SaveManager.save()` (debounced; suppressed during battle; force-flush at battle end / app close)
- Profiles (max 4; profile = progress) → `src/game/account/` + `menu/profile_window/`; hangar → `menu/plane_hangar_window/`; catalog → `src/features/plane/plane_catalog.gd`; plane art shared via `plane_frames.tres` / `flame_frames.tres` (battle `plane.tscn` + visual-only `PlaneFlyer` `plane_flyer.tscn`: hover + pencil trail, `apply_plane(id)`) — never instance battle `plane.tscn` for showcases; each plane = own column `atlas_column` of `planes_atlas_spaced.png` (288×108 cells, rows idle/down/up; col 0 = base pencil art «Быстрый», cols 1+ = pen / marker / ruler / fountain pen only from `tools/generate_plane_variants.py`, pre-colored → `tint` white; exhaust flame moved per plane by def `flame_offset` via `PlaneCatalog.flame_position`, never per-plane flame nodes); set look only via `AirPlane`/`PlaneFlyer.apply_plane(id)` (→ `PlaneCatalog.sprite_frames`) or `PlaneCatalog.apply_preview`
- First-run tutorial → context `src/game/scenes/tutorial/` (HFSM `App/Tutorial`, see `hfsm-app-integration.md`). All tutorial logic/texts live there: `tutorial.gd` = chapters `first_flight` → `daily_stamp` → `plane_shop` (flags `PData.state.tutorial_steps`) + late chapter `endless_intro` (= `ProgressController.ENDLESS_INTRO_STEP`; not gated by `tutorial_completed`, shown when `is_endless_intro_pending()`; confirm button or pressing the clock completes it) + late chapter `shop_tour` (= `ProgressController.SHOP_TOUR_STEP`; after `plane_shop` or finished tutorial, first `ev.exit_game` with `CosmeticCatalog.has_affordable` → flag `shop_tour_armed`; menu `menu.shop` → `shop_tour_steps` one at a time, each advances on `AnchorPointer.ev_target_pressed`, last `shop.buy` confirm/press; context stays open idle while `is_shop_tour_pending()`) + late chapter `mistakes_intro` (`MISTAKES_INTRO_STEP`, due when `is_mistakes_intro_pending()` = `PData.mistakes` non-empty: `menu.awards` → `awards.hard_facts` (press) → `awards.hard_facts_list` in `HardFactsOverlay`, step `layer` 12 lifts the hint over the overlay, confirm); late chapters only when no base chapter is ready (never during first_flight), priority endless → shop → mistakes; tours = entry steps + tour steps one at a time, earlier steps stay as fallback, `MenuPointer` steps per chapter, `BattleCoach` (re-`arm` after DONE restarts it — new pilot while the context stayed open); any won `ev.exit_game` or a pilot with stars (`has_any_stars`, old stuck saves) completes `first_flight`; one-shot battle tips `BattleTips` (`tip_missing_operand` / `tip_boss` / `tip_boss_rage`, same flags, after first_flight; info from `GameEvents.ev_answers_spawned(..., missing_operand)` / `ev_boss_*`; tutorial closes only when chapters + tips done). Other scenes only mark UI: `UiAnchor` → `tutorial/tutorial_anchors.tres` (`menu.start`, `menu.pack`, `levels.next`, `menu.daily`, `menu.profile`, `menu.endless`, `menu.shop`, `menu.awards`, `awards.hard_facts`, `awards.hard_facts_list`, `shop.item` (CosmeticsPage `item_anchor`: not-selected card, affordable first), `shop.slot.trail`, `shop.slot.cover`, `shop.buy`, `profile.plane`, `hangar.buy`, `battle.question`, `battle.boss`). Never add tutorial code/hints to menu/battle scenes
- «How to play» before the first battle of each app session → context `src/game/scenes/controls_intro/` (HFSM `App/ControlsIntro`, opened by AppRoot `initialize` + `_sync_controls_intro` when the active pilot changes to one with `!is_first_flight_done()`, closes itself after one battle): holds countdown via `GameEvents.ev_countdown_entered` → `ev_hold_countdown(true/false)`; touch / keys variants (`AirPlane.is_touch_scheme()`); touch cards fly into `HUD/TouchHints` corners; also shown before the tutorial `first_flight` battle (`BattleCoach` starts only on GAME). Never put its UI/logic in the battle scene
- Battle-mode rules card → `src/ui/rules_overlay/` (`RulesOverlay` CanvasLayer: `open(with_start)`, `ev_start_pressed` / `ev_closed`; content = per-mode scene: magister, endless)
- Math line label → `src/ui/math_label/` (`MathLabel.set_math_text` / `math_text`: «√n» drawn as a bold radical with a bar, the font's √ is too thin; question banner `ui/answer_label.gd` extends it)
- Hint/anchor UI kit (shared UI, not core): `src/ui/tutorial_hint/` (`TutorialHint` arrow + cloud shader; look via `TutorialHintStyle` — palette `tutorial/tutorial_hint_style.tres`; `AnchorPointer` + `AnchorPointerStep`; `ev_target_pressed(step)` when the pointed `BaseButton` is pressed; step `layer` > 0 = host lifts its CanvasLayer while shown), `src/ui/ui_anchor/` (`UiAnchor`, `UiAnchorRegistry`), `src/ui/spotlight_dim/` (`SpotlightDim`: dim + clickable holes via `_has_point`, optional `ui_*` key block; hints drawn above it)
- Difficulty choice widget (easy/normal/hard cards, `ev_changed`) → `src/ui/difficulty_picker/` (`DifficultyPicker`; profile window + create overlay)
- Cosmetics (look only, bought with gold; never speed/aim/perks) → data `src/common/cosmetics/` (`CosmeticItem` subclasses `PaintItem` / `TrailItem` / `ShotItem` / `StickerItem` / `FrameItem` / `CoverItem`, all items in `cosmetic_catalog.tres`; free item = slot default); buy/equip only via `CosmeticsController` (AppRoot `Account/`); readers `@export` catalog + live `pdata` → `catalog.equipped_item(slot, pdata.cosmetics.equipped)`. Paint = `features/plane/plane_body.gdshader` (`PlaneCatalog.apply_paint`), trail = `PlaneFlyerTrail.apply_style`, shot = `ShotManager.apply_style` → `InkBlot` (`ink_tint.gdshader` for colored inks); new art rarely needed — stickers reuse `assets/ui/stamps/` + game icons (coin, stopwatch, magister cap, alarm clock), covers reuse `BackgroundBase` scenes (`classic_sky/`-style skies `space/` `school_dreams/` `balloon_world/` `candy_kingdom/` also join battle backgrounds — `visual-concept.md`); 12 items per slot, order = ascending price with the rainbow / gold premium item last; new item = `.tres` entry + CSV row (all columns) + keep `id` unique, never change existing prices
- Celebration overlays (valley / plane / daily gold / `KIND_MASTER` = first exam pass of the last valley, AppRoot when `next_container_id` empty; CPUParticles2D `Ribbons` only for master) → `src/ui/celebration_splash/` (not window stack); first-run create overlay same rule
- App-root SFX → `src/features/sfx/` (`SfxController` instanced in `app_root/root.tscn`); plane-local audio stays on `plane.tscn`
- App-root vibration → `src/features/vibration/` (`VibrationController` instanced in `app_root/root.tscn`)
- App-root background pause → `src/features/app_pause/` (`AppPauseController`)
- App-root music → `src/features/music/` (`MusicController` + win/lose themes; drives AppRoot `MusicPlayer`)
- App-root language → `src/features/locale/` (`LocaleController`); table + `GameLocale` → `src/common/localization/`; language row + list overlay → `src/ui/language_picker/` (`LanguagePicker` / `LanguageOverlay` / `LanguageCard`, flags `flag_<code>.svg`); baked-text art swap → `src/ui/locale_texture_swap/` — `localization.md`
- Editor-only practice lab (frozen full training UI) → `src/dev/training_room_lab/` — do not merge into player-facing `training_room_window/`; menu bottom-left button uses `OS.has_feature("editor")`; **+1** / **+10** gold (one row) / **СБРОСИТЬ ВСЁ** (wipe closes lab → first-run overlay) + **БЕЗ ОБУЧЕНИЯ** (one row; `ProfileController.reset_progress_keep_tutorial()`: only the active pilot stays — id, name, difficulty, `state.tutorial_*` — everything else fresh) / «Экзамен:» row `exam_buttons` + `exam_container_ids` (+ − × ÷ ±) → `ProgressController.pass_exam(id, 3)` at once (trophy, exam plane, next valley; no battle) + `ev_profiles_changed`; block «Бонус, время и босс» = `bonus_gold_chance` + `time_limit_sec` + `boss_chance` + `boss_armor` + `boss_rage_hits` steppers (0 / 3 / 15 by default) + `BossRoyal` checkbox → `boss_royal` (exam chief look); **ОТКРЫТЬ ВСЕ** → `ProgressController.unlock_all_containers()`; **ПРОЙТИ ВСЕ** → `complete_all_containers()` (every level + exam 3 stars), one row; every lab progress / gold edit ends with `RootEvents.ev_profiles_changed` (AppRoot `_sync_tutorial`, tutorial `_refresh`, menu entries re-check)
- Endless survival battle → menu entry `menu/endless/` (`endless_entry.gd` = main-menu left clock, visible only when `ProgressController.is_endless_unlocked()` = `ENDLESS_UNLOCK_EXAMS` (4) valley exams passed; whole button pulses (child `UiPulse` → wrapper `ClockBox`) until best ≥ `calm_best_sec` (300) — then never; first press → `RulesOverlay` `menu/endless/endless_rules_overlay.tscn` (hearts / stopwatch / record cards + rules; start marks `ProgressController.ENDLESS_RULES_STEP`, then the battle); `endless_game_config.tres` = `GameConfig.endless` + `endless_stages` → `custom_battle`; EASY profile → `easy_endless_config` `endless_game_config_easy.tres`, ± ≤ 20 / tables 2–5, same record); battle side `round/endless_director.gd` — `game.md`. Record = `PData.statistics.endless_best_sec` (written only by `StatisticsController` from `ev_exit_game` `endless_sec`); shown in HUD plate, post-battle, trophy room scroll
- Valley record battle → level grid clock `menu/endless/valley_endless_entry.tscn` (`ValleyEndlessEntry extends EndlessEntry` — hooks `_is_unlocked` / `_best_sec` / `_battle_config`; instanced in `levels/levels_selection.tscn` left of the grid, vertically centered, `record_entry.set_valley(id)` on every populate); shown when `ProgressController.is_valley_record_unlocked(id)` = `LevelsConfig.get_record_operation(id)` ≠ 0 (container key `record_operation`: addition / subtraction / multiplication / division; mix has none) + valley exam passed; battle = `ValleyRecordScenario.build(endless config (EASY → easy one), id, op)` — every `endless_stages` entry narrowed to the one op, `GameConfig.endless_valley_id` = id → own record `PData.statistics.valley_endless_best_sec[id]`, valley art in battle + post-battle, post-battle menu button returns to that grid; same rules overlay + `ENDLESS_RULES_STEP` as the menu clock; announced by the `ExamVictoryDialog` «НОВЫЙ РЕЖИМ!» card; record on the trophy shelf tags
- Magister trial → menu entry `menu/magister/` (`magister_entry.gd` = main-menu right cap `assets/ui/icons/magister_cap.svg`, mirrors the endless clock (anchored to the right edge), visible when `ProgressController.are_all_valley_exams_passed()` (all 5 exams), whole button pulses (child `UiPulse` → wrapper `CapBox`) until `is_magister()`; caption «Магистр» / golden «Ты магистр!»; first press → `RulesOverlay` (`menu/magister/magister_rules_overlay.tscn`: square / root 3×3 pictures + trial rules; start button marks `ProgressController.MAGISTER_RULES_STEP`, then the battle); `magister_game_config.tres` = `GameConfig.magister` + `time_limit_sec` 600 + `endless_stages` (squares / roots, 1–5 → 7–16 every 60 s) + boss every 120 s (royal, armor 4, `boss_rage_hits` 0) → `custom_battle`; EASY profile → `easy_magister_config` `magister_game_config_easy.tres` (all four ops, ± ≤ 20 / tables 2–5) + `easy_rules_overlay` `magister_easy_rules_overlay.tscn`, trophy room `magister_easy_rules` same pick). Survived (win) → AppRoot: `ProgressController.unlock_magister()` (first time: +`MAGISTER_GOLD` 25, payload `magister_gold`, `CelebrationSplash.KIND_MAGISTER`)
- Parents report behind a parental gate (Settings → «Для родителей») → `menu/parents_window/` — `menu-and-navigation.md`
- Store / promo videos → `tools/trailer/` (`record.py` bot-played takes via Movie Maker → `bin/trailer/`, `sheet.py`, `compose.py` + `scenarios/*.json`); how-to = skill `.claude/skills/trailer/`; never referenced by the game
- Player practice UI → `training_room_window/`: ops columns + `BattleDifficulty` coefficients into `GameConfig` (full steppers live only in lab); «НА ВРЕМЯ» switch (`TrainingOptionButton.is_switch`, preset `timed`) → `time_limit_sec = timed_practice_sec` (60); boss airship after the last question = `practice_boss_chance` (.33) → `config.boss_chance`; timed = `practice_timed_boss_chance` (.5) → `config.timed_boss_chance` (boss flies in when the time is up); armor rolled 2–6 (`practice_boss_armor_min/max` → `boss_armor`/`boss_armor_max`), 20 % royal (`practice_royal_chance` → `boss_royal_chance`, armor 4–6); `? + 3 = 7` = `missing_operand_chance_by_difficulty` (normal .3, hard .4) + `missing_operand_start_by_difficulty` (normal .5 = second half) exports there, not in `BattleDifficulty` (that also drives campaign via profile `PData.difficulty`)

## Cheap-change heuristics

1. Match nearest existing file; copy its wiring (`@export`, signals `ev_*`).
2. Prefer editing one layer: data (`.tres`) → feature → scene orchestration.
3. Before adding to `core/`: confirm zero `src/` imports. Before splitting a feature: keep deps inside it.
4. New scene dependency → default `.tres` on the scene + optional runtime override from parent event.
5. Do not rename entrenched typos (`persisten_*`, `fsm game_states.gd`) unless asked.
6. Do not edit `addons/` or binary assets; reference `res://` paths.
7. Live context Resources (e.g. `game_config.tres`) are defaults/overridden at runtime — change level `.tres` or `GameConfig` schema for real content.
