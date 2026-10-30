extends SceneTree

## Trailer take: level grids → parents report → hall of fame → daily stamps.
## Sample profile lives only in memory. Run via `record.py boards`.

const LEVELS := "res://src/game/scenes/menu/levels/levels_selection.tscn"
const TROPHY := "res://src/game/scenes/menu/trophy_room_window/trophy_room_window.tscn"
const PARENTS := "res://src/game/scenes/menu/parents_window/parents_window.tscn"
const DAILY := "res://src/game/scenes/menu/daily/daily_challenges_panel.tscn"
const SKY := "res://src/ui/backgrounds/classic_sky/classic_sky_background.tscn"
const SFX := "res://src/features/sfx/sfx_controller.tscn"

const VALLEYS: Array[String] = ["addition", "subtraction", "multiplication", "division", "mix"]
const VALLEY_HOLD := 0.95
## Order is the if-chain below: valleys, then the parents report, then the hall, then daily stamps.
## These times match the cut in scenarios/ad_ru.json. Parents uses the mid-campaign profile;
## the hall is filled in only when the trophy page opens.
const PARENTS_AT := 4.77
const TROPHY_AT := 10.15
const DAILY_AT := 14.35
const END_AT := 17.90

var pdata: PData
var _page: Node
var _t := 0.0
var _valley := 0
var _trophy_on := false
var _parents_on := false
var _daily_on := false


func _initialize() -> void:
	if OS.get_environment("TRAILER_LOCALE") != "":
		TranslationServer.set_locale(OS.get_environment("TRAILER_LOCALE"))
	for i in AudioServer.bus_count:
		AudioServer.set_bus_mute(i, false)
	if OS.get_environment("TRAILER_MUTE_MUSIC") == "1":
		var music_bus := AudioServer.get_bus_index("Music")
		if music_bus >= 0:
			AudioServer.set_bus_mute(music_bus, true)
	root.add_child((load(SFX) as PackedScene).instantiate())
	pdata = load("res://src/game/account/persistent_data.tres")
	_fill_journey(pdata)
	_show_levels(0)
	print("TRAILER BOARDS valleys 0-%.2f parents %.2f trophy %.2f daily %.2f end %.2f" % [
		PARENTS_AT, PARENTS_AT, TROPHY_AT, DAILY_AT, END_AT])


func _process(delta: float) -> bool:
	_t += delta
	if not _parents_on and _t >= PARENTS_AT:
		_parents_on = true
		var win := (load(PARENTS) as PackedScene).instantiate()
		_swap(win)
		win.get_node("ParentalGate").visible = false
		win.get_node("Content/Card/BottomButtons").visible = false
		_hide_named(win, "MenuWindowBack")
		win.get_node("Content").show()
		win.call("_rebuild")
		print("TRAILER %.2f parents" % _t)
	elif not _trophy_on and _t >= TROPHY_AT:
		_trophy_on = true
		_complete_for_hall(pdata)
		var hall := (load(TROPHY) as PackedScene).instantiate()
		_swap(hall)
		hall.call("on_window_enter")
		_hide_named(hall, "MenuWindowBack")
		print("TRAILER %.2f trophy" % _t)
	elif not _daily_on and _t >= DAILY_AT:
		_daily_on = true
		_show_daily()
		print("TRAILER %.2f daily" % _t)
	elif not _parents_on and _valley < VALLEYS.size() - 1 and _t >= float(_valley + 1) * VALLEY_HOLD:
		_valley += 1
		_page.call("initialize", VALLEYS[_valley])
		print("TRAILER %.2f valley %s" % [_t, VALLEYS[_valley]])
	return _t >= END_AT


func _show_levels(index: int) -> void:
	_valley = index
	var levels := (load(LEVELS) as PackedScene).instantiate()
	_swap(levels)
	levels.call("initialize", VALLEYS[index])
	_hide_named(levels, "MenuWindowBack")
	print("TRAILER %.2f valley %s" % [_t, VALLEYS[index]])


func _show_daily() -> void:
	pdata.daily.utc_day = PData.utc_day_key()
	pdata.daily.slots = PData.DailyData.empty_slots()
	for i in 4:
		pdata.daily.slots[i] = true
	pdata.daily.streak_days = 6
	pdata.daily.cycle_sets = 1
	DailyChallengesPanel._seen_completed = 0
	_drop_page()
	var sky := (load(SKY) as PackedScene).instantiate()
	root.add_child(sky)
	_page = sky
	var layer := CanvasLayer.new()
	layer.layer = 5
	root.add_child(layer)
	var panel := (load(DAILY) as PackedScene).instantiate() as Control
	panel.scale = Vector2(1.58, 1.58)
	panel.position = (Vector2(1280, 720) - Vector2(660, 265) * 1.58) * 0.5
	layer.add_child(panel)


func _swap(node: Node) -> void:
	_drop_page()
	root.add_child(node)
	current_scene = node
	_page = node


func _drop_page() -> void:
	if _page == null:
		return
	if _page.get_parent() == root:
		root.remove_child(_page)
	_page.queue_free()
	_page = null


func _hide_named(node: Node, node_name: String) -> void:
	var found := node.find_child(node_name, true, false)
	if found != null:
		found.visible = false


func _fill_journey(pd: PData) -> void:
	pd.reset_to_defaults()
	pd.display_name = "Mia" if TranslationServer.get_locale().begins_with("en") else "Мия"
	pd.difficulty = BattleDifficulty.NORMAL
	pd.state.tutorial_completed = true
	pd.statistics.total_answers = 858
	pd.statistics.facts_correct = 740
	pd.statistics.facts_wrong = 118
	pd.statistics.battle_total_time = 4.0 * 3600.0 + 20.0 * 60.0
	pd.statistics.total_time = pd.statistics.battle_total_time
	pd.statistics.total_wins = 96
	pd.statistics.total_battles = 110
	pd.statistics.game_sessions = 48
	pd.statistics.total_shoot_count = 2400
	pd.statistics.total_stars = 219
	pd.statistics.endless_best_sec = 412
	_stars(pd, "addition", 20, true)
	_stars(pd, "subtraction", 20, true)
	_stars(pd, "multiplication", 20, true)
	_stars(pd, "division", 10, false)
	_stars(pd, "mix", 4, false)
	_mistakes(pd)


func _complete_for_hall(pd: PData) -> void:
	for valley_id in VALLEYS:
		_stars(pd, valley_id, 20, true)
	pd.trophies.unlock(ProgressController.MAGISTER_TROPHY)
	pd.statistics.total_stars = 300
	pd.statistics.endless_best_sec = 412


func _stars(pd: PData, valley_id: String, up_to: int, exam_passed: bool) -> void:
	var container := pd.levels.ensure_container(valley_id)
	container.unlocked = true
	container.exam_passed = exam_passed
	for level_id in range(1, up_to + 1):
		container.ensure_level(level_id).stars = 3


func _mistakes(pd: PData) -> void:
	var sample := {"mul:7:8": 6, "mul:6:7": 5, "add:8:7": 4, "mul:9:6": 3}
	for key in sample:
		pd.mistakes.misses[key] = sample[key]
		pd.mistakes.weights[key] = mini(int(sample[key]), MistakesController.MAX_WEIGHT)
