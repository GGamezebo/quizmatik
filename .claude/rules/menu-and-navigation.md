---
description: Menu, windows, and RootEvents navigation rules
paths:
  - "src/game/scenes/menu/**/*"
  - "src/game/scenes/app_root/**/*"
  - "src/game/scenes/post_battle/**/*"
  - "core/lib/window_stack_manager/**/*"
---

# Menu & navigation

## Layers

1. **Scenes** (Menu/Game/PostBattle) — only via `RootEvents`
2. **Full-screen windows** — only via `WindowStackManager`
3. **Dialogs/overlays** (confirm, pause popup) — NOT on the window stack

## Window stack

- One `WindowStackManager` per menu (under `MenuScene/UI`)
- **Forward:** `ButtonWindowTransition` (button → `open_stacked_window(target)`)
- **Back:** `ButtonWindowBack` (button → `close_stacked_window`) or `ui_cancel`
- Never “Back → open MainMenu”; always **pop** so nested paths work (`Main → Levels → LevelSelect`)
- Optional hooks on window scripts: `on_window_enter()` / `on_window_exit()`
- Keep `theme = style.tres` on each window root `Control`

## Game start

- Campaign: `{ "battle_info": GameConfig.BattleInfo(...) }`
- Training: `{ "custom_battle": GameConfig }`
- Return: `ev_return_to_menu` (optional `{ "open_level_select": container_id }` → Menu opens pack level grid)
- Quit battle: `ev_exit_game`

## Placement

