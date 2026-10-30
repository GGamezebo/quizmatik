class_name AnalyticsReporter
extends Node

## App-root analytics: turns battle results and gold purchases into anonymous `PlatformServices.ev_track`
## goals. Called by AppRoot (parent calls down); never sends ids, names or free text — only enum / number
## params. Which platform sends them (if any) is decided by the platform contexts.

const GOAL_BATTLE_END := &"battle_end"
const GOAL_EXAM_PASSED := &"exam_passed"
const GOAL_GOLDEN_FLIGHT := &"golden_flight"
const GOAL_ITEM_BOUGHT := &"item_bought"
const GOAL_PLANE_BOUGHT := &"plane_bought"

@export var platform_services: PlatformServices
## Live active profile (difficulty + gold balance after the event).
@export var pdata: PData


## `data` = `ev_exit_game` payload after AppRoot granted its rewards.
func report_battle(data: Dictionary) -> void:
	var config: GameConfig = data.get("game_config") as GameConfig
	if config == null:
		return
	var is_win: bool = bool(data.get("is_win", false))
	var params := _base_params()
	params["mode"] = battle_mode(config)
	params["win"] = 1 if is_win else 0
	params["stars"] = int(data.get("stars", 0))
	var valley := _valley_of(config)
	if not valley.is_empty():
		params["valley"] = valley
	if config.battle_info != null:
		params["level"] = config.battle_info.level_id
	if config.endless:
		params["sec"] = int(data.get("endless_sec", 0))
	_track(GOAL_BATTLE_END, params)

	if config.golden_flight and is_win:
		var flight := _base_params()
		flight["coins"] = int(data.get("golden_gold", 0))
		flight["sec"] = int(config.time_limit_sec)
		_track(GOAL_GOLDEN_FLIGHT, flight)
	var celebration: Dictionary = data.get("exam_celebration", {})
	if bool(celebration.get("first_exam_pass", false)):
		var exam := _base_params()
		exam["valley"] = valley
		_track(GOAL_EXAM_PASSED, exam)


func report_item_bought(item: CosmeticItem) -> void:
	if item == null:
		return
	var params := _base_params()
	params["slot"] = CosmeticItem.slot_key(item.get_slot())
	params["item"] = item.id
	params["price"] = item.gold_cost
	_track(GOAL_ITEM_BOUGHT, params)


func report_plane_bought(plane_id: String, cost: int) -> void:
	var params := _base_params()
	params["plane"] = plane_id
	params["price"] = cost
	_track(GOAL_PLANE_BOUGHT, params)


## Short battle kind for reports: level / exam / practice / endless / valley_record / expert / magister /
## event / golden_flight.
static func battle_mode(config: GameConfig) -> String:
	if config.golden_flight:
		return "golden_flight"
	if not config.event_key.is_empty():
		return "event"
	if config.magister:
		return "magister"
	if not config.expert_valley_id.is_empty():
		return "expert"
	if config.endless:
		return "endless" if config.endless_valley_id.is_empty() else "valley_record"
	if config.battle_info != null:
		return "exam" if config.battle_info.is_exam else "level"
	return "practice"


static func _valley_of(config: GameConfig) -> String:
	if config.battle_info != null:
		return config.battle_info.container_id
	if not config.expert_valley_id.is_empty():
		return config.expert_valley_id
	return config.endless_valley_id


func _base_params() -> Dictionary:
	if pdata == null:
		return {}
	return {"difficulty": pdata.difficulty, "gold": pdata.gold}


func _track(goal: StringName, params: Dictionary) -> void:
	if platform_services != null:
		platform_services.ev_track.emit(goal, params)
