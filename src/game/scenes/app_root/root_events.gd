class_name RootEvents
extends Resource

@warning_ignore("unused_signal") signal ev_start_game(data: Dictionary)
@warning_ignore("unused_signal") signal ev_exit_game(data: Dictionary)
@warning_ignore("unused_signal") signal ev_return_to_menu(data: Dictionary)
## Request writing PData to disk (handled only by SaveManager).
@warning_ignore("unused_signal") signal ev_save_progress
@warning_ignore("unused_signal") signal ev_battle_started
@warning_ignore("unused_signal") signal ev_battle_finished
@warning_ignore("unused_signal") signal ev_profiles_changed
@warning_ignore("unused_signal") signal ev_show_celebration(kind: String, payload: Dictionary)
@warning_ignore("unused_signal") signal ev_celebration_hold
@warning_ignore("unused_signal") signal ev_celebration_unhold
