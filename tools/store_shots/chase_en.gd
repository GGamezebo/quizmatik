extends SceneTree

## One English store frame: a chase battle on the space map.
## Run via tools/store_shots/chase_en.py. Never loaded by the game.

const GAME_SCENE := "res://src/game/scenes/game/game.tscn"
const CONFIG_PATH := "res://src/game/scenes/game/game_config.tres"
const PROFILE_SCENE := "res://src/game/account/profile_controller.tscn"
const SPACE_SCENE := "res://src/ui/backgrounds/space/space_background.tscn"
const OUT_PATH := "D:/Godot/MyProjects/quizmatik/tools/store_shots/_preview/chase_raw.png"

var _game: Node
var _plane: AirPlane
var _started: bool = false
var _battle_t: float = 0.0
var _spawned_at: float = -1.0
var _target_value: int = -999999
var _grab: bool = false
var _last_shot: float = -10.0
var _tap_frames: int = 0
var _stable: float = 0.0
var _logged: float = 0.0
var _best_x: float = -9999.0
var _shot_spawn: float = -999.0


func _initialize() -> void:
	for bus in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus, true)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	TranslationServer.set_locale("en")

	var pdata: PData = load("res://src/game/account/persistent_data.tres")
	pdata.reset_to_defaults()
	pdata.profile_id = "store_shot"
	pdata.display_name = "Mia"
	pdata.difficulty = BattleDifficulty.NORMAL
	pdata.state.tutorial_completed = true
	pdata.gold = 8
	pdata.equipped_plane_id = "gold"
	pdata.unlocked_planes = ["starter", "fast", "green", "red", "gold"]
	pdata.cosmetics.owned = ["paint_stars", "trail_rainbow", "shot_rainbow"]
	pdata.cosmetics.equipped = {"paint": "paint_stars", "trail": "trail_rainbow", "shot": "shot_rainbow"}
	root.add_child((load(PROFILE_SCENE) as PackedScene).instantiate())


func _process(delta: float) -> bool:
	if not _started:
		if not root.is_node_ready():
			return false
		_start_battle()
		_started = true
		return false
	if _grab:
		_save()
		return true
	_battle_t += delta
	if _game == null:
		return false
	if _tap_frames > 0:
		_tap_frames -= 1
		if _tap_frames == 0:
			_press_shoot(false)
	var player := _game.get_node_or_null("Player") as Player
	var view := _game.get_viewport().get_visible_rect().size
	var score := 0
	if player != null:
		score = player.score
	# Two correct answers step the plane right, so the chasers are fully on screen
	# when they close in again. Then hold the middle lane and keep the closest frame.
	if score < 2:
		_fly(view)
	else:
		_center_on_lane(view)
	var min_x := _min_ship_x()
	if score >= 2 and _answers_ready(view) and min_x > _best_x + 12.0 and _ships_behind():
		_best_x = min_x
		_save()
		print("POSE kept min_x=%.0f score=%d" % [min_x, score])
	if score >= 2 and _best_x > 80.0 and not _ships_behind():
		print("POSE stop min_x=%.0f best=%.0f" % [min_x, _best_x])
		return true
	if _battle_t - _logged > 2.0:
		_logged = _battle_t
		_log_pose(score, view)
	if _battle_t > 32.0:
		print("SHOT timeout")
		_log_pose(score, view)
		return true
	return false


func _start_battle() -> void:
	# Mount from _process: the tree is ready, so add_child runs _ready immediately,
	# before current_scene is assigned. IScene then does not auto-initialize.
	var scenario: GameConfig = (load(CONFIG_PATH) as GameConfig).duplicate(true)
	scenario.questions_count = 4
	scenario.allowed_operations = GameConfig.Operations.ADDITION
	scenario.min_generate_number = 2
	scenario.max_generate_number = 9
	scenario.answer_lines_count = 3
	scenario.answer_speed = 220.0
	scenario.health = 3
	scenario.boss_chance = 0.0
	scenario.timed_boss_chance = 0.0
	scenario.boss_armor_max = 0
	scenario.boss_royal = false
	scenario.boss_royal_chance = 0.0
	scenario.bonus_gold_chance = 0.0
	scenario.missing_operand_chance = 0.0
	scenario.time_limit_sec = 0.0
	scenario.endless = false
	scenario.golden_flight = false
	scenario.hidden_pair = false
	scenario.chase = true
	scenario.chase_chance = 0.0
	scenario.carry_mode = GameConfig.CarryMode.ANY
	scenario.operation_ranges = {}
	scenario.second_operand_ranges = {}
	scenario.result_ranges = {}
	scenario.review_facts = {"add:7:6": 4}
	scenario.review_chance = 1.0

	var events: GameEvents = load("res://src/game/scenes/game/game_events.tres")
	if not events.ev_answers_spawned.is_connected(_on_answers):
		events.ev_answers_spawned.connect(_on_answers)
	if not events.ev_game_state_changed.is_connected(_on_state):
		events.ev_game_state_changed.connect(_on_state)

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	var bg: BackgroundHost = _game.get_node("HUD/Background")
	var space: PackedScene = load(SPACE_SCENE)
	bg.variants = [space]
	bg.pick_random = false
	bg.fixed_variant_index = 0
	seed(7)
	root.add_child(_game)
	var ready_now := _game.is_node_ready()
	current_scene = _game
	_plane = _game.get_node("Player/AirPlane")
	if ready_now:
		_game.initialize({
			"custom_battle": scenario,
			"review_facts": {"add:7:6": 4},
		})
	var live: GameConfig = _game.game_config
	live.chase = true
	live.chase_chance = 0.0
	live.boss_chance = 0.0
	live.questions_count = 4
	live.answer_lines_count = 3
	live.allowed_operations = GameConfig.Operations.ADDITION
	live.review_facts = {"add:7:6": 4}
	live.review_chance = 1.0
	print("POSE config q=%d lines=%d ops=%d chase=%s" % [
		live.questions_count, live.answer_lines_count, live.allowed_operations, live.chase,
	])
	_apply_look()


