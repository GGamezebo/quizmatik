# Training room lab (editor-only)

Frozen duplicate of the full practice / training room UI for development.

- Player-facing practice: `src/game/scenes/menu/training_room_window/` — redesign freely.
- This lab: opened from the main-menu bottom-left circle button, only when `OS.has_feature("editor")`.
- Separate save file: `user://training_lab_settings.json`.
- Separate `GameConfig` resource: `training_room_lab_game_config.tres`.
- **+1** / **+10** gold and **печать** (right column, one row): `ProfileController.add_gold(n)`; the stamp is `DailyChallengesController.register_win` (one slot; close the lab to see it slam in; five open the golden flight).
- **ОТКРЫТЬ ВСЕ ДОЛИНЫ**: `ProgressController.unlock_all_containers()`; **ПРОЙТИ ВСЕ ДОЛИНЫ**: `complete_all_containers()` — every level + exam on 3 stars (opens the endless clock in the menu).
- **Экзамен:** row (+ − × ÷ ±): `pass_exam(id, 3)` for that valley; **Эксперт:** row: `complete_expert(id)` — valley opened, exam passed first if needed, expert trophy (badge on the valley card, level grid, trophy cup; no gold / celebration).
- **Подсказки** panel (right column, 3×3): each button forgets one tutorial hint and makes its trigger true, then close the lab to see it — **Серия** (daily stamp; empty day → +1 win), **Самолёт** (buy a plane; gold topped up to the cheapest locked plane), **Магазин** (shop tour, armed; gold up to the cheapest look item), **Ошибки** (hard facts; none → seeds 7 × 8), **Рекорд** (menu clock intro + rules card; passes exams up to 4), **Эксперт** (rules card + coached first round; passes the first exam if none), **Магистр** (rules card; completes every expert if the cap is closed), **В бою** (the three battle tips). Base chapters / tips reopen the tutorial with all other base chapters and tips marked done.
- **СБРОСИТЬ ПРОГРЕСС** (right column): deletes every profile, writes an empty save, pops the lab window, then AppRoot shows the first-run create overlay.

Do not import lab scripts from production practice code (or vice versa).
