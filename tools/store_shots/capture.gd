extends SceneTree

## Google Play phone screenshots of the live UI, one folder per game language.
## Run via tools/store_shots/capture.py. Never loaded by the game.
## Env: SHOT_DIR (absolute folder), SHOT_LOCALES (comma list, default all 12).

const MENU_SCENE := "res://src/game/scenes/menu/menu.tscn"
const GAME_SCENE := "res://src/game/scenes/game/game.tscn"
const CONFIG_PATH := "res://src/game/scenes/game/game_config.tres"
const PROFILE_SCENE := "res://src/game/account/profile_controller.tscn"
const LOCALES_ALL := ["ru", "en", "tr", "es", "pt", "de", "fr", "it", "pl", "uk", "id", "nl"]

const MENU_WAIT := 2.7
const WINDOW_WAIT := 0.55
const BATTLE_SCORE_AT := 3
const BATTLE_GIVE_UP := 45.0
const BOSS_GIVE_UP := 70.0

var _out_dir: String = ""
var _locales: PackedStringArray = []
var _locale_i: int = 0
var _fresh_config: GameConfig
var _pdata: PData
var _menu: Node
var _game: Node
var _plane: AirPlane
var _phase: String = "boot"
var _phase_t: float = 0.0
var _grab_path: String = ""
var _target_value: int = -999999
var _spawned_at: float = -1.0
var _battle_t: float = 0.0
var _boss_at: float = -1.0
var _battle_saved: bool = false
var _boss_saved: bool = false
var _last_shot: float = -10.0
var _tap_frames: int = 0
var _hold_shot: bool = false
var _aligned_for: float = 0.0
var _facts_ready: bool = false
var _question_text: String = ""


func _initialize() -> void:
	_out_dir = OS.get_environment("SHOT_DIR")
	var listed := OS.get_environment("SHOT_LOCALES")
	if listed == "":
		_locales = PackedStringArray(LOCALES_ALL)
	else:
		_locales = PackedStringArray(listed.split(","))
	for bus in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_lock_window()
	_pdata = load("res://src/game/account/persistent_data.tres")
	_fresh_config = ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	var profiles := (load(PROFILE_SCENE) as PackedScene).instantiate()
	root.add_child(profiles)
	_begin_locale()


func _process(delta: float) -> bool:
	if _grab_path != "":
		_save_png(_grab_path)
		_grab_path = ""
	_phase_t += delta
	match _phase:
		"menu":
			if _phase_t >= MENU_WAIT:
				_queue_grab("03_menu.png", "open_valleys")
		"open_valleys":
			_open_window("UI/LevelsWindow")
			_phase = "valleys"
			_phase_t = 0.0
		"valleys":
			if _phase_t >= WINDOW_WAIT:
				_queue_grab("04_valleys.png", "open_levels")
		"open_levels":
			_menu.get_node("UI/LevelsWindow").open_level_select("multiplication")
			_phase = "levels"
			_phase_t = 0.0
		"levels":
			if _phase_t >= WINDOW_WAIT:
				_queue_grab("05_levels.png", "open_practice")
		"open_practice":
			_show_practice()
			_phase = "practice"
			_phase_t = 0.0
		"practice":
			if _phase_t >= WINDOW_WAIT:
				_queue_grab("06_practice.png", "open_trophy")
		"open_trophy":
			_fill_trophies(_pdata)
			_open_window("UI/TrophyRoomWindow")
			_phase = "trophy"
			_phase_t = 0.0
		"trophy":
			if _phase_t >= WINDOW_WAIT:
				_queue_grab("07_trophies.png", "open_hangar")
		"open_hangar":
			_open_window("UI/PlaneHangarWindow")
			(_menu.get_node("UI/PlaneHangarWindow") as LazyWindow).content.call("open_on_planes")
			_phase = "hangar"
			_phase_t = 0.0
		"hangar":
			if _phase_t >= WINDOW_WAIT:
				_queue_grab("08_hangar.png", "start_battle")
		"start_battle":
			_start_battle()
			_phase = "battle"
			_phase_t = 0.0
		"battle":
			if _tick_battle(delta):
				# The grab is taken on the next frame. Quitting now would drop the boss shot.
				if _grab_path != "":
					_save_png(_grab_path)
					_grab_path = ""
				_finish_locale()
		"next":
			_finish_locale()
	return _locale_i >= _locales.size() and _phase == "done"