func _on_state(_from_name: String, _to_name: String) -> void:
	_apply_look.call_deferred()


func _on_answers(_answers: Array, correct_value: int, _lanes: Array, _missing: bool) -> void:
	_target_value = correct_value
	_spawned_at = _battle_t
	var banner := _game.get_node_or_null("HUD/QuestionBanner/Question") as Label
	var text := ""
	if banner != null:
		text = banner.text
	print("QUESTION %s -> %d" % [text, correct_value])


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


func _answers_ready(view: Vector2) -> bool:
	if _spawned_at < 0.0 or _battle_t - _spawned_at < 0.35:
		return false
	var answers := _live_answers()
	if answers.size() < 3:
		return false
	for ans in answers:
		var ratio := ans.global_position.x / view.x
		if ratio < 0.62 or ratio > 0.97:
			return false
	return true


func _min_ship_x() -> float:
	var ships := _game.find_children("*", "BossAirship", true, false)
	if ships.size() < 3:
		return -9999.0
	var min_x := 99999.0
	for node in ships:
		var ship := node as Node2D
		if ship == null:
			return -9999.0
		min_x = minf(min_x, ship.global_position.x)
	return min_x


## Nose is still behind the plane: the chief has not started the ram.
func _ships_behind() -> bool:
	if _plane == null or not is_instance_valid(_plane):
		return false
	var ships := _game.find_children("*", "BossAirship", true, false)
	if ships.size() < 3:
		return false
	var limit := _plane.global_position.x - 220.0
	for node in ships:
		var ship := node as Node2D
		if ship == null or ship.global_position.x > limit:
			return false
	return true


func _ships_in(view: Vector2) -> bool:
	return _ships_framed(view)


## All three hulls on screen, clearly behind the plane, not overlapping it.
func _ships_framed(view: Vector2) -> bool:
	if _plane == null or not is_instance_valid(_plane):
		return false
	var ships := _game.find_children("*", "BossAirship", true, false)
	if ships.size() < 3:
		return false
	var plane_x := _plane.global_position.x
	for node in ships:
		var ship := node as Node2D
		if ship == null:
			return false
		var x := ship.global_position.x
		var y := ship.global_position.y
		# Centers sit left of the art; 190 keeps the tail of the rearmost wing on screen.
		if x < 190.0 or x > plane_x - 150.0:
			return false
		if y < 40.0 or y > view.y - 30.0:
			return false
	return true


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


func _fly(view: Vector2) -> void:
	if _plane == null or not is_instance_valid(_plane) or not _plane.is_processing():
		_release_move()
		return
	var target: Answer = null
	for ans in _live_answers():
		if ans.value == _target_value and ans.global_position.x > _plane.global_position.x + 80.0:
			target = ans
			break
	if target == null:
		_release_move()
		return
	var dy := target.global_position.y - _plane.global_position.y
	if absf(dy) > 12.0:
		Input.action_press("ui_down" if dy > 0.0 else "ui_up")
		Input.action_release("ui_up" if dy > 0.0 else "ui_down")
		return
	_release_move()
	if target.global_position.x > view.x * 0.94:
		return
	if _shot_spawn == _spawned_at:
		return
	if _battle_t - _spawned_at < 0.35:
		return
	_shot_spawn = _spawned_at
	_last_shot = _battle_t
	_press_shoot(true)
	_tap_frames = 2


func _center_on_lane(view: Vector2) -> void:
	if _plane == null or not is_instance_valid(_plane):
		_release_move()
		return
	var answers := _live_answers()
	var target_y := view.y * 0.55
	if answers.size() >= 3:
		var ys: Array[float] = []
		for ans in answers:
			ys.append(ans.global_position.y)
		ys.sort()
		target_y = ys[1]
	var dy := target_y - _plane.global_position.y
	if absf(dy) > 14.0:
		Input.action_press("ui_down" if dy > 0.0 else "ui_up")
		Input.action_release("ui_up" if dy > 0.0 else "ui_down")
		return
	_release_move()


func _log_pose(score: int, view: Vector2) -> void:
	var ships := ""
	for node in _game.find_children("*", "BossAirship", true, false):
		var ship := node as Node2D
		if ship == null:
			continue
		ships += " %.0f,%.0f" % [ship.global_position.x, ship.global_position.y]
	var answers := ""
	for ans in _live_answers():
		answers += " %d@%.0f" % [ans.value, ans.global_position.x]
	var plane_x := -1.0
	if _plane != null and is_instance_valid(_plane):
		plane_x = _plane.global_position.x
	print("POSE t=%.1f score=%d plane=%.0f view=%.0f ships[%s] answers[%s]" % [
		_battle_t, score, plane_x, view.x, ships, answers,
	])


func _save() -> void:
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var err := image.save_png(OUT_PATH)
	print("SHOT %s %dx%d err=%d" % [OUT_PATH, image.get_width(), image.get_height(), err])


func _press_shoot(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"shoot"
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_move() -> void:
	Input.action_release("ui_up")
	Input.action_release("ui_down")
