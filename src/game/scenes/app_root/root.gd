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

var _listener: EventListener = EventListener.new()


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_start_game, _on_ev_start_game)
	_listener.add(root_events.ev_exit_game, _on_ev_exit_game)
	_listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)
	_listener.add(root_events.ev_profiles_changed, _on_profiles_changed)
	
	# Platform branch is picked inside App/Platform (PlatformRouterContext), never here.
	add_event("ev.open_platform", {
		"music_player": music_player,
		"root_events": root_events,
		"platform_services": platform_services,
	})

	music_player.play()
	_maybe_open_first_profile()
	_sync_tutorial()

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
	add_event("ev.open_menu", data)

func _on_profiles_changed() -> void:
	_maybe_open_first_profile()
	_sync_tutorial()


## Tutorial is a parallel HFSM state: open for a profile that hasn't finished it, close otherwise.
func _sync_tutorial() -> void:
	var needs_tutorial: bool = (
		profile_controller != null and profile_controller.has_profiles()
		and not progress_controller.is_tutorial_completed()
	)
	add_event("ev.open_tutorial" if needs_tutorial else "ev.close_tutorial")


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

func _apply_battle_result(data: Dictionary) -> void:
	var is_win: bool = data['is_win']
	var stars: int = data['stars']
	var game_config: GameConfig = data['game_config']
	var battle_info = game_config.battle_info
	# Bonus balloon gold is kept win or lose.
	var bonus_gold: int = int(data.get("bonus_gold", 0))
	if bonus_gold > 0:
		profile_controller.add_gold(bonus_gold)
	if not is_win:
		return
	var daily_result: Dictionary = daily_challenges_controller.register_win()
	var celebration: Dictionary = {}
	if battle_info:
		celebration = progress_controller.post_battle(battle_info, stars)
		var level_gold: int = int(celebration.get("level_gold", 0))
		celebration.erase("level_gold")
		if level_gold > 0:
			profile_controller.add_gold(level_gold)
			data["level_gold"] = level_gold
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
		if next_container_id.is_empty():
			root_events.ev_show_celebration.emit(CelebrationSplash.KIND_MASTER, {})
		else:
			root_events.ev_show_celebration.emit(CelebrationSplash.KIND_VALLEY, {"container_id": next_container_id})
