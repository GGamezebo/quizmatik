extends IContext

@export var game_config: GameConfig

func initialize(_data: Dictionary) -> void:
	var scenario: GameConfig = _data.get('game_config')
	if scenario:
		ResourceUtils.update_resource(game_config, scenario)
