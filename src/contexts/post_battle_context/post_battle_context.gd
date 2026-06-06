class_name PostBattleContext
extends IContext

@export_category('Major components')
@export var main_events: MainEvents
@export var title_label: Label
@export var score_label: Label
@export var stars_row: PostBattleStars
@export_group('Buttons')
@export var menu_button: Button
@export var repeat_button: Button

var _game_config: GameConfig


func _ready() -> void:
	repeat_button.grab_focus()

func initialize(data: Dictionary) -> void:
	if data.has("game_config"):
		_game_config = data["game_config"]

	var is_win: bool = data.get("is_win", false)
	var score: int = data.get("score", 0)
	var stars: int = data.get("stars", 0)
	var max_score: int = _game_config.questions_count if _game_config else 0
	_update_results(is_win, score, max_score, stars)

	menu_button.pressed.connect(_on_menu)
	repeat_button.pressed.connect(_on_repeat)

func deinit() -> void:
	menu_button.pressed.disconnect(_on_menu)
	repeat_button.pressed.disconnect(_on_repeat)
	_game_config = null

func _update_results(is_win: bool, score: int, max_score: int, stars: int) -> void:
	title_label.text = "Победа!" if is_win else "Поражение"
	var title_settings: LabelSettings = title_label.label_settings.duplicate()
	title_settings.font_color = Color(0.45, 1.0, 1.0, 1.0) if is_win else Color(1.0, 0.55, 0.55, 1.0)
	title_label.label_settings = title_settings

	if max_score > 0:
		score_label.text = "Правильных ответов: %d / %d" % [score, max_score]
	else:
		score_label.text = "Правильных ответов: %d" % score

	stars_row.show_stars(stars)

func _on_menu() -> void:
	main_events.ev_return_to_menu.emit()

func _on_repeat() -> void:
	if _game_config:
		var data: Dictionary
		if _game_config.battle_info:
			data = {"battle_info": _game_config.battle_info}
		else:
			data = {"custom_battle": _game_config}
		main_events.ev_start_game.emit(data)
	else:
		main_events.ev_return_to_menu.emit()
