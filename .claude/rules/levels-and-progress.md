---
description: Levels, GameConfig, and progress persistence rules
paths:
  - "src/common/**/*"
  - "src/levels/**/*"
  - "src/game/account/**/*"
  - "tools/**/*"
---

# Levels & progress

## Levels

- Canonical files: `src/levels/{addition|subtraction|multiplication|division|mix}/level_N.tres`
- Container metadata + unlocks: `src/common/levels/levels_config.gd`
- Bulk generation: `tools/generate_levels.py` holds the curve (incl. `missing_operand_chance`: L1–5 0, L6–9 .3, L10–16 .5, exam .4; `bonus_gold_chance`: L3–16 .35, else 0)
- ⚠ Do NOT run its `main()`: `make_levels_config()` is stale vs `levels_config.gd` and would drop code. Patch `.tres` surgically + mirror in the generator.
- Ignore legacy `src/levels/level_*.tres` at root
- Missing level file → assert at `LevelsConfig` init — always add file + config entry together

## GameConfig

- Schema: `src/common/game_config_default.gd`
- Level content = exported fields on level `.tres` (ops, ranges, speeds, health, questions)
- Player difficulty: `BattleDifficulty.apply(config, id, base)` — coefficients on questions / `answer_speed` / round-speed extras; **never health** (always 3 in training)
- Mid-battle ramps: `answer_speed_round_coeffs` and optional `generate_number_round_ranges` (score → min/max)
- Do not permanently edit runtime `game/game_config.tres` (overwritten per battle)

## Progress

- Schema: `PData` (`src/game/account/persistent_data.gd`) — typed nested classes; live defaults in `persistent_data.tres` = **active profile**
- Save envelope v5 (v4 = tutorial chapters, v5 = `mistakes`): `{ active_profile_id, profiles }` (`SaveData.CURRENT_SAVE_VERSION`); switch stashes live PData into the slot
- `ProfileController` — create/switch/delete (never last), gold, equipped plane; age → `BattleDifficulty` for valleys only; lab-only `wipe_all_profiles()` empties the envelope immediately (then first-run overlay)
- `PData.trophies.unlocked` — valley exam trophies; UI kit `tools/generate_achievements_ui.py`
- Disk: `SaveManager` + GodotSavesAddon (`SaveData`) profile `save` under `user://save/` (not plain `progress.json`)
- Campaign mutations: `ProgressController` only (incl. tutorial: `complete_tutorial()` / `complete_tutorial_step(id)` → `PData.state.tutorial_completed` / `tutorial_steps`; save v4 migration marks profiles with wins as completed)
- Weak examples: `PData.mistakes` (`MathFact` key → `weights` + `misses`) mutated only by `MistakesController` (AppRoot `Account/`) on `GameEvents.ev_fact_answered`: miss weight +2 (cap 6) and misses +1, clean correct weight −1; weight 0 → `erase()` from both dicts; max 50 facts (trim drops tail of `top_keys`). `top_keys` order = misses desc → weight desc → key. AppRoot `_on_ev_start_game` adds payload `review_facts` (top 10 keys → weights) to **every** battle start
- Daily challenges (UTC day, 5 win-slots): `DailyChallengesController` — any battle win fills one slot; 5/5 first time that day → +1 gold
- Level gold: regular level first reaching 3★ → +1 gold (`ProgressController.pass_level` returns amount, `post_battle` → `{level_gold}`; AppRoot grants via `ProfileController.add_gold`, passes `level_gold` to PostBattle label). Exam gives no level gold
- Bonus gold: `GameConfig.bonus_gold_chance` (default 0 = practice / exam / L1–2) → ≤1 golden balloon per battle; payload `bonus_gold` granted by AppRoot `_apply_battle_result` **before** the win check (kept on lose / HUD exit; lost on in-battle restart); PostBattle `BonusGold` label
- Disk write: only `SaveManager` (controllers emit `RootEvents.ev_save_progress` → `save()`)
- `save()` is **debounced** (`SAVE_DEBOUNCE_SEC`, restarts on each request): no synchronous write per mutation
- **Never writes during battle** (`ev_battle_started`→`ev_battle_finished`); force-flush at battle end
- Force-flush on `ev_battle_finished`, app close/back, pause, focus-out
- Shared live resource: all controllers / trophy room `@export` the same `persistent_data.tres`; `SaveManager.load_pdata()` mutates the **active** profile via `PData.apply_dict`
- Int level keys restored in `PData.ContainerProgress.from_dict` (JSON string keys → `int`)
- Schema migrations: `SaveData.migrate_save_data` / `CURRENT_SAVE_VERSION` (addon), not a separate migrator class
- Unlock helpers: `LevelsContainerConditions` in `conditions.gd`
- Settings: `UserSettings` → `user://settings.json` (JSON via `ResourceUtils`); `save()` emits `ev_changed` so mute UI / buses can resync without scene NodePaths

## Must

- Keep `container_id` strings stable (progress keys)
- Bump save version + add migration in `SaveData` when schema changes
- Daily rollover via `PData.utc_day_key()` (UTC); menu slots are display-only (not clickable)
