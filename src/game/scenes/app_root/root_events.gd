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
## Platform context reports app visibility (e.g. web tab hidden/minimized) → AppPauseController.
@warning_ignore("unused_signal") signal ev_app_visibility_changed(is_visible: bool)
## Menu daily card: a stamp slam hit the paper (`completes_series` = the 5th of the day) → SFX / vibration.
@warning_ignore("unused_signal") signal ev_daily_stamp_landed(completes_series: bool)
## Menu daily card: the stamps turned into «ЗОЛОТОЙ ПОЛЁТ» → SFX / vibration.
@warning_ignore("unused_signal") signal ev_daily_series_shown
## Overlay celebration (thank-you after a purchase) on / off → MusicController joyful theme, then back.
@warning_ignore("unused_signal") signal ev_celebration_music(is_on: bool)
## Tutorial: while on, the post-battle menu button goes to the main menu (not the valley level grid).
@warning_ignore("unused_signal") signal ev_post_battle_exit_home(is_on: bool)
