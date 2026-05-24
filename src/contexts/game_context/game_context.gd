extends IContext

@export var game_config: GameConfig
@export var levels_config: LevelsConfig

func initialize(_data: Dictionary) -> void:
	var extra_info = {}
	var scenario: GameConfig = _data.get('game_config')
	if not scenario:
		var container_id: String = _data.get("container_id", "")
		var level_id: int = _data.get("level_id", -1)
		extra_info['container_id'] = container_id
		extra_info['level_id'] = level_id
		scenario = levels_config.get_level_config(container_id, level_id)
		
	if scenario:
		_load_game_scenario(scenario)
		
	game_config.extra_info = extra_info
	
func _load_game_scenario(scenario: GameConfig):
	ResourceUtils.update_resource(game_config, scenario)
