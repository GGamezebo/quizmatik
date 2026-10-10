class_name EndlessDirector
extends RefCounted

## Endless battle (`GameConfig.endless`): counts seconds survived (`ev_tick`), raises difficulty every
## `endless_step_sec` (`GameConfig.apply_endless_stage`) and asks for a boss after every
## `endless_boss_every_sec` of balloons (`ev_boss_due`; the clock waits until `boss_finished`);
## `ev_heart_due` every `endless_heart_every_sec` (the listener spawns a heart balloon only if hurt).
## Paused together with the answers (`ev_pause_answers`).

signal ev_tick(seconds: int)
signal ev_boss_due
signal ev_heart_due

var _config: GameConfig
var _active: bool = false
var _paused: bool = false
var _elapsed: float = 0.0
var _shown: int = -1
var _step: int = 0
var _boss_clock: float = 0.0
var _boss_busy: bool = false
var _heart_clock: float = 0.0


## Applies the first stage right away — call before the first round is generated.
func _init(config: GameConfig) -> void:
	_config = config
	_active = config.endless
	if _active:
		_config.apply_endless_stage(0)


func deinit() -> void:
	_active = false
	_config = null


func set_paused(paused: bool) -> void:
	_paused = paused


## Boss fell — balloons again until the next `endless_boss_every_sec`.
func boss_finished() -> void:
	_boss_busy = false
	_boss_clock = 0.0


func update(delta: float) -> void:
	if not _active or _paused:
		return
	_elapsed += delta
	var seconds: int = floori(_elapsed)
	if seconds != _shown:
		_shown = seconds
		ev_tick.emit(seconds)
	var step: int = floori(_elapsed / maxf(_config.endless_step_sec, 1.0))
	if step != _step:
		_step = step
		_config.apply_endless_stage(step)
	if _config.endless_heart_every_sec > 0.0:
		_heart_clock += delta
		if _heart_clock >= _config.endless_heart_every_sec:
			_heart_clock = 0.0
			ev_heart_due.emit()
	if _boss_busy or _config.endless_boss_every_sec <= 0.0:
		return
	_boss_clock += delta
	if _boss_clock >= _config.endless_boss_every_sec:
		_boss_busy = true
		ev_boss_due.emit()