func _begin_locale() -> void:
	if _locale_i >= _locales.size():
		_phase = "done"
		return
	var code := _locales[_locale_i]
	TranslationServer.set_locale(code)
	_lock_window()
	_fill_profile(_pdata, code)
	DailyChallengesPanel._seen_completed = 3
	if _menu != null:
		_menu.queue_free()
	_menu = (load(MENU_SCENE) as PackedScene).instantiate()
	var title: Node = _menu.get_node("UI/MainMenuWindow/CenterContainer/VBoxContainer/MarginContainer/AnimatedTitle")
	title.set("idle_wave", false)
	var menu_bg: Node = _menu.get_node("UI/MainMenuWindow/Background")
	menu_bg.set("paint_from_daily", false)
	menu_bg.set("idle_color_amount", 1.0)
	root.add_child(_menu)
	current_scene = _menu
	_phase = "menu"
	_phase_t = 0.0
	print("SHOT locale %s" % code)


func _finish_locale() -> void:
	_release_move()
	if _game != null:
		_game.queue_free()
		_game = null
		_plane = null
	_locale_i += 1
	if _locale_i >= _locales.size():
		_phase = "done"
		if _menu != null:
			_menu.queue_free()
			_menu = null
		return
	_begin_locale()


func _open_window(path: String) -> void:
	var stack: WindowStackManager = _menu.get_node("UI/StackWindowController")
	stack.open_stacked_window(_menu.get_node(path))


func _show_practice() -> void:
	var train: Node = (_menu.get_node("UI/TrainingRoomWindow") as LazyWindow).load_content()
	train.set("_op_ids", {
		&"addition": &"r20",
		&"subtraction": &"r20",
		&"multiplication": &"t10",
		&"division": &"t10",
	})
	train.set("_difficulty", &"normal")
	train.set("_timed", false)
	train.call("_sync_ui")
	_open_window("UI/TrainingRoomWindow")


func _queue_grab(file_name: String, next_phase: String) -> void:
	root.gui_release_focus()
	Input.warp_mouse(Vector2(960, 16))
	var code := _locales[_locale_i]
	_grab_path = _out_dir.path_join(code).path_join(file_name)
	_phase = next_phase
	_phase_t = 0.0


func _save_png(path: String) -> void:
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := image.save_png(path)
	print("SHOT %s %dx%d err=%d" % [path, image.get_width(), image.get_height(), err])


func _fill_profile(pd: PData, code: String) -> void:
	pd.reset_to_defaults()
	pd.profile_id = "store_shot"
	pd.display_name = "Мия" if code == "ru" else ("Мія" if code == "uk" else "Mia")
	pd.difficulty = BattleDifficulty.NORMAL
	pd.state.tutorial_completed = true
	pd.gold = 8
	pd.equipped_plane_id = "gold"
	pd.unlocked_planes = ["starter", "fast", "green", "red", "gold"]
	pd.cosmetics.owned = ["paint_stars", "trail_rainbow", "shot_rainbow"]
	pd.cosmetics.equipped = {"paint": "paint_stars", "trail": "trail_rainbow", "shot": "shot_rainbow"}
	pd.statistics.total_answers = 640
	pd.statistics.facts_correct = 560
	pd.statistics.facts_wrong = 80
	pd.statistics.total_wins = 72
	pd.statistics.total_battles = 84
	pd.statistics.total_stars = 156
	pd.statistics.total_shoot_count = 900
	pd.statistics.battle_total_time = 12.0 * 60.0 + 5.0
	pd.statistics.total_time = pd.statistics.battle_total_time
	pd.statistics.game_sessions = 20
	pd.statistics.valley_endless_best_sec["addition"] = 154
	pd.daily.utc_day = PData.utc_day_key()
	pd.daily.slots = PData.DailyData.empty_slots()
	for slot in 3:
		pd.daily.slots[slot] = true
	pd.daily.streak_days = 3
	pd.daily.cycle_sets = 3
	pd.state.last_container_id = "addition"
	_mark_levels(pd, "addition", 20, true)
	_mark_levels(pd, "subtraction", 16, false)
	_mark_levels(pd, "mix", 6, false)
	_mark_levels(pd, "multiplication", 14, false)
	_mark_levels(pd, "division", 4, false)
	_give_mistakes(pd)


func _fill_trophies(pd: PData) -> void:
	for valley_id in ["addition", "subtraction", "multiplication", "division"]:
		_mark_levels(pd, valley_id, 20, true)
	pd.statistics.total_stars = 248
	pd.statistics.endless_best_sec = 412


func _mark_levels(pd: PData, valley_id: String, up_to: int, exam_passed: bool) -> void:
	var container := pd.levels.ensure_container(valley_id)
	container.unlocked = true
	container.exam_passed = exam_passed
	for level_id in range(1, up_to + 1):
		container.ensure_level(level_id).stars = 3


