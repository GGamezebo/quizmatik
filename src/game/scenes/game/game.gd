extends IScene

@export var game_config: GameConfig
@export var levels_config: LevelsConfig
@export var root_events: RootEvents
@export var initable_components: Array[Node]
## Active profile (shared live `.tres`) → equipped look items; isolated run → catalog defaults.
@export var pdata: PData
@export var cosmetics: CosmeticCatalog
## Campaign battle: small chance to swap the valley art for one of these (school / forests).
@export var rare_valley_backgrounds: Array[PackedScene] = []
@export_range(0.0, 1.0, 0.01) var rare_valley_background_chance: float = 0.15

func initialize(_data: Dictionary) -> void:
	var scenario: GameConfig = _data.get('custom_battle')
	var battle_info: GameConfig.BattleInfo = _data.get('battle_info')
	assert(not scenario or not battle_info, 'Incorrect battle config')
	
	if battle_info:
		var profiles := ProfileController.find_in_tree(get_tree())
		var difficulty: StringName = profiles.valley_difficulty() if profiles != null else BattleDifficulty.NORMAL
		scenario = levels_config.get_level_config(battle_info.container_id, battle_info.level_id, difficulty)
		if scenario:
			scenario = scenario.duplicate(true)
			if battle_info.is_early_exam:
				scenario.apply_early_exam_modifiers()
			if profiles != null:
				BattleDifficulty.apply(scenario, difficulty)
		
	if scenario:
		_load_game_scenario(scenario)
		
	game_config.battle_info = battle_info
	var review_facts: Variant = _data.get("review_facts", {})
	game_config.review_facts = review_facts if review_facts is Dictionary else {}
	game_config.endless_best_sec = pdata.statistics.endless_best_sec if pdata != null else 0
	_apply_equipped_plane()
	_apply_cosmetics()

	# Campaign: tie battle background to selected valley (rarely a school / forest instead).
	if battle_info != null:
		var bg_host: BackgroundHost = get_node_or_null("HUD/Background") as BackgroundHost
		if bg_host != null:
			var packed: PackedScene = ValleyBackgroundArt.get_scene(battle_info.container_id)
			if not rare_valley_backgrounds.is_empty() and randf() < rare_valley_background_chance:
				packed = rare_valley_backgrounds.pick_random()
			bg_host.force_variant(packed)
	
	for component in initable_components:
		component.initialize(game_config)
	
	root_events.ev_battle_started.emit()

func deinit() -> void:
	root_events.ev_battle_finished.emit()

func _load_game_scenario(scenario: GameConfig):
	ResourceUtils.update_resource(game_config, scenario)


func _apply_equipped_plane() -> void:
	var plane_id := "starter"
	var profiles := ProfileController.find_in_tree(get_tree())
	if profiles != null:
		plane_id = profiles.equipped_plane_id()
	game_config.equipped_plane_id = plane_id
	var plane := get_node_or_null("Player/AirPlane") as AirPlane
	if plane != null:
		plane.apply_plane(plane_id)


## Look only: paint / trail on the plane, shot ink. Never touches speed or combat.
func _apply_cosmetics() -> void:
	if cosmetics == null:
		return
	var equipped: Dictionary = pdata.cosmetics.equipped if pdata != null else {}
	var plane := get_node_or_null("Player/AirPlane") as AirPlane
	if plane != null:
		plane.apply_paint(cosmetics.equipped_item(CosmeticItem.Slot.PAINT, equipped) as PaintItem)
		plane.apply_trail(cosmetics.equipped_item(CosmeticItem.Slot.TRAIL, equipped) as TrailItem)
	var shots := get_node_or_null("Controllers/ShotManager")
	if shots != null:
		shots.apply_style(cosmetics.equipped_item(CosmeticItem.Slot.SHOT, equipped) as ShotItem)
