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
- Settings → `menu/settings_window/` — cream CTA frame `btn_cta_wide.png` (**680×540**), Label title «НАСТРОЙКИ» (no reset-progress; wipe = delete profile; full wipe = editor lab)
- Profile → `menu/profile_window/` — «удостоверение пилота» card (plane photo, name + pencil → edit overlay, gold chip, cup chip → trophy room, always-on `DifficultyPicker`, plane strip → hangar) + right 2×2 pilot cards (`profile_card.tscn` template, active = green border + check; «+ Новый пилот» last). Separate red «УДАЛИТЬ ПИЛОТА» button under the cards (hidden when last profile) → `ConfirmDialog` re-opened for each of `DELETE_STEPS` (3 escalating warnings), delete only after the last confirm; cancel resets. Create overlay = name (prefilled «Пилот») + difficulty; edit overlay (`open(..., show_difficulty=false)`) = rename only → `ProfileController.rename_profile`
- Plane hangar → `menu/plane_hangar_window/` — tabs «САМОЛЁТЫ» / «ПОКРАСКА»; opens on «ПОКРАСКА» (main menu shop button `RightSideButtons/Shop`, under Profile), on «САМОЛЁТЫ» only via `planes_entry_buttons` (profile plane strip → tutorial `hangar.buy`). «ПОКРАСКА» = `CosmeticsPage` (8 items per slot; 6 slot chips → `cosmetic_card.tscn` grid; tap = try-on in the preview stage, one green CTA buys/equips; `CosmeticSwatch` draws trail/shot previews)
- Main menu background = `BackgroundHost` driven by `MenuCover` (equipped `CoverItem`; sits before the host so the first mount has no crossfade). Profile ID photo shows equipped paint + frame (`Polaroid` style) + sticker
- Trophy room / stats → `menu/trophy_room_window/` — full-screen hangar achievements layout; `HardFacts` panel between shelf and extra scroll = top 3 weak examples (`PData.mistakes.top_keys`); tap (`HardFactsButton`) → `HardFactsOverlay` (overlay, not stack; rows = `hard_fact_row.tscn` template, `MathFact.display_with_answer` + misses) (AI look-match: `concepts/ART_DIRECTION.md`; never load files from `concepts/`)
- Shared window back overlay → `menu/ui/menu_window_back.tscn` (bottom-left; same as pack select)
- Main-menu quit → cream circle, black X, red ring (`menu/ui/btn_exit.png`); never a red X glyph
- Confirm overlays: cancel = `levels/ui/btn_back.png`, confirm = `menu/ui/btn_check.png`
- Daily slots (display-only) → `menu/daily/` under main-menu CTAs (`Ежедневная серия`); sky color from completed dailies via `BackgroundBase.paint_from_daily`
- Results → `post_battle/` — campaign valley (or random valley from training); color from dailies via `paint_from_daily`
- Stack helpers → `core/lib/window_stack_manager/`
- Account/progress/daily/profile → `src/game/account/` (wired in `app_root/root.tscn`)
- First-run profile create + celebration splashes → overlays, **not** the window stack

## Avoid

- Second navigation stack/router beside `WindowStackManager`
- Loading `GameScene` from menu scripts directly
- Putting confirm/pause dialogs on the full-screen stack
- Building window UI trees in GDScript