func _give_mistakes(pd: PData) -> void:
	var sample := {"mul:7:8": 6, "mul:6:7": 5, "add:8:7": 4, "mul:9:6": 3}
	for key in sample:
		pd.mistakes.misses[key] = sample[key]
		pd.mistakes.weights[key] = mini(int(sample[key]), MistakesController.MAX_WEIGHT)


func _start_battle() -> void:
	if _menu != null:
		_menu.queue_free()
		_menu = null
	var live: GameConfig = load(CONFIG_PATH)
	ResourceUtils.update_resource(live, _fresh_config)
	live.questions_count = 4
	live.allowed_operations = GameConfig.Operations.ADDITION
	live.min_generate_number = 2
	live.max_generate_number = 9
	live.answer_lines_count = 3
	live.answer_speed = 150.0
	live.health = 3
	live.boss_chance = 1.0
	live.boss_armor = 4
	live.boss_armor_max = 0
	live.boss_royal = false
	live.boss_royal_chance = 0.0
	live.bonus_gold_chance = 0.0
	live.missing_operand_chance = 0.0
	live.time_limit_sec = 0.0
	live.chase = false
	live.chase_chance = 0.0
	live.carry_mode = GameConfig.CarryMode.ANY
	live.operation_ranges = {}
	live.second_operand_ranges = {}
	live.result_ranges = {}
	live.review_facts = {}
	live.review_chance = 0.0

	_battle_saved = false
	_boss_saved = false
	_boss_at = -1.0
	_battle_t = 0.0
	_spawned_at = -1.0
	_target_value = -999999
	_last_shot = -10.0
	_tap_frames = 0
	_hold_shot = false
	_aligned_for = 0.0
	_facts_ready = false
	_question_text = ""

	var events: GameEvents = load("res://src/game/scenes/game/game_events.tres")
	if not events.ev_answers_spawned.is_connected(_on_answers_spawned):
		events.ev_answers_spawned.connect(_on_answers_spawned)
	if not events.ev_boss_appeared.is_connected(_on_boss_appeared):
		events.ev_boss_appeared.connect(_on_boss_appeared)
	if not events.ev_game_state_changed.is_connected(_on_state_changed):
		events.ev_game_state_changed.connect(_on_state_changed)

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	var bg: BackgroundHost = _game.get_node("HUD/Background")
	bg.variants = [ValleyBackgroundArt.get_scene("addition")]
	bg.pick_random = false
	bg.fixed_variant_index = 0
	# Root is already ready, so add_child runs _ready immediately — before current_scene
	# can be assigned. IScene only calls initialize when current_scene == self, so do it here.
	seed(7)
	root.add_child(_game)
	var ready_now := _game.is_node_ready()
	current_scene = _game
	_plane = _game.get_node("Player/AirPlane")
	if ready_now:
		_game.initialize({})


func _on_state_changed(_from_name: String, _to_name: String) -> void:
	_apply_look.call_deferred()


func _on_boss_appeared(_armor: int) -> void:
	_boss_at = _battle_t


func _on_answers_spawned(_answers: Array, correct_value: int, _lanes: Array, _missing: bool) -> void:
	_target_value = correct_value
	_spawned_at = _battle_t
	_aligned_for = 0.0
	if _game == null or not is_instance_valid(_game):
		return
	var banner := _game.get_node_or_null("HUD/QuestionBanner/Question") as Label
	_question_text = banner.text if banner != null else ""
	print("QUESTION %s -> %d" % [_question_text, correct_value])


func _apply_look() -> void:
	if _plane == null or not is_instance_valid(_plane):
		return
	var catalog: CosmeticCatalog = load("res://src/common/cosmetics/cosmetic_catalog.tres")
	_plane.apply_plane("gold")
	_plane.apply_paint(catalog.get_item("paint_stars") as PaintItem)
	_plane.apply_trail(catalog.get_item("trail_rainbow") as TrailItem)
	if _game == null or not is_instance_valid(_game):
		return
	var shots := _game.get_node_or_null("Controllers/ShotManager")
	if shots != null:
		shots.apply_style(catalog.get_item("shot_rainbow") as ShotItem)


