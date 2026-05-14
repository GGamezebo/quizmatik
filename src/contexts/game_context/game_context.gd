extends IContext

@export var game_config: GameConfig

func initialize(_data: Dictionary) -> void:
	var scenario: GameConfig = _data.get('game_config')
	if scenario:
		game_config = scenario
