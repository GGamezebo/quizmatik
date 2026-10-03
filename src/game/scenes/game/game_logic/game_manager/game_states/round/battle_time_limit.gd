class_name BattleTimeLimit
extends RefCounted

## Timed level countdown (`GameConfig.time_limit_sec` > 0): ticks whole seconds, fires once at 0.

signal ev_tick(seconds_left: int)
signal ev_expired

var _left: float = 0.0
var _active: bool = false
var _paused: bool = false
var _shown: int = -1


func _init(limit_sec: float) -> void:
	_left = limit_sec
	_active = limit_sec > 0.0


func deinit() -> void:
	_active = false


func set_paused(paused: bool) -> void:
	_paused = paused


func update(delta: float) -> void:
	if not _active or _paused:
		return
	_left = maxf(_left - delta, 0.0)
	var seconds: int = ceili(_left)
	if seconds != _shown:
		_shown = seconds
		ev_tick.emit(seconds)
	if _left <= 0.0:
		_active = false
		ev_expired.emit()
