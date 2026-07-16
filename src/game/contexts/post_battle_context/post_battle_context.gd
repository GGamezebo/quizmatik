class_name PostBattleContext
extends IContext

const STAR_FILLED_COLOR := Color(1.0, 0.84, 0.2, 1.0)
const STAR_EMPTY_COLOR := Color(0.35, 0.42, 0.55, 0.45)

@export_category('Major components')
@export var main_events: MainEvents
@export var title_label: Label
@export var score_label: Label
@export var stars: Array[TextureRect] = []
@export_group('Buttons')
@export var menu_button: Button
@export var repeat_button: Button

var _game_config: GameConfig


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


func _ready() -> void:
	repeat_button.grab_focus()

func initialize(data: Dictionary) -> void:
	if data.has("game_config"):
		_game_config = data["game_config"]

	var is_win: bool = data.get("is_win", false)
	var score: int = data.get("score", 0)
	var stars_count: int = data.get("stars", 0)
	var max_score: int = data.get("max_score", _game_config.questions_count if _game_config else 0)
	_update_results(is_win, score, max_score, stars_count)

	menu_button.pressed.connect(_on_menu)
	repeat_button.pressed.connect(_on_repeat)

func deinit() -> void:
	menu_button.pressed.disconnect(_on_menu)
	repeat_button.pressed.disconnect(_on_repeat)
	_game_config = null

func _update_results(is_win: bool, score: int, max_score: int, stars_count: int) -> void:
	title_label.text = "ПОБЕДНЫЙ ПОЛЁТ!" if is_win else "ПОСАДКА..."
	var title_settings: LabelSettings = title_label.label_settings.duplicate()
	title_settings.font_color = Color(0.45, 1.0, 1.0, 1.0) if is_win else Color(1.0, 0.55, 0.55, 1.0)
	title_label.label_settings = title_settings

	if max_score > 0:
		score_label.text = "Правильных ответов: %d / %d" % [score, max_score]
	else:
		score_label.text = "Правильных ответов: %d" % score

	_show_stars(stars_count)

func _show_stars(count: int) -> void:
	for index in range(stars.size()):
		var star: TextureRect = stars[index]
		var is_filled: bool = index < count
		star.visible = true
		star.scale = Vector2.ONE
		star.modulate = STAR_FILLED_COLOR if is_filled else STAR_EMPTY_COLOR

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
