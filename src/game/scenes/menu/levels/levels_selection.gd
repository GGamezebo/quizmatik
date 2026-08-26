extends Control

@export var root_events: RootEvents
@export var grid_container: GridContainer
@export var level_button: PackedScene
@export var levels: LevelsConfig
@export var container_id: String
@export var progress: ProgressController
@export var back_button: BaseButton
@export var early_exam_dialog: ConfirmDialog
@export var exam_info_panel: PanelContainer
@export var difficulty_label: Label
@export var difficulty_bars: Array[ColorRect] = []

var _pending_battle_info: GameConfig.BattleInfo = null

const BAR_OFF := Color(0.78, 0.74, 0.70, 1.0)
const BAR_ON := Color(0.55, 0.42, 0.72, 1.0)


func initialize(_container_id: String) -> void:
	container_id = _container_id
	_populate_levels_grid()
	_refresh_exam_info()


func _ready() -> void:
	early_exam_dialog.ev_confirmed.connect(_on_early_exam_confirmed)
	early_exam_dialog.ev_canceled.connect(_on_early_exam_canceled)
	_style_exam_info_panel()
	if container_id:
		_refresh_exam_info()


func _style_exam_info_panel() -> void:
	if exam_info_panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.992, 0.984, 0.957, 0.94)
	style.border_color = Color(0.165, 0.2, 0.251, 0.12)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0.15, 0.12, 0.08, 0.14)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	exam_info_panel.add_theme_stylebox_override("panel", style)

	var badge := exam_info_panel.find_child("InfoBadge", true, false) as Panel
	if badge:
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.55, 0.42, 0.72, 1.0)
		badge_style.set_corner_radius_all(14)
		badge.add_theme_stylebox_override("panel", badge_style)


func _populate_levels_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var container = levels.find_container_in_config(container_id)
	var next_id := _find_next_level_id(container)

	for level in container["levels"]:
		var lvl_id: int = level["level_id"]
		var is_exam: bool = level.get("is_exam", false)
		var btn = level_button.instantiate()
		btn.initialize(lvl_id, false, 0, is_exam)
		grid_container.add_child(btn)

		var is_unlocked: bool = progress.is_level_unlocked(container_id, lvl_id)
		var stars: int = progress.get_level_stars(container_id, lvl_id)
		btn.set_params(is_unlocked, stars)
		if btn.has_method("set_as_next"):
			btn.set_as_next(lvl_id == next_id and not is_exam)
		if is_unlocked or is_exam:
			if is_unlocked:
				progress.mark_level_seen(container_id, lvl_id)
			var battle_info = GameConfig.BattleInfo.new(container_id, lvl_id, is_exam)
			btn.pressed.connect(_on_level_selected.bind(battle_info))

	_refresh_exam_info()


func _refresh_exam_info() -> void:
	if progress == null or container_id.is_empty():
		return
	var all_done := progress.are_all_regular_levels_completed(container_id)
	# Bars 1..5; base = 2, raised = 5 (matches reference “Высокая”).
	var level := 2 if all_done else 5
	if difficulty_label:
		difficulty_label.text = "Базовая" if all_done else "Высокая"
	for i in difficulty_bars.size():
		difficulty_bars[i].color = BAR_ON if i < level else BAR_OFF


func _find_next_level_id(container: Dictionary) -> int:
	if container.is_empty():
		return -1
	for level in container["levels"]:
		if level.get("is_exam", false):
			continue
		var lvl_id: int = level["level_id"]
		if progress.is_level_unlocked(container_id, lvl_id) and progress.get_level_stars(container_id, lvl_id) < 1:
			return lvl_id
	for level in container["levels"]:
		if level.get("is_exam", false):
			return int(level["level_id"])
	return -1


func _on_level_selected(battle_info: GameConfig.BattleInfo) -> void:
	if battle_info.is_exam and not progress.are_all_regular_levels_completed(battle_info.container_id):
		_pending_battle_info = battle_info
		early_exam_dialog.open(
			"Усложнённый экзамен",
			"Вы не прошли все уровни в этом блоке. Экзамен будет усложнённым.",
			"Начать",
			"Отмена",
		)
		return
	_start_game(battle_info)


func _on_early_exam_confirmed() -> void:
	if _pending_battle_info == null:
		return
	var battle_info := GameConfig.BattleInfo.new(
		_pending_battle_info.container_id,
		_pending_battle_info.level_id,
		true,
		true,
	)
	_pending_battle_info = null
	_start_game(battle_info)


func _on_early_exam_canceled() -> void:
	_pending_battle_info = null


func _start_game(battle_info: GameConfig.BattleInfo) -> void:
	root_events.ev_start_game.emit({
		"battle_info": battle_info
	})