func _tick_battle(delta: float) -> bool:
	_battle_t += delta
	if not _facts_ready and _battle_t > 0.1:
		# Isolated initialize wipes review_facts; put the showcase examples back before the first round.
		_facts_ready = true
		var live: GameConfig = load(CONFIG_PATH)
		live.review_facts = {"add:2:5": 4, "add:4:3": 4, "add:6:7": 4, "add:8:5": 4}
		live.review_chance = 1.0
	if _battle_t < 0.05:
		return false
	var player := _game.get_node_or_null("Player") as Player
	var view := _game.get_viewport().get_visible_rect().size
	if _tap_frames > 0:
		_tap_frames -= 1
		if _tap_frames == 0:
			_press_shoot(false)
	if not _battle_saved and player != null and player.score >= BATTLE_SCORE_AT and _boss_at < 0.0:
		if _composed(view, true):
			_aligned_for += delta
			if _aligned_for > 0.18:
				_save_battle_frame("01_battle.png")
				_battle_saved = true
				_aligned_for = 0.0
		else:
			_aligned_for = 0.0
	elif not _boss_saved and _boss_at >= 0.0 and _battle_t - _boss_at > 2.35:
		if _boss_composed(view):
			_aligned_for += delta
			if _aligned_for > 0.2:
				_save_battle_frame("02_boss.png")
				_boss_saved = true
		else:
			_aligned_for = 0.0
	if not _battle_saved and _battle_t > BATTLE_GIVE_UP:
		_save_battle_frame("01_battle.png")
		_battle_saved = true
		print("SHOT battle timeout")
	if _battle_saved and not _boss_saved and _battle_t > BOSS_GIVE_UP:
		_save_battle_frame("02_boss.png")
		_boss_saved = true
		print("SHOT boss timeout")
	_fly_bot(view)
	return _battle_saved and _boss_saved


func _save_battle_frame(file_name: String) -> void:
	root.gui_release_focus()
	var code := _locales[_locale_i]
	_grab_path = _out_dir.path_join(code).path_join(file_name)
	_hold_shot = true


func _composed(view: Vector2, require_align: bool) -> bool:
	if _plane == null or not _plane.is_processing():
		return false
	if _battle_t - _spawned_at < 0.15:
		return false
	var answers := _live_answers()
	if answers.size() < 3:
		return false
	var correct: Node2D = null
	for ans in answers:
		var x_ratio := ans.global_position.x / view.x
		if x_ratio < 0.58 or x_ratio > 0.94:
			return false
		if ans.value == _target_value:
			correct = ans
	if correct == null:
		return false
	if not require_align:
		return true
	return absf(correct.global_position.y - _plane.global_position.y) < 16.0


func _boss_composed(view: Vector2) -> bool:
	var ships := _game.find_children("*", "BossAirship", true, false)
	if ships.is_empty():
		return false
	var ship := ships[0] as Node2D
	var ship_x := ship.global_position.x / view.x
	if ship_x < 0.62 or ship_x > 1.02:
		return false
	var answers := _live_answers()
	if answers.size() < 2:
		return false
	var correct := false
	for ans in answers:
		var x_ratio := ans.global_position.x / view.x
		if x_ratio < 0.42 or x_ratio > 0.9:
			return false
		if ans.value == _target_value:
			correct = true
	return correct


func _live_answers() -> Array[Answer]:
	var out: Array[Answer] = []
	for node in _game.find_children("*", "Answer", true, false):
		var ans := node as Answer
		if ans == null or ans.is_queued_for_deletion() or not ans.visible or not ans.is_hittable():
			continue
		if ans is BonusBalloon or ans is HeartBalloon:
			continue
		out.append(ans)
	return out


func _fly_bot(view: Vector2) -> void:
	if _plane == null or not is_instance_valid(_plane) or not _plane.is_processing():
		_release_move()
		return
	var target := _find_target()
	if target == null:
		_release_move()
		return
	var dy: float = target.global_position.y - _plane.global_position.y
	if _battle_t - _spawned_at < 0.2 and not (target is BossAirship):
		_release_move()
		return
	if absf(dy) > 10.0:
		Input.action_press("ui_down" if dy > 0.0 else "ui_up")
		Input.action_release("ui_up" if dy > 0.0 else "ui_down")
		return
	_release_move()
	var block_shot := _hold_shot or (_boss_at >= 0.0 and not _boss_saved)
	_hold_shot = false
	if block_shot:
		return
	if target.global_position.x > view.x * 0.92:
		return
	if _battle_t - _last_shot > 0.55 and target.global_position.x > _plane.global_position.x + 140.0:
		if not (target is Answer) or (target as Answer).is_hittable():
			_last_shot = _battle_t
			_press_shoot(true)
			_tap_frames = 2


func _find_target() -> Node2D:
	if _boss_saved:
		for node in get_nodes_in_group("shot_targets"):
			var area := node as Area2D
			if area != null and not (area is Answer) and area.collision_layer != 0 and area.is_visible_in_tree():
				return area
	var best: Node2D = null
	for ans in _live_answers():
		if ans.global_position.x < _plane.global_position.x + 120.0:
			continue
		if ans.value == _target_value:
			best = ans
	return best


func _press_shoot(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"shoot"
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_move() -> void:
	Input.action_release("ui_up")
	Input.action_release("ui_down")


func _lock_window() -> void:
	# Borderless so Windows does not clamp the window to the work area (this monitor is < 1080p).
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
