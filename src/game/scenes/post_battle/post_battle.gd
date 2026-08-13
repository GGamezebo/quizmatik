class_name PostBattleScene
extends IScene

@export_category("Major components")
@export var root_events: RootEvents
@export var progress: ProgressController
@export var title_label: Label
@export var score_label: Label
@export var stamps: Array[TextureRect] = []
@export var stamp_textures: Array[Texture2D] = []
@export var stamp_empty: Texture2D
@export_group("Buttons")
@export var next_level_button: BaseButton
@export var menu_button: BaseButton
@export var repeat_button: BaseButton
@export var _game_config: GameConfig

var _next_battle_info: GameConfig.BattleInfo = null
var _listener: EventListener = EventListener.new()


static func build_result_data(
	game_config: GameConfig,
	player: Player,
	is_win: bool,
	stars_count: int = 0,
) -> Dictionary:
	return {
		"game_config": game_config,
		"score": player.score,
		"max_score": game_config.questions_count,
		"is_win": is_win,
		"stars": stars_count,
	}


func initialize(data: Dictionary) -> void:
	if data.has("game_config"):
		_game_config = data["game_config"]

	var is_win: bool = data.get("is_win", false)
	var score: int = data.get("score", 0)
	var stars_count: int = data.get("stars", 0)
	var max_score: int = data.get("max_score", _game_config.questions_count if _game_config else 0)
	_update_results(is_win, score, max_score, stars_count)
	_setup_next_level_button(is_win)

	_listener.add(menu_button.pressed, _on_menu)
	_listener.add(repeat_button.pressed, _on_repeat)
	_listener.add(next_level_button.pressed, _on_next_level)

	var auto_container_id: String = _resolve_auto_level_select_container(is_win)
	if not auto_container_id.is_empty():
		call_deferred("_return_to_level_select", auto_container_id)


func deinit() -> void:
	_listener.deinit()
	_game_config = null
	_next_battle_info = null


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


func _resolve_menu_level_select_container() -> String:
	if _game_config == null or _game_config.battle_info == null:
		return ""
	return _game_config.battle_info.container_id


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
	if progress.get_level_stars(next_container_id, 1) > 0:
		return ""
	return next_container_id


func _return_to_level_select(container_id: String) -> void:
	root_events.ev_return_to_menu.emit({"open_level_select": container_id})


func _on_menu() -> void:
	var container_id: String = _resolve_menu_level_select_container()
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
