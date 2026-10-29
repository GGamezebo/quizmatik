extends IScene

## App-root HFSM scene: shared account/progress/music + RootEvents → HFSM bridge.

@export var root_events: RootEvents
@export var platform_services: PlatformServices
@export var progress_controller: ProgressController
@export var daily_challenges_controller: DailyChallengesController
@export var profile_controller: ProfileController
@export var mistakes_controller: MistakesController
@export var music_player: AudioStreamPlayer
@export var first_run_overlay: ProfileCreateOverlay
## «Сесть в самолёт» on the new-plane splash → equip it.
@export var celebration_splash: CelebrationSplash

var _listener: EventListener = EventListener.new()
## Pilot the controls intro was last opened for (new pilot on first flight → open it again).
var _intro_profile_id: String = ""


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_start_game, _on_ev_start_game)
	_listener.add(root_events.ev_exit_game, _on_ev_exit_game)
	_listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)
	_listener.add(root_events.ev_profiles_changed, _on_profiles_changed)
	if celebration_splash != null:
		_listener.add(celebration_splash.ev_board_plane, _on_board_plane)

	# Platform branch is picked inside App/Platform (PlatformRouterContext), never here.
	add_event("ev.open_platform", {
		"music_player": music_player,
		"root_events": root_events,
		"platform_services": platform_services,
	})

	music_player.play()
	_maybe_open_first_profile()
	_sync_tutorial()
	# Once per app session: «how to play» before the first battle (closes itself).
	_intro_profile_id = profile_controller.active_profile_id()
	add_event("ev.open_controls_intro")

func deinit() -> void:
	_listener.deinit()
	super.deinit()

## Every battle start (menu, retry, next level) gets the active profile's weak examples.
func _on_ev_start_game(data: Dictionary) -> void:
	var payload: Dictionary = data.duplicate()
	if mistakes_controller != null:
		payload["review_facts"] = mistakes_controller.review_facts()
	add_event("ev.start_game", payload)

func _on_ev_exit_game(data: Dictionary = {}) -> void:
	_apply_battle_result(data)
	add_event("ev.exit_game", data)

func _on_ev_return_to_menu(data: Dictionary = {}) -> void:
	_sync_tutorial()
	add_event("ev.open_menu", data)

func _on_board_plane(plane_id: String) -> void:
	profile_controller.equip_plane(plane_id)

func _on_profiles_changed() -> void:
	# Cloud save arrived while «Кто будет пилотом?» was open → the profile already exists.
	if first_run_overlay != null and first_run_overlay.visible and profile_controller.has_profiles():
		first_run_overlay.close()
	_maybe_open_first_profile()
	_sync_tutorial()
	_sync_controls_intro()


## Another pilot (new one, or switched to) still before the first flight → «how to play» again before
## that battle. Already open and unused → HFSM ignores the repeated enter event.
func _sync_controls_intro() -> void:
	var profile_id: String = profile_controller.active_profile_id()
	if profile_id.is_empty() or profile_id == _intro_profile_id:
		return
	_intro_profile_id = profile_id
	if not progress_controller.is_first_flight_done():
		add_event("ev.open_controls_intro")


## Tutorial is a parallel HFSM state: open for a profile that hasn't finished it (or has a late
## chapter due / awaited — endless intro, shop tour, mistakes intro, expert / flight-mode rounds), close otherwise.
func _sync_tutorial() -> void:
	var needs_tutorial: bool = (
		profile_controller != null and profile_controller.has_profiles()
		and (
			not progress_controller.is_tutorial_completed()
			or progress_controller.is_endless_intro_pending()
			or progress_controller.is_shop_tour_pending()
			or progress_controller.is_mistakes_intro_pending()
			or progress_controller.is_expert_intro_pending()
			or progress_controller.is_flight_mode_intro_pending()
		)
	)
	add_event("ev.open_tutorial" if needs_tutorial else "ev.close_tutorial")


func _apply_endless_record(data: Dictionary) -> void:
	var minutes: int = ProgressStatistics.record_new_minutes(
		int(data.get("endless_sec", 0)), int(data.get("endless_best_before", 0))
	)
	if minutes > 0:
		profile_controller.add_gold(ENDLESS_RECORD_GOLD * minutes)
		data["record_gold"] = ENDLESS_RECORD_GOLD * minutes
	if bool(daily_challenges_controller.register_win().get("gold_awarded", false)):
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_DAILY_GOLD, {})


