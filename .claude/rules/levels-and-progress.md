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

- Canonical files: `src/levels/{addition|subtraction|multiplication|division|mix}/level_1..20.tres`; **20 = exam** (`is_exam` in config; read it via `LevelsConfig.get_exam_level_id()`, never hardcode)
- EASY profile = grade-1 set `src/levels/{valley}/easy/level_1..20.tres` (± within 20, × / ÷ tables 2–5 + ×1 / ×10 (own intro levels L4 / L5, then mixed in); same ids / exams / timed / boss layout; progress shared) from generator `EASY_VALLEYS`; pick only via `LevelsConfig.get_level_config(container, level, difficulty)` (game.gd, `GoldenFlightScenario`); file missing → same init assert
- HARD profile (grade 3–4) = normal levels; `ProgressController.is_container_unlocked` → every valley open while `is_hard_difficulty()` (computed, never saved — back to NORMAL relocks valleys without a passed exam; paywall still applies, minus `OfferBoard.extra_free_by_difficulty` = multiplication on HARD). Exam on HARD never uses early-exam modifiers / «Усложнённый экзамен» dialog
- Container metadata + unlocks: `src/common/levels/levels_config.gd` (hand-edited); `record_operation` (one `GameConfig.Operations` flag, `get_record_operation`, 0 = none) = the valley record battle (addition / subtraction / multiplication / division)
- Bulk generation: `tools/generate_levels.py` = source of truth for the curriculum (kids 7-10, RU school order; per valley 4 acts + exam climbing through act skills via score stages 4/8/12). Edit the curve there and re-run (`python tools/generate_levels.py` rewrites only level `.tres`, keeps uids); never hand-patch level `.tres`
- Single-op valleys (addition / subtraction / multiplication / division, both sets, exam stages too) use only their own op — never mix in another (expert trial + golden flight read these levels); only `mix` mixes ops
- Pace authored as `t` = seconds per balloon flight on NORMAL (`answer_speed = 1100 / t`); new-skill (`intro`) levels: no `? + 3 = 7`, no speed ramp
- Generator constants: timed L9 + L17 (60 s); `boss_chance` 1.0 on L2, L5, L10, L15, exam (`boss_armor` 6 = all plate slots, `boss_rage_hits` 20, `boss_royal` true), .25 on other L3–19 non-timed; `bonus_gold_chance` .35 on L3–19; `CHASE_LEVELS` (`chase` true, boss / bonus 0; both sets) = L3, L7, L13, L19 of every valley (examples / pace unchanged); lines 3 on L1–3 else 4; never narrow `player_acceleration_*`
- Ignore legacy `src/levels/level_*.tres` at root
- Missing level file → assert at `LevelsConfig` init — always add file + config entry together

## GameConfig

- Schema: `src/common/game_config_default.gd`
- Level content = exported fields on level `.tres` (ops, ranges, speeds, health, questions)
- Example shape per op: `operation_ranges` (1st operand: addend / minuend / factor / divisor), `second_operand_ranges` (2nd: addend / subtrahend / factor / quotient), `result_ranges` (allowed answer), `carry_mode` (+/− through the ten: ANY / NONE / REQUIRED). Missing op entry → min/max_generate_number; missing 2nd → 1st
- Player difficulty: `BattleDifficulty.apply(config, id, base)` — coefficients on questions / `answer_speed` / round-speed extras (only speed-ups scale; < 1 exam-stage slow-downs kept) / boss armor (`boss_armor` preset, EASY .67, floor `MIN_SCALED_ARMOR` 2 → exam 6 → 4, mini-boss 3 → 2; all four armor fields via `scale_boss_armor`, training calls it after setting practice armor; level `.tres` keep NORMAL armor); **never health** (always 3 in training). Levels tuned for NORMAL ≈ 8 y.o.; EASY also swaps the content (easy level set above, `easy_*` endless / magister configs via `ProgressController.is_easy_difficulty()`)
- Mid-battle ramps: `answer_speed_round_coeffs` and `generate_number_round_ranges` (score → stage: min/max fall back to base; `GameConfig.STAGE_KEYS` replace and persist). Thresholds rescale with `questions_count` (`scale_round_thresholds`: difficulty preset + early exam)
- Do not permanently edit runtime `game/game_config.tres` (overwritten per battle)

## Progress

