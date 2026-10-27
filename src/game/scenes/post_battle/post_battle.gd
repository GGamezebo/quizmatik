class_name PostBattleScene
extends IScene

@export_category("Major components")
@export var root_events: RootEvents
@export var progress: ProgressController
@export var title_label: Label
@export var score_label: Label
## Holds the gold lines; hidden when none shows so the card keeps its spacing.
@export var gold_lines: Control
## Gold lines = `CoinIcon` + label rows.
@export var level_gold_row: Control
@export var gold_label: Label
@export var bonus_gold_row: Control
@export var bonus_gold_label: Label
@export var stamps: Array[TextureRect] = []
## Endless battle: stamps make way for the clock row (time survived + record).
@export var stamps_row: Control
@export var endless_row: Control
@export var endless_record_label: Label
## Record battles: when the next coin comes (next whole minute of the record).
@export var endless_next_coin_label: Label
@export var stamp_textures: Array[Texture2D] = []
@export var stamp_empty: Texture2D
@export_group("Buttons")
@export var next_level_button: BaseButton
@export var menu_button: BaseButton
@export var repeat_button: BaseButton
@export var exam_victory_dialog: ExamVictoryDialog
@export var background_host: BackgroundHost
## Monetization hooks (default board = no offers, nothing paywalled).
@export var offer_board: OfferBoard
@export var rewarded_gold_button: RewardedGoldButton
@export var _game_config: GameConfig
@export_group("Endless texts")
@export var endless_record_title: String = "НОВЫЙ РЕКОРД!"
@export var endless_title: String = "ПОЛЁТ ОКОНЧЕН"
@export var endless_time_format: String = "Время: %s"
@export var endless_record_format: String = "Рекорд: %s"
@export var endless_previous_format: String = "Прежний рекорд: %s"
@export var endless_first_text: String = "Первый рекорд!"
@export var endless_next_coin_format: String = "Следующая монетка: %s"
@export_group("Golden flight texts")
@export var golden_title: String = "ЗОЛОТОЙ ПОЛЁТ!"
@export_group("Magister texts")
@export var magister_title: String = "ТЫ — МАГИСТР!"
@export_group("Expert texts")
@export var expert_title: String = "ТЫ — ЭКСПЕРТ!"

var _next_battle_info: GameConfig.BattleInfo = null
## The magister / expert coin row is for the expert award.
var _expert_gold_line: bool = false
var _pending_auto_container: String = ""
## `RootEvents.ev_post_battle_exit_home`: the menu button skips the valley grid.
var _exit_home: bool = false
var _listener: EventListener = EventListener.new()


static func build_result_data(
	game_config: GameConfig,
	player: Player,
	is_win: bool,
	stars_count: int = 0,
) -> Dictionary:
	var data := {
		"game_config": game_config,
		"score": player.score,
		"max_score": 0 if game_config.is_timed() or game_config.endless else game_config.questions_count,
		"is_win": is_win,
		"stars": stars_count,
		"bonus_gold": 0 if game_config.golden_flight else player.bonus_gold,
	}
	if game_config.golden_flight:
		# Caught coin balloons + the final pick, kept on any exit.
		data["golden_gold"] = player.bonus_gold
	if game_config.magister:
		data["magister"] = true
	if not game_config.expert_valley_id.is_empty():
		data["expert_valley_id"] = game_config.expert_valley_id
	if game_config.endless:
		data["endless_sec"] = player.survived_sec
		data["endless_best_before"] = game_config.endless_best_sec
		data["is_record"] = player.survived_sec > game_config.endless_best_sec
		data["endless_valley_id"] = game_config.endless_valley_id
	return data


