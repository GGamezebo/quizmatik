extends CanvasLayer

@export var root_events: RootEvents
@export var player: Player
@export var restart_button: BaseButton
@export var exit_button: BaseButton

var _game_config: GameConfig


func initialize(game_config: GameConfig) -> void:
	_game_config = game_config


func _ready() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)


func _on_restart_pressed() -> void:
	if _game_config == null:
		return
	var data: Dictionary
	if _game_config.battle_info:
		data = {"battle_info": _game_config.battle_info}
	else:
		data = {"custom_battle": _game_config}
	root_events.ev_start_game.emit(data)


func _on_exit_pressed() -> void:
	root_events.ev_exit_game.emit(
		PostBattleScene.build_result_data(_game_config, player, false)
	)