- Level select → `menu/levels/` (pack carousel: centered looping valley + page dots; not a scrollbar). Pack carousel **and** level grid share the parent `BackgroundHost` (no remount on enter); isolated grid F6 keeps its own fallback valley
- Training → `menu/training_room_window/` — CTA frame `btn_cta_wide.png` (**980×620**), title «ПРАКТИКА» + subtitle; left cream settings panel (icon rows + steppers + ops grid), right exam/help side panels; bottom **СБРОСИТЬ** / green **НАЧАТЬ ПРАКТИКУ** / **СЛУЧАЙНЫЕ НАСТРОЙКИ** (`training_action_button.tscn`); unique lab/practice glyphs in `training_room_window/ui/` (never copy `menu/ui/` icons); back via `menu_window_back`
- Settings → `menu/settings_window/` — cream CTA frame `btn_cta_wide.png` (**680×540**), Label title «НАСТРОЙКИ»; first row «Язык» = `LanguagePicker` flags — `localization.md` (no reset-progress; wipe = delete profile; full wipe = editor lab)
- Profile → `menu/profile_window/` — «удостоверение пилота» card (plane photo, name + pencil → edit overlay, gold chip, cup chip → trophy room, always-on `DifficultyPicker`, plane strip → hangar) + right 2×2 pilot cards (`profile_card.tscn` template, active = green border + check; «+ Новый пилот» last). Separate red «УДАЛИТЬ ПИЛОТА» button under the cards (hidden when last profile) → `ConfirmDialog` re-opened for each of `DELETE_STEPS` (3 escalating warnings), delete only after the last confirm; cancel resets. Create overlay = name (prefilled «Пилот») + difficulty; edit overlay (`open(..., show_difficulty=false)`) = rename only → `ProfileController.rename_profile`
- Plane hangar → `menu/plane_hangar_window/` — tabs «САМОЛЁТЫ» / «ПОКРАСКА»; opens on «ПОКРАСКА» (main menu shop button `RightSideButtons/ShopBox/Shop`, under Profile; whole button pulses (`UiPulse` → wrapper `ShopBox`) via `menu/ui/shop_pulse.gd` (`MainMenuWindow/ShopPulse`) while gold covers any not-owned plane or cosmetic, re-check on `ev_profiles_changed` + button visibility), on «САМОЛЁТЫ» only via `planes_entry_buttons` (profile plane strip → tutorial `hangar.buy`). «ПОКРАСКА» = `CosmeticsPage` (8 items per slot; 6 slot chips → `cosmetic_card.tscn` grid; tap = try-on in the preview stage, one green CTA buys/equips; `CosmeticSwatch` draws trail/shot previews)
- Main menu background = `BackgroundHost` driven by `MenuCover` (equipped `CoverItem`; sits before the host so the first mount has no crossfade). Profile ID photo shows equipped paint + frame (`Polaroid` style) + sticker
- Main menu `CenterContainer/VBoxContainer` = `mouse_filter` IGNORE (it spans under the side buttons; else it eats their taps)
- Main menu right of the daily scroll: magister cap `MagisterEntry` (`menu/magister/`, anchored right, same y/size as the clock; icon inside the circle ring) — `architecture.md`
- Main menu left: mute buttons (top), endless clock `EndlessEntry` (`menu/endless/endless_entry.gd`, winged gold `stopwatch.png` — never the orange alarm `clock.svg`, below center left of the daily scroll, 160px circle, icon fits inside its ring (`Icon` 104×92); caption «Рекорд m:ss») — `architecture.md`
- Trophy room / stats → `menu/trophy_room_window/` — full-screen hangar achievements layout; shelf = 5 valley trophies + «Магистр» slot only once all 5 are unlocked (`are_all_valley_trophies_unlocked`; `TrophySlot.initialize_award`, `ui/trophies/trophy_magister.svg`): not earned → locked silhouette pulses, tap (`HintButton` → `ev_hint_pressed`) → own `MagisterRulesOverlay.open(false)`; earned → cup, no hint; `HallLamps` = two garlands of `hall_bulb.tscn` (top-left / top-right, `ui/lamps/`), grey until `ProgressController.is_hall_complete()` → light one by one + twinkle; bottom-right scroll (`ExtraSection`) = endless time record (`assets/ui/icons/stopwatch.png` + «РЕКОРД ВРЕМЕНИ»); while endless locked → rolled sealed `ui/scroll_closed.svg` + hint (`record_open_nodes` / `record_closed_nodes`); `HardFacts` panel between shelf and record scroll = top 3 weak examples (`PData.mistakes.top_keys`); tap (`HardFactsButton`) → `HardFactsOverlay` (overlay, not stack; rows = `hard_fact_row.tscn` template, `MathFact.display_with_answer` + misses) (AI look-match: `concepts/ART_DIRECTION.md`; never load files from `concepts/`)
- Shared window back overlay → `menu/ui/menu_window_back.tscn` (bottom-left; same as pack select)
- Main-menu quit → cream circle, black X, red ring (`menu/ui/btn_exit.png`); never a red X glyph
- Confirm overlays: cancel = `levels/ui/btn_back.png`, confirm = `menu/ui/btn_check.png`
- Daily card → `menu/daily/` under main-menu CTAs (`Ежедневная серия`); sky color from completed dailies via `BackgroundBase.paint_from_daily`. Header: title with days-in-a-row (`Texts/Streak`, RU plural) on a second line under it (VBox `separation` 6 keeps the stamps in place) + 5-day cycle strip right (`Cycle`: 4 pips + coin goal, `get_cycle_filled`). New stamps since last shown (`DailyChallengesPanel._seen_completed`, static, session-only) slam in (`DailySlot.play_stamp` → `RootEvents.ev_daily_stamp_landed` → SFX `stamp.wav` + vibration; `set_filled` idempotent). 5/5 with today's flight open → stamps `glow_out`, `GoldenState` «ЗОЛОТОЙ ПОЛЁТ» pops (`ev_daily_series_shown` → `series.wav`), whole scroll pulses and `ScrollButton` (full-rect) starts it: `start_bonus_flight()` first, then `ev_start_game {custom_battle: GoldenFlightScenario.build(golden_flight_config.tres, progress, 60 | 120 s on the cycle's 5th day)}`. Used → stamps back, no extra text. Post-battle of a golden flight: title «ЗОЛОТОЙ ПОЛЁТ!», no stamps row, no «repeat»
- Results → `post_battle/` — campaign valley (or random valley from training); color from dailies via `paint_from_daily`; endless payload (`endless_sec`) → `StampsRow` hidden, `EndlessRow` (`stopwatch.png` + record line), title «НОВЫЙ РЕКОРД!» / «ПОЛЁТ ОКОНЧЕН»
- Stack helpers → `core/lib/window_stack_manager/`
- Account/progress/daily/profile → `src/game/account/` (wired in `app_root/root.tscn`)
- First-run profile create + celebration splashes → overlays, **not** the window stack

## Avoid

- Second navigation stack/router beside `WindowStackManager`
- Loading `GameScene` from menu scripts directly
- Putting confirm/pause dialogs on the full-screen stack
- Building window UI trees in GDScript