- Schema: `PData` (`src/game/account/persistent_data.gd`) — typed nested classes; live defaults in `persistent_data.tres` = **active profile**
- Save envelope v9 (v4 = tutorial chapters, v5 = `mistakes`, v6 = `ContainerProgress.unlocked`, v7 = `difficulty` replaces `gender`/`age`, v8 = `cosmetics`, v9 = exam level 17 → 20, passed valleys get 17-19 with exam stars): `{ active_profile_id, profiles }` (`SaveData.CURRENT_SAVE_VERSION`); switch stashes live PData into the slot
- Profile identity = `display_name` (empty → `ProfileController.DEFAULT_NAME` «Пилот», shown/prefilled translated via `display_name_or_default`; `create_profile` + new-pilot prefill use `unique_name()` → «Пилот 2», «Пилот 3»…, case-insensitive) + `PData.difficulty` (`BattleDifficulty` id). Never collect gender/age/other personal data (store requirements)
- `ProfileController` — create/switch/delete (never last), gold, equipped plane; `set_difficulty()` / `valley_difficulty()` → `BattleDifficulty` for valleys only; lab-only `wipe_all_profiles()` empties the envelope immediately (then first-run overlay)
- `PData.trophies.seen` — awards already shown in the trophy room (`award_ids` / `has_unseen_awards` / `mark_awards_seen`)
- `PData.trophies.unlocked` — valley exam trophies + expert awards `ProgressController.expert_trophy(id)` = `"expert:<id>"` (`unlock_expert` / `is_expert` / `are_all_experts_passed` → `is_magister_unlocked`; dev lab «ПРОЙТИ ВСЕ» = `complete_all_containers` unlocks them too) + `ProgressController.MAGISTER_TROPHY` ("magister", `unlock_magister()` / `is_magister()`); `is_hall_complete()` = all valley trophies + endless unlocked + magister (hall lamps); UI kit `tools/generate_achievements_ui.py`
- Disk: `SaveManager` + GodotSavesAddon (`SaveData`) profile `save` under `user://save/` (not plain `progress.json`)
- Campaign mutations: `ProgressController` only (incl. tutorial: `complete_tutorial()` / `complete_tutorial_step(id)` → `PData.state.tutorial_completed` / `tutorial_steps`; save v4 migration marks profiles with wins as completed)
- Statistics: `PData.statistics` mutated only by `StatisticsController` (AppRoot `Account/`) from `RootEvents` / `GameEvents`; `facts_correct` / `facts_wrong` = `ev_fact_answered` (one per question, first try) → `StatisticsData.first_try_percent()` (-1 = none; parents window + paywall); parent-facing time = `ProgressStatistics.format_hours_minutes`; record battles: `endless_best_sec` (menu) + `valley_endless_best_sec` (valley id → s) only via `record_endless(valley_id, sec)` / read `endless_best(valley_id)` ("" = menu); new keys additive, no save bump
- Weak examples: `PData.mistakes` (`MathFact` key → `weights` + `misses`) mutated only by `MistakesController` (AppRoot `Account/`) on `GameEvents.ev_fact_answered`: miss weight +2 (cap 6) and misses +1, clean correct weight −1; weight 0 → `erase()` from both dicts; max 50 facts (trim drops tail of `top_keys`). `top_keys` order = misses desc → weight desc → key. AppRoot `_on_ev_start_game` adds payload `review_facts` (top 10 keys → weights) to **every** battle start
- Daily challenges (UTC day, 5 win-slots): `DailyChallengesController` — any battle win fills one slot; 5/5 first time that day → +1 gold and one «Золотой полёт» (`PData.daily.bonus_flight_played`; `can_start_bonus_flight` / `start_bonus_flight`). Day streak: `daily.streak_days` + `last_complete_day` (5/5 days in a row; a day without 5/5 → 0 on the next `_ensure_today`); cycle `STREAK_CYCLE` 5 → `get_cycle_filled()` (resets after the 5th day's flight / next day), `is_big_flight_today()` = 120 s flight. Additive keys, no save bump. Battle config = `menu/daily/golden_flight_scenario.gd` (`GoldenFlightScenario`): frontier = furthest unlocked regular level of the last unlocked valley → its `.tres` + `BattleDifficulty` of the profile, golden overlay (no boss / bonus balloon / heal); no progress → template `golden_flight_config.tres`. Gold = payload `golden_gold` (caught coins + final pick), granted by AppRoot `_apply_battle_result` win or HUD exit
- Level gold: regular level first reaching 3★ → +1 gold (`ProgressController.pass_level` returns amount, `post_battle` → `{level_gold}`; AppRoot grants via `ProfileController.add_gold`, passes `level_gold` to PostBattle label). Exam gives no level gold; first exam pass → `pass_exam` result `exam_gold` (`EXAM_FIRST_PASS_GOLD` 5) + `plane_refund_gold` (exam plane already bought → `PLANE_REFUND_SHARE` ½ of its `gold_cost`); AppRoot grants both → payload `exam_gold` + `plane_refund` → post-battle «+N за экзамен [и купленный самолёт]» (dev lab `pass_exam` grants no gold)
- HARD skip gold: first exam pass on HARD → `pass_exam` result `skip_gold` = `HARD_SKIP_LEVEL_GOLD` (2) × regular levels with 0 stars before the pass (`skip_gold_for`); AppRoot adds it to `exam_gold` + payload `skipped_levels` → post-battle «+%d за экзамен и пропущенные уровни». Exam result `next_container_id` only when the pass really opens it, else the next id goes to `open_next_container_id` (HARD offer splash); `all_exams_passed` drives `KIND_MASTER` / «все долины покорены»
- Prices: planes `PlaneCatalog` `gold_cost` 1 / 40 / 90 / 180 (fast stays 1 — first purchase after the first flight; others mostly come free from exams); top cosmetics 20–35 — rationale `.claude/doc/balance_gold.md`
- Bonus gold: `GameConfig.bonus_gold_chance` (default 0 = practice / exam / L1–2) → ≤1 golden balloon per battle; payload `bonus_gold` granted by AppRoot `_apply_battle_result` **before** the win check (kept on lose / HUD exit; lost on in-battle restart); PostBattle `BonusGold` label
- Cosmetics: `PData.cosmetics` (`owned` ids, `equipped` slot key → id; keys = `CosmeticItem.SLOT_KEYS`, never rename) mutated only by `CosmeticsController.try_buy` / `equip` (spends `pdata.gold`); free items never stored
- Cloud copy (`PlatformServices.can_cloud_save`): `SaveManager` pulls once per cap-on, `CloudSaveCodec` (`src/game/account/`) = JSON envelope `{version, saved_at, active_profile_id, profiles}` (< 190 KB, version > game → ignored, older → `SaveData.migrate_envelope`). Rule: newer `saved_at` (unix s, stamped on each local write; unsaved changes = now) wins, equal = in sync; cloud wins → replace profiles, `apply_dict`, local write, `ev_profiles_changed` (AppRoot closes first-run overlay). Pull answer during battle is deferred to battle end. Push: never before the first pull answered, never with no profiles; coalesced `CLOUD_PUSH_SEC`, immediate on battle end / pause / focus-out / close. Settings (`UserSettings`) stay local
- `project.godot` `config/custom_user_dir_name="quizmatic"` keeps `user://` = old folder after the display rename to «Jet Math» — never drop it (desktop saves would be orphaned)
- Disk write: only `SaveManager` (controllers emit `RootEvents.ev_save_progress` → `save()`)
- `save()` is **debounced** (`SAVE_DEBOUNCE_SEC`, restarts on each request): no synchronous write per mutation
- **Never writes during battle** (`ev_battle_started`→`ev_battle_finished`); force-flush at battle end
- Force-flush on `ev_battle_finished`, app close/back, pause, focus-out
- Shared live resource: all controllers / trophy room `@export` the same `persistent_data.tres`; `SaveManager.load_pdata()` mutates the **active** profile via `PData.apply_dict`
- Int level keys restored in `PData.ContainerProgress.from_dict` (JSON string keys → `int`)
- Schema migrations: `SaveData.migrate_save_data` / `CURRENT_SAVE_VERSION` (addon), not a separate migrator class
- Last valley: `PData.state.last_container_id` (per profile) — set only via `ProgressController.set_last_container_id` from `levels_choice_window` (carousel selection / valley enter); carousel `finalize` starts on it (app start, back from battle). Never keep the selected valley only in carousel index
- Unlock helpers: `LevelsContainerConditions` in `conditions.gd`; `ContainerProgress.unlocked` (dev lab «open all valleys», `ProgressController.unlock_all_containers()`; «pass all valleys» = `complete_all_containers()`; `is_endless_unlocked()` = `passed_valley_exams_count() >= ENDLESS_UNLOCK_EXAMS` (4) → endless battle) opens a valley regardless of its condition, levels inside stay sequential
- Settings: `UserSettings` (incl. `language`, "" = auto) → `user://settings.json` (JSON via `ResourceUtils`); `save()` emits `ev_changed` so mute UI / buses can resync without scene NodePaths

## Must

- Keep `container_id` strings stable (progress keys)
- Bump save version + add migration in `SaveData` when schema changes
- Daily rollover via `PData.utc_day_key()` (UTC); menu slots are display-only (not clickable)
