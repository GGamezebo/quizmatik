extends IScene

@export var game_config: GameConfig
@export var levels_config: LevelsConfig
@export var root_events: RootEvents
@export var initable_components: Array[Node]

const VALLEY_BACKGROUNDS: Dictionary = {
	"addition": preload("res://src/ui/backgrounds/valley_addition/valley_addition_background.tscn"),
	"subtraction": preload("res://src/ui/backgrounds/valley_subtraction/valley_subtraction_background.tscn"),
	"multiplication": preload("res://src/ui/backgrounds/valley_multiplication/valley_multiplication_background.tscn"),
	"division": preload("res://src/ui/backgrounds/valley_division/valley_division_background.tscn"),
	"mix": preload("res://src/ui/backgrounds/valley_mix/valley_mix_background.tscn"),
}

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

	# Campaign: tie battle background to selected valley.
	if battle_info != null:
		var bg_host: BackgroundHost = get_node_or_null("HUD/Background") as BackgroundHost
		if bg_host != null:
			var packed: PackedScene = VALLEY_BACKGROUNDS.get(battle_info.container_id) as PackedScene
			bg_host.force_variant(packed)
	
	for component in initable_components:
		component.initialize(game_config)
	
	root_events.ev_battle_started.emit()

func deinit() -> void:
	root_events.ev_battle_finished.emit()

func _load_game_scenario(scenario: GameConfig):
	ResourceUtils.update_resource(game_config, scenario)
