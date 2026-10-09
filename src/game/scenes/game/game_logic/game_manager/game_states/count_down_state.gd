class_name CountDownState
extends StateBase

## Plane flies in, then GAME. Overlays may hold the start: `ev_countdown_entered` →
## `ev_hold_countdown(true)` … `(false)`; `ev_countdown_started` once the fly-in begins.

@export var game_events: GameEvents
@export var air_plane: AirPlane
@export var spawn_duration: float = 2.4
@export var spawn_distance: float = 660.0
@export var spawn_scale: float = 2.0
@export var spawn_alpha: float = 0.0

static func get_state() -> String:
	return FSMGameStates.COUNTDOWN
	
var _active: bool = false
var _held: bool = false
var _started: bool = false

func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	air_plane.set_process(false)
	air_plane.modulate.a = spawn_alpha
	_active = true
	_held = false
	_started = false
	if game_events:
		event_listener.add(game_events.ev_hold_countdown, _on_hold_countdown)
		game_events.ev_countdown_entered.emit()
	_try_start.call_deferred()
	
func leave(_event_data: Dictionary) -> void:
	_active = false
	if game_events:
		event_listener.remove(game_events.ev_hold_countdown, _on_hold_countdown)
	air_plane.set_process(true)

func _on_hold_countdown(held: bool) -> void:
	_held = held
	if not held:
		_try_start()

func _try_start() -> void:
	if not _active or _held or _started:
		return
	_started = true
	_start_spawn_animation()
	if game_events:
		game_events.ev_countdown_started.emit()
	
func _start_spawn_animation() -> void:
	var default_position: Vector2 = air_plane.position
	var spawn_offset = Vector2.from_angle(randf() * TAU) * spawn_distance
	var start_pos = default_position + spawn_offset
	
	var rand_bool = bool(randi() % 2)
	var scale_coeff = spawn_scale if rand_bool else 1.0 / spawn_scale
	
	air_plane.position = start_pos	
	air_plane.modulate.a = spawn_alpha
	air_plane.scale = Vector2(scale_coeff, scale_coeff)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(air_plane, "global_position", default_position, spawn_duration)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
		
	tween.tween_property(air_plane, "scale", Vector2(1, 1), spawn_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	tween.tween_property(air_plane, "modulate:a", 1.0, spawn_duration * 0.75)
	
	tween.set_parallel(true)
	tween.tween_callback(_on_animation_finish).set_delay(spawn_duration)
	
func _on_animation_finish() -> void:
	add_event(FSMGameEvents.START_GAME)
	
