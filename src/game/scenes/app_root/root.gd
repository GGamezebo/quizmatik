extends IScene

## App-root HFSM scene: shared account/progress/music + RootEvents → HFSM bridge.

@export var root_events: RootEvents
@export var progress_controller: ProgressController
@export var daily_challenges_controller: DailyChallengesController
@export var profile_controller: ProfileController
@export var music_player: AudioStreamPlayer
@export var first_run_overlay: ProfileCreateOverlay

var _listener: EventListener = EventListener.new()


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_start_game, _on_ev_start_game)
	_listener.add(root_events.ev_exit_game, _on_ev_exit_game)
	_listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)
	
	if OS.has_feature("web"):
		add_event("ev.open_web", {"music_player": music_player})
		
	music_player.play()
	_maybe_open_first_profile()

func deinit() -> void:
	_listener.deinit()
	super.deinit()

func _on_ev_start_game(data: Dictionary) -> void:
	add_event("ev.start_game", data)

func _on_ev_exit_game(data: Dictionary = {}) -> void:
	_apply_battle_result(data)
	add_event("ev.exit_game", data)

func _on_ev_return_to_menu(data: Dictionary = {}) -> void:
	add_event("ev.open_menu", data)

func _maybe_open_first_profile() -> void:
	if profile_controller == null or first_run_overlay == null:
		return
	if profile_controller.has_profiles():
		return
	if not first_run_overlay.ev_submitted.is_connected(_on_first_profile_submitted):
		first_run_overlay.ev_submitted.connect(_on_first_profile_submitted)
	first_run_overlay.open(false, "Кто будет пилотом?")

func _on_first_profile_submitted(display_name: String, gender: String, age: int) -> void:
	if profile_controller == null:
		return
	profile_controller.create_profile(display_name, gender, age)

func _apply_battle_result(data: Dictionary) -> void:
	var is_win: bool = data['is_win']
	var stars: int = data['stars']
	var game_config: GameConfig = data['game_config']
	var battle_info = game_config.battle_info
	if not is_win:
		return
	var daily_result: Dictionary = daily_challenges_controller.register_win()
	var celebration: Dictionary = {}
	if battle_info:
		celebration = progress_controller.post_battle(battle_info, stars)
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
	if bool(celebration.get("first_exam_pass", false)) and not next_container_id.is_empty():
		root_events.ev_show_celebration.emit(CelebrationSplash.KIND_VALLEY, {"container_id": next_container_id})
