class_name StatisticsController
extends Node

@export var pdata: PDataProgress
@export var main_events: MainEvents
@export var game_events: GameEvents

var _listener: EventListener = EventListener.new()
var _game_session_start_msec: int = -1
var _battle_start_msec: int = -1

func _ready() -> void:
	_start_game_session()
	_listener.add(main_events.ev_battle_started, _on_battle_started)
	_listener.add(main_events.ev_battle_finished, _on_battle_finished)
	_listener.add(game_events.ev_shoot, _on_shoot)

func _exit_tree() -> void:
	_finish_game_session()
	_listener.deinit()
	_save()

func _statistics() -> Dictionary:
	return pdata.progress["statistics"]

func _save() -> void:
	ResourceUtils.save_resource_to_disk(pdata, pdata.SAVE_PATH)

func _start_game_session() -> void:
	_game_session_start_msec = Time.get_ticks_msec()
	var stats := _statistics()
	stats["game_session_count"] = int(stats["game_session_count"]) + 1
	_save()

func _on_battle_started() -> void:
	_battle_start_msec = Time.get_ticks_msec()

func _on_battle_finished() -> void:
	if _battle_start_msec < 0:
		return
	var duration_seconds: float = (Time.get_ticks_msec() - _battle_start_msec) / 1000.0
	_battle_start_msec = -1
	if duration_seconds <= 0.0:
		return
	var stats := _statistics()
	stats["battle_total_time"] = float(stats["battle_total_time"]) + duration_seconds
	_save()

func _finish_game_session() -> void:
	if _game_session_start_msec < 0:
		return
	var duration_seconds: float = (Time.get_ticks_msec() - _game_session_start_msec) / 1000.0
	_game_session_start_msec = -1
	if duration_seconds <= 0.0:
		return
	var stats := _statistics()
	stats["total_time"] = float(stats["total_time"]) + duration_seconds
	_save()

func _on_shoot() -> void:
	var stats := _statistics()
	stats["total_shoot_count"] = int(stats["total_shoot_count"]) + 1