func initialize(data: Dictionary) -> void:
	if data.has("game_config"):
		_game_config = data["game_config"]
	_apply_valley_background()

	var is_win: bool = data.get("is_win", false)
	var score: int = data.get("score", 0)
	var stars_count: int = data.get("stars", 0)
	var max_score: int = data.get("max_score", _game_config.questions_count if _game_config else 0)
	_update_results(is_win, score, max_score, stars_count)
	_show_endless(data)
	var record_gold: int = int(data.get("record_gold", 0))
	var golden_gold: int = int(data.get("golden_gold", 0))
	# Magister and expert gold share the row (one kind per battle).
	var magister_gold: int = int(data.get("magister_gold", 0))
	var expert_gold: int = int(data.get("expert_gold", 0))
	_expert_gold_line = expert_gold > 0
	var exam_gold: int = int(data.get("exam_gold", 0))
	_show_level_gold(int(data.get("level_gold", 0)), record_gold, golden_gold, magister_gold + expert_gold,
			exam_gold, bool(data.get("plane_refund", false)), bool(data.get("skipped_levels", false)))
	_show_bonus_gold(int(data.get("bonus_gold", 0)))
	var earned_gold: int = int(data.get("level_gold", 0)) + int(data.get("bonus_gold", 0)) + record_gold + golden_gold 			+ magister_gold + expert_gold + exam_gold
	if gold_lines:
		gold_lines.visible = earned_gold > 0
	if rewarded_gold_button:
		rewarded_gold_button.setup(earned_gold)
	_setup_next_level_button(is_win)
	# Daily bonus battle is once a day: no «repeat».
	if _game_config != null and _game_config.golden_flight:
		# Once a day: no «repeat»; hearts/stamps mean nothing there.
		repeat_button.visible = false
		call_deferred("_grab_button_focus", menu_button)
		title_label.text = golden_title
		if stamps_row:
			stamps_row.visible = false
	if _game_config != null and _game_config.magister:
		if is_win:
			title_label.text = magister_title
		if stamps_row:
			stamps_row.visible = false
	if _game_config != null and not _game_config.expert_valley_id.is_empty():
		if is_win:
			title_label.text = expert_title
		if stamps_row:
			stamps_row.visible = false

	_listener.add(menu_button.pressed, _on_menu)
	_listener.add(repeat_button.pressed, _on_repeat)
	_listener.add(next_level_button.pressed, _on_next_level)
	if root_events != null:
		_listener.add(root_events.ev_post_battle_exit_home, _on_exit_home)

	var celebration: Dictionary = data.get("exam_celebration", {})
	if is_win and not celebration.is_empty() and celebration.get("first_exam_pass", false):
		_pending_auto_container = _resolve_auto_level_select_container(is_win)
		call_deferred("_show_exam_victory", celebration)
	else:
		if root_events != null:
			root_events.ev_celebration_unhold.emit()
		var auto_container_id: String = _resolve_auto_level_select_container(is_win)
		if not auto_container_id.is_empty():
			call_deferred("_return_to_level_select", auto_container_id)


func deinit() -> void:
	if root_events != null:
		root_events.ev_celebration_unhold.emit()
	_listener.deinit()
	_game_config = null
	_expert_gold_line = false
	_next_battle_info = null
	_pending_auto_container = ""
	_exit_home = false


func _apply_valley_background() -> void:
	if background_host == null:
		return
	var valley_id: String = _valley_id()
	var packed: PackedScene = null
	if not valley_id.is_empty():
		packed = ValleyBackgroundArt.get_scene(valley_id)
	else:
		packed = ValleyBackgroundArt.pick_random_scene()
	background_host.force_variant(packed)


## Valley of this battle: campaign level, valley record battle or expert trial; "" = training / menu modes.
func _valley_id() -> String:
	if _game_config == null:
		return ""
	if _game_config.battle_info != null:
		return _game_config.battle_info.container_id
	if not _game_config.expert_valley_id.is_empty():
		return _game_config.expert_valley_id
	return _game_config.endless_valley_id