func _maybe_open_first_profile() -> void:
	if profile_controller == null or first_run_overlay == null:
		return
	if profile_controller.has_profiles():
		return
	if not first_run_overlay.ev_submitted.is_connected(_on_first_profile_submitted):
		first_run_overlay.ev_submitted.connect(_on_first_profile_submitted)
	first_run_overlay.open(false, "Кто будет пилотом?")

func _on_first_profile_submitted(display_name: String, difficulty: StringName) -> void:
	if profile_controller == null:
		return
	profile_controller.create_profile(display_name, difficulty)

## Record battles (menu endless, valley clocks): each new record = one daily slot (the mode is never "won")
## + this gold per new whole record minute (`ProgressStatistics.record_new_minutes`: 2:45 → 3:00+ = +1).
const ENDLESS_RECORD_GOLD: int = 1
## Magister trial survived the first time (with the hall-of-fame award).
const MAGISTER_GOLD: int = 25
## Valley expert trial survived the first time (badge on the valley cup), same as the magister.
const EXPERT_GOLD: int = 25

func _apply_battle_result(data: Dictionary) -> void:
	var is_win: bool = data['is_win']
	var stars: int = data['stars']
	var game_config: GameConfig = data['game_config']
	var battle_info = game_config.battle_info
	# Bonus balloon gold is kept win or lose.
	var bonus_gold: int = int(data.get("bonus_gold", 0))
	if bonus_gold > 0:
		profile_controller.add_gold(bonus_gold)
	# Daily «Золотой полёт»: caught coin balloons + final pick, also on a HUD exit.
	var golden_gold: int = int(data.get("golden_gold", 0))
	if golden_gold > 0:
		profile_controller.add_gold(golden_gold)
	if bool(data.get("is_record", false)):
		_apply_endless_record(data)
	if not is_win:
		return
	if bool(data.get("magister", false)) and progress_controller.unlock_magister():
		profile_controller.add_gold(MAGISTER_GOLD)
		data["magister_gold"] = MAGISTER_GOLD
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_MAGISTER, {})
	var expert_valley_id := String(data.get("expert_valley_id", ""))
	if not expert_valley_id.is_empty() and progress_controller.unlock_expert(expert_valley_id):
		profile_controller.add_gold(EXPERT_GOLD)
		data["expert_gold"] = EXPERT_GOLD
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_EXPERT, {"container_id": expert_valley_id})
	var daily_result: Dictionary = daily_challenges_controller.register_win()
	var celebration: Dictionary = {}
	if battle_info:
		celebration = progress_controller.post_battle(battle_info, stars)
		var level_gold: int = int(celebration.get("level_gold", 0))
		celebration.erase("level_gold")
		if level_gold > 0:
			profile_controller.add_gold(level_gold)
			data["level_gold"] = level_gold
		var exam_gold: int = int(celebration.get("exam_gold", 0))
		var plane_refund_gold: int = int(celebration.get("plane_refund_gold", 0))
		var skip_gold: int = int(celebration.get("skip_gold", 0))
		celebration.erase("exam_gold")
		celebration.erase("plane_refund_gold")
		celebration.erase("skip_gold")
		if exam_gold + plane_refund_gold + skip_gold > 0:
			profile_controller.add_gold(exam_gold + plane_refund_gold + skip_gold)
			data["exam_gold"] = exam_gold + plane_refund_gold + skip_gold
			data["plane_refund"] = plane_refund_gold > 0
			data["skipped_levels"] = skip_gold > 0
		if not celebration.is_empty():
			data["exam_celebration"] = celebration
			if bool(celebration.get("first_exam_pass", false)):
				root_events.ev_celebration_hold.emit()
	if bool(daily_result.get("gold_awarded", false)):
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_DAILY_GOLD, {})
	var unlocked_plane_id := String(celebration.get("unlocked_plane_id", ""))
	if not unlocked_plane_id.is_empty():
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_PLANE, {"plane_id": unlocked_plane_id})
	var next_container_id := String(celebration.get("next_container_id", ""))
	if bool(celebration.get("first_exam_pass", false)):
		if bool(celebration.get("all_exams_passed", false)):
			root_events.ev_show_celebration.emit(CelebrationSplash.KIND_MASTER, {})
		elif not next_container_id.is_empty():
			root_events.ev_show_celebration.emit(CelebrationSplash.KIND_VALLEY, {"container_id": next_container_id})
