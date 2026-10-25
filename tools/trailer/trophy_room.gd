extends SceneTree

## Trailer take: trophy room with a sample pupil profile (in memory only — no SaveManager, user saves
## untouched), then a hint finger taps «Трудные примеры» and the list opens.
## Run via `tools/trailer/record.py trophy ...`. Env: TRAILER_LOCALE, TRAILER_TAP_AT (3.2), TRAILER_END_AT (9.5).

const WINDOW := "res://src/game/scenes/menu/trophy_room_window/trophy_room_window.tscn"
const FINGER_IN_AT := 1.6
## Mistakes shown in the list: `MathFact` key → misses.
const SAMPLE_MISTAKES := {
	"mul:7:8": 6, "mul:6:7": 5, "add:7:8": 4, "mul:6:9": 4,
	"add:6:9": 3, "mul:4:8": 3, "add:5:7": 2, "mul:3:9": 2,
}

## Held for the whole take: an unreferenced `.tres` drops out of the cache and the window would load a fresh copy.
var pdata: PData
var win: Control
var finger: TextureRect
var t: float = 0.0
var tap_at: float = 3.2
var end_at: float = 9.5
var tapped := false


func _initialize() -> void:
	if OS.get_environment("TRAILER_LOCALE") != "":
		TranslationServer.set_locale(OS.get_environment("TRAILER_LOCALE"))
	if OS.get_environment("TRAILER_TAP_AT") != "":
		tap_at = float(OS.get_environment("TRAILER_TAP_AT"))
	if OS.get_environment("TRAILER_END_AT") != "":
		end_at = float(OS.get_environment("TRAILER_END_AT"))
	pdata = load("res://src/game/account/persistent_data.tres")
	_fill_sample_profile(pdata)

	win = (load(WINDOW) as PackedScene).instantiate()
	root.add_child(win)
	current_scene = win
	win.on_window_enter()

	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	finger = TextureRect.new()
	finger.texture = load("res://assets/ui/icons/hint_finger.svg")
	finger.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	finger.size = Vector2(72, 72)
	finger.position = Vector2(-300, -300)
	finger.modulate.a = 0.0
	layer.add_child(finger)


## 4 valley exams passed (endless record scroll open), mix in progress, stats, weak examples.
func _fill_sample_profile(pd: PData) -> void:
	pd.reset_to_defaults()
	pd.display_name = "Mia"
	for id in ["addition", "subtraction", "multiplication", "division"]:
		var c := pd.levels.ensure_container(id)
		c.unlocked = true
		c.exam_passed = true
		for lvl in range(1, 21):
			c.ensure_level(lvl).stars = 3 if lvl % 4 else 2
	var mix := pd.levels.ensure_container("mix")
	mix.unlocked = true
	for lvl in range(1, 7):
		mix.ensure_level(lvl).stars = 3
	var s := pd.statistics
	s.total_wins = 74
	s.total_battles = 81
	s.total_answers = 1236
	s.total_stars = 214
	s.total_shoot_count = 1580
	s.total_time = 6.4 * 3600.0
	s.game_sessions = 37
	s.endless_best_sec = 412
	for key in SAMPLE_MISTAKES:
		pd.mistakes.misses[key] = SAMPLE_MISTAKES[key]
		pd.mistakes.weights[key] = mini(SAMPLE_MISTAKES[key], MistakesController.MAX_WEIGHT)


func _process(delta: float) -> bool:
	t += delta
	var btn: Control = win.hard_facts_button
	var target: Vector2 = btn.get_global_rect().get_center() + Vector2(-20, -10)
	if t > FINGER_IN_AT and t < tap_at:
		finger.modulate.a = minf(1.0, (t - FINGER_IN_AT) / 0.3)
		var k := clampf((t - FINGER_IN_AT) / (tap_at - FINGER_IN_AT - 0.25), 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		finger.position = (target + Vector2(260, 160)).lerp(target, k)
	elif t >= tap_at and not tapped:
		tapped = true
		finger.scale = Vector2(0.85, 0.85)
		btn.pressed.emit()
	elif tapped:
		finger.scale = Vector2.ONE
		finger.modulate.a = maxf(0.0, finger.modulate.a - delta * 4.0)
	return t > end_at