func _update_results(is_win: bool, score: int, max_score: int, stars_count: int) -> void:
	title_label.text = "ПОБЕДНЫЙ ПОЛЁТ!" if is_win else "ПОСАДКА..."
	var title_settings: LabelSettings = title_label.label_settings.duplicate()
	title_settings.font_color = Color(0.22, 0.44, 0.28, 1.0) if is_win else Color(0.70, 0.28, 0.26, 1.0)
	title_label.label_settings = title_settings

	if max_score > 0:
		score_label.text = "%d / %d" % [score, max_score]
	else:
		score_label.text = str(score)

	_show_stamps(stars_count)


## Endless: «m:ss» survived instead of the score; record line under the clock.
func _show_endless(data: Dictionary) -> void:
	var endless: bool = data.has("endless_sec")
	if stamps_row:
		stamps_row.visible = not endless
	if endless_row:
		endless_row.visible = endless
	if not endless:
		return
	var seconds: int = int(data["endless_sec"])
	var best_before: int = int(data.get("endless_best_before", 0))
	var is_record: bool = bool(data.get("is_record", false))
	title_label.text = endless_record_title if is_record else endless_title
	var title_settings: LabelSettings = title_label.label_settings.duplicate()
	title_settings.font_color = Color(0.22, 0.44, 0.28, 1.0) if is_record else Color(0.22, 0.25, 0.3, 1.0)
	title_label.label_settings = title_settings
	score_label.text = tr(endless_time_format) % ProgressStatistics.format_clock(seconds)
	if not is_record:
		endless_record_label.text = tr(endless_record_format) % ProgressStatistics.format_clock(best_before)
	elif best_before > 0:
		endless_record_label.text = tr(endless_previous_format) % ProgressStatistics.format_clock(best_before)
	else:
		endless_record_label.text = endless_first_text
	if endless_next_coin_label:
		var next_coin: int = ProgressStatistics.next_record_coin_sec(maxi(seconds, best_before))
		endless_next_coin_label.text = tr(endless_next_coin_format) % ProgressStatistics.format_clock(next_coin)


func _show_stamps(count: int) -> void:
	var rotations: Array[float] = [-0.12, 0.08, -0.06]
	for index in range(stamps.size()):
		var stamp: TextureRect = stamps[index]
		var is_filled: bool = index < count
		stamp.visible = true
		stamp.pivot_offset = stamp.size * 0.5
		if stamp.size == Vector2.ZERO:
			stamp.pivot_offset = Vector2(48, 48)
		stamp.rotation = rotations[index % rotations.size()] if is_filled else 0.0
		stamp.modulate = Color(1, 1, 1, 0.92) if is_filled else Color(1, 1, 1, 0.55)
		if is_filled and index < stamp_textures.size() and stamp_textures[index] != null:
			stamp.texture = stamp_textures[index]
		else:
			stamp.texture = stamp_empty


## Same coin row: level «3 stamps» gold, endless record, golden-flight, magister or first exam pass gold
## (one kind per battle; exam gold includes the refund for an exam plane bought earlier).
func _show_level_gold(amount: int, record_amount: int = 0, golden_amount: int = 0, magister_amount: int = 0,
		exam_amount: int = 0, plane_refund: bool = false, skipped_levels: bool = false) -> void:
	if gold_label == null:
		return
	if level_gold_row:
		level_gold_row.visible = amount > 0 or record_amount > 0 or golden_amount > 0 or magister_amount > 0 \
				or exam_amount > 0
	if exam_amount > 0 and skipped_levels:
		gold_label.text = tr("+%d за экзамен и пропущенные уровни") % exam_amount
	elif exam_amount > 0:
		gold_label.text = tr("+%d за экзамен и купленный самолёт" if plane_refund else "+%d за экзамен") % exam_amount
	elif magister_amount > 0:
		gold_label.text = tr("+%d за звание эксперта" if _expert_gold_line else "+%d за звание магистра") % magister_amount
	elif golden_amount > 0:
		gold_label.text = tr("+%d за золотой полёт") % golden_amount
	elif record_amount > 0:
		gold_label.text = tr("+%d за рекорд") % record_amount
	elif amount > 0:
		gold_label.text = tr("+%d за 3 штампа") % amount


