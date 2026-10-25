extends SceneTree

## Trailer take: battle scene alone + app-root music/SFX, a bot plays it (InputMap actions only).
## Run via `tools/trailer/record.py battle ...` (Movie Maker). Never loaded by the game.
## Env: TRAILER_SEED, TRAILER_LOCALE, TRAILER_VALLEY, TRAILER_PLANE, TRAILER_PAINT, TRAILER_TRAIL,
## TRAILER_SHOT, TRAILER_BATTLE (JSON: GameConfig property → value, merged over BATTLE_DEFAULTS).

const GAME_SCENE := "res://src/game/scenes/game/game.tscn"
## Short showcase battle: 3 questions → royal boss (2 plates, 3 rage shots) ≈ 28 s at seed 7.
const BATTLE_DEFAULTS := {
	"questions_count": 3,
	"allowed_operations": 5, # ADDITION | MULTIPLICATION
	"min_generate_number": 4,
	"max_generate_number": 9,
	"answer_speed": 200.0,
	"health": 3,
	"boss_chance": 1.0,
	"boss_armor": 2,
	"boss_rage_hits": 3,
	"boss_royal": true,
	"bonus_gold_chance": 1.0,
	"missing_operand_chance": 0.0,
	"time_limit_sec": 0.0,
}
## Seconds the take keeps rolling after the battle ends (win fly-off is already over).
const TAIL_SEC := 1.2

var game: Node
var plane: AirPlane
var root_events: RootEvents
var target_value: int = -999999
var spawned_at: float = 0.0
var t: float = 0.0
var frame_no: int = 0
var last_shot: float = -10.0
var tap_frames: int = 0
var done_at: float = -1.0
var react_delay: float = 0.35


func _initialize() -> void:
	seed(int(_env("TRAILER_SEED", "7")))
	if _env("TRAILER_LOCALE", "") != "":
		TranslationServer.set_locale(_env("TRAILER_LOCALE", ""))
	for i in AudioServer.bus_count:
		AudioServer.set_bus_mute(i, false)

	var cfg: GameConfig = load("res://src/game/scenes/game/game_config.tres")
	var overrides: Dictionary = BATTLE_DEFAULTS.duplicate()
	if _env("TRAILER_BATTLE", "") != "":
		overrides.merge(JSON.parse_string(_env("TRAILER_BATTLE", "")), true)
	for key in overrides:
		cfg.set(key, overrides[key])

	var events: GameEvents = load("res://src/game/scenes/game/game_events.tres")
	root_events = load("res://src/game/scenes/app_root/root_events.tres")
	events.ev_answers_spawned.connect(_on_answers_spawned)
	# GameState re-applies the equipped plane on entering states → re-apply the showcase look.
	events.ev_game_state_changed.connect(func(_a, _b): _apply_look.call_deferred())
	root_events.ev_exit_game.connect(func(_d = {}): done_at = t)

	var music_player := AudioStreamPlayer.new()
	music_player.bus = &"Music"
	music_player.volume_db = -7.69
	music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	root.add_child(music_player)
	var music: Node = load("res://src/features/music/music_controller.tscn").instantiate()
	music.music_player = music_player
	root.add_child(music)
	root.add_child(load("res://src/features/sfx/sfx_controller.tscn").instantiate())

	game = (load(GAME_SCENE) as PackedScene).instantiate()
	var bg := game.get_node("HUD/Background")
	var valley: Array[PackedScene] = [ValleyBackgroundArt.get_scene(_env("TRAILER_VALLEY", "multiplication"))]
	bg.variants = valley
	bg.pick_random = false
	bg.fixed_variant_index = 0
	root.add_child(game)
	current_scene = game
	root_events.ev_start_game.emit({})
	plane = game.get_node("Player/AirPlane") as AirPlane


func _env(key: String, fallback: String) -> String:
	var value := OS.get_environment(key)
	return value if value != "" else fallback


func _apply_look() -> void:
	var cat: CosmeticCatalog = load("res://src/common/cosmetics/cosmetic_catalog.tres")
	plane.apply_plane(_env("TRAILER_PLANE", "gold"))
	plane.apply_paint(cat.get_item(_env("TRAILER_PAINT", "paint_stars")) as PaintItem)
	plane.apply_trail(cat.get_item(_env("TRAILER_TRAIL", "trail_rainbow")) as TrailItem)
	game.get_node("Controllers/ShotManager").apply_style(cat.get_item(_env("TRAILER_SHOT", "shot_rainbow")) as ShotItem)


func _on_answers_spawned(_answers: Array, correct_value: int, _lanes: Array, _missing: bool) -> void:
	target_value = correct_value
	spawned_at = t
	react_delay = randf_range(0.12, 0.3)


func _process(delta: float) -> bool:
	t += delta
	frame_no += 1
	if frame_no == 3:
		_apply_look()
	if tap_frames > 0:
		tap_frames -= 1
		if tap_frames == 0:
			Input.action_release("shoot")
	if done_at >= 0.0 and t - done_at > TAIL_SEC:
		return true
	if plane == null or not is_instance_valid(plane) or not plane.is_processing():
		_release_move()
		return false

	var target := _find_target()
	if target == null:
		_release_move()
		return false

	var dy: float = target.global_position.y - plane.global_position.y
	if t - spawned_at < react_delay and not _is_boss(target):
		_release_move()
		return false
	if absf(dy) > 9.0:
		Input.action_press("ui_down" if dy > 0 else "ui_up")
		Input.action_release("ui_up" if dy > 0 else "ui_down")
	else:
		_release_move()
		var cadence := 0.25 if _is_boss(target) else 0.7
		if t - last_shot > cadence and target.global_position.x > plane.global_position.x + 150.0:
			if not (target is Answer) or (target as Answer).is_hittable():
				last_shot = t
				Input.action_press("shoot")
				tap_frames = 2
	return false


func _is_boss(n: Node2D) -> bool:
	return not (n is Answer)


## Angry boss hull first, then a bonus coin balloon, then the correct answer.
func _find_target() -> Node2D:
	for n in get_nodes_in_group("shot_targets"):
		var a := n as Area2D
		if a != null and not (a is Answer) and a.collision_layer != 0 and a.is_visible_in_tree():
			return a
	var best: Node2D = null
	for n in _all_answers(game):
		var ans := n as Answer
		if ans.is_queued_for_deletion() or not ans.visible or ans._is_dying:
			continue
		if ans.global_position.x < plane.global_position.x + 120.0:
			continue
		if ans is BonusBalloon:
			return ans
		if ans.value == target_value and not (ans is HeartBalloon):
			best = ans
	return best


func _all_answers(node: Node) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c is Answer:
			out.append(c)
		out.append_array(_all_answers(c))
	return out


func _release_move() -> void:
	Input.action_release("ui_up")
	Input.action_release("ui_down")
