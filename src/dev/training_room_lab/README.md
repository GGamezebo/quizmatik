# Training room lab (editor-only)

Frozen duplicate of the full practice / training room UI for development.

- Player-facing practice: `src/game/scenes/menu/training_room_window/` — redesign freely.
- This lab: opened from the main-menu bottom-left circle button, only when `OS.has_feature("editor")`.
- Separate save file: `user://training_lab_settings.json`.
- Separate `GameConfig` resource: `training_room_lab_game_config.tres`.
- **+1 ЗОЛОТАЯ** (right column): `ProfileController.add_gold(1)` on the active profile.
- **СБРОСИТЬ ПРОГРЕСС** (right column): deletes every profile, writes an empty save, pops the lab window, then AppRoot shows the first-run create overlay.

Do not import lab scripts from production practice code (or vice versa).