func _show_bonus_gold(amount: int) -> void:
	if bonus_gold_label == null:
		return
	if bonus_gold_row:
		bonus_gold_row.visible = amount > 0
	if amount > 0:
		bonus_gold_label.text = tr("+%d из бонусного шарика") % amount


func _setup_next_level_button(is_win: bool) -> void:
	_next_battle_info = _resolve_next_battle_info(is_win)
	var show_next: bool = _next_battle_info != null
	next_level_button.visible = show_next
	if show_next:
		call_deferred("_grab_button_focus", next_level_button)
	else:
		call_deferred("_grab_button_focus", repeat_button)


func _grab_button_focus(button: BaseButton) -> void:
	if button == null or not button.visible:
		return
	button.focus_mode = Control.FOCUS_ALL
	button.grab_focus()


func _resolve_next_battle_info(is_win: bool) -> GameConfig.BattleInfo:
	if not is_win:
		return null
	var battle_info: GameConfig.BattleInfo = _game_config.battle_info
	if battle_info == null:
		return null

	var next_level_id: int = battle_info.level_id + 1
	if not progress.levels_config.has_level(battle_info.container_id, next_level_id):
		return null
	if progress.get_level_stars(battle_info.container_id, next_level_id) > 0:
		return null

	var is_exam: bool = progress.levels_config.is_level_exam(
		battle_info.container_id,
		next_level_id,
	)
	return GameConfig.BattleInfo.new(battle_info.container_id, next_level_id, is_exam)


## Back to the valley's level grid (campaign level or its record clock); "" = main menu.
func _resolve_menu_level_select_container() -> String:
	return _valley_id()


func _resolve_auto_level_select_container(is_win: bool) -> String:
	if not is_win:
		return ""
	var battle_info: GameConfig.BattleInfo = _game_config.battle_info
	if battle_info == null or not battle_info.is_exam:
		return ""

	var next_container_id: String = progress.levels_config.get_next_container_id(battle_info.container_id)
	if next_container_id.is_empty():
		return ""
	if not progress.is_container_unlocked(next_container_id):
		return ""
	if offer_board != null and offer_board.is_container_paywalled(next_container_id, StringName(progress.pdata.difficulty)):
		return ""
	if progress.get_level_stars(next_container_id, 1) > 0:
		return ""
	return next_container_id


func _return_to_level_select(container_id: String) -> void:
	root_events.ev_return_to_menu.emit({"open_level_select": container_id})


func _show_exam_victory(celebration: Dictionary) -> void:
	if exam_victory_dialog == null:
		if root_events != null:
			root_events.ev_celebration_unhold.emit()
		if not _pending_auto_container.is_empty():
			_return_to_level_select(_pending_auto_container)
		_pending_auto_container = ""
		return
	exam_victory_dialog.open(celebration)
	exam_victory_dialog.ev_confirmed.connect(_on_exam_victory_confirmed, CONNECT_ONE_SHOT)


func _on_exam_victory_confirmed() -> void:
	if root_events != null:
		root_events.ev_celebration_unhold.emit()
	var container_id := _pending_auto_container
	_pending_auto_container = ""
	if not container_id.is_empty():
		_return_to_level_select(container_id)


func _on_exit_home(is_on: bool) -> void:
	_exit_home = is_on


func _on_menu() -> void:
	var container_id: String = "" if _exit_home else _resolve_menu_level_select_container()
	if container_id.is_empty():
		root_events.ev_return_to_menu.emit({})
	else:
		_return_to_level_select(container_id)


func _on_repeat() -> void:
	if _game_config:
		var data: Dictionary
		if _game_config.battle_info:
			data = {"battle_info": _game_config.battle_info}
		else:
			data = {"custom_battle": _game_config}
		root_events.ev_start_game.emit(data)
	else:
		root_events.ev_return_to_menu.emit({})


func _on_next_level() -> void:
	if _next_battle_info == null:
		return
	root_events.ev_start_game.emit({"battle_info": _next_battle_info})
