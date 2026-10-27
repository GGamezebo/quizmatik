# Training room lab (editor-only)

Frozen duplicate of the full practice / training room UI for development.

- Player-facing practice: `src/game/scenes/menu/training_room_window/` — redesign freely.
- This lab: opened from the main-menu bottom-left circle button, only when `OS.has_feature("editor")`.
- Separate save file: `user://training_lab_settings.json`.
- Separate `GameConfig` resource: `training_room_lab_game_config.tres`.
- **+1** / **+10** gold (right column, one row): `ProfileController.add_gold(n)` on the active profile.
- **ОТКРЫТЬ ВСЕ ДОЛИНЫ**: `ProgressController.unlock_all_containers()`; **ПРОЙТИ ВСЕ ДОЛИНЫ**: `complete_all_containers()` — every level + exam on 3 stars (opens the endless clock in the menu).
- **Экзамен:** row (+ − × ÷ ±): `pass_exam(id, 3)` for that valley; **Эксперт:** row: `complete_expert(id)` — valley opened, exam passed first if needed, expert trophy (badge on the valley card, level grid, trophy cup; no gold / celebration).
- **СБРОСИТЬ ПРОГРЕСС** (right column): deletes every profile, writes an empty save, pops the lab window, then AppRoot shows the first-run create overlay.

Do not import lab scripts from production practice code (or vice versa).
