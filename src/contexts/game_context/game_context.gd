extends IContext

@export var game_config: GameConfig
@export var levels_config: LevelsConfig

func initialize(_data: Dictionary) -> void:
	var scenario: GameConfig = _data.get('custom_battle')
	var battle_info: GameConfig.BattleInfo = _data.get('battle_info')
	assert(not scenario or not battle_info, 'Incorrect battle config')
	
	if battle_info:
		scenario = levels_config.get_level_config(battle_info.container_id, battle_info.level_id)
		if scenario:
			scenario = scenario.duplicate(true)
			if battle_info.is_early_exam:
				scenario.apply_early_exam_modifiers()
		
	if scenario:
		_load_game_scenario(scenario)
		
	game_config.battle_info = battle_info

func _load_game_scenario(scenario: GameConfig):
	ResourceUtils.update_resource(game_config, scenario)
