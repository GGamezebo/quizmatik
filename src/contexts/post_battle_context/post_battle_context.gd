class_name PostBattleContext
extends IContext

@export_category('Major components')
@export var main_events: MainEvents
@export var score_label: Label
@export_group('Buttons')
@export var menu_button: Button
@export var repeat_button: Button

var _game_config: GameConfig

func initialize(data: Dictionary) -> void:
	if data.has("game_config"):
		_game_config = data["game_config"]
	
	if data.has("score"):
		var max_score: int = _game_config.questions_count
		score_label.text = "Результаты: %d / %d" % [data["score"], max_score]
	else:
		score_label.text = "Результаты"

func _ready() -> void:
	repeat_button.grab_focus()
	
	menu_button.pressed.connect(_on_menu)
	repeat_button.pressed.connect(_on_repeat)

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
