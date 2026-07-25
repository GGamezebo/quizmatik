class_name StatisticsController
extends Node

@export var pdata: PData
@export var root_events: RootEvents
@export var game_events: GameEvents

var _listener: EventListener = EventListener.new()
var _game_session_start_msec: int = -1
var _battle_start_msec: int = -1

func _ready() -> void:
	_start_game_session()
	_listener.add(root_events.ev_battle_started, _on_battle_started)
	_listener.add(root_events.ev_battle_finished, _on_battle_finished)
	_listener.add(root_events.ev_exit_game, _on_exit_game)
	_listener.add(game_events.ev_shoot, _on_shoot)
	_listener.add(game_events.ev_correct_answer, _on_correct_answer)
	_listener.add(game_events.ev_mistake, _on_mistake)

func _exit_tree() -> void:
	_finish_game_session()
	_listener.deinit()
	_save()

func _stats() -> PData.StatisticsData:
	return pdata.statistics

func _save() -> void:
	root_events.ev_save_progress.emit()

func _start_game_session() -> void:
	_game_session_start_msec = Time.get_ticks_msec()
	_stats().game_sessions += 1
	_save()

func _on_battle_started() -> void:
	_battle_start_msec = Time.get_ticks_msec()
	_stats().total_battles += 1
	_save()

func _on_battle_finished() -> void:
	if _battle_start_msec < 0:
		return
	var duration_seconds: float = (Time.get_ticks_msec() - _battle_start_msec) / 1000.0
	_battle_start_msec = -1
	if duration_seconds <= 0.0:
		return
	_stats().battle_total_time += duration_seconds
	_save()

func _finish_game_session() -> void:
	if _game_session_start_msec < 0:
		return
	var duration_seconds: float = (Time.get_ticks_msec() - _game_session_start_msec) / 1000.0
	_game_session_start_msec = -1
	if duration_seconds <= 0.0:
		return
	_stats().total_time += duration_seconds
	_save()

func _on_shoot() -> void:
	_stats().total_shoot_count += 1

func _on_correct_answer() -> void:
	_stats().total_answers += 1

func _on_mistake() -> void:
	_stats().total_mistakes += 1

func _on_exit_game(data: Dictionary) -> void:
	if not data.has("score"):
		return
	var stats := _stats()
	stats.total_scores += int(data.get("score", 0))
	stats.total_stars += int(data.get("stars", 0))
	if data.get("is_win", false):
		stats.total_wins += 1
	_save()
