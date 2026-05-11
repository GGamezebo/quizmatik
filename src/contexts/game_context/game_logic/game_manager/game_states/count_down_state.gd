class_name CountDownState
extends StateBase

@export var air_plane: AirPlane
@export var spawn_duration: float = 2.4
@export var spawn_distance: float = 660.0
@export var spawn_scale: float = 2.0
@export var spawn_alpha: float = 0.0

static func get_state() -> String:
	return FSMGameStates.COUNTDOWN
	
func enter(_prev_state: FSMState, _event_data: Dictionary) -> void:
	air_plane.set_process(false)
	_start_spawn_animation()
	
func leave(_event_data: Dictionary) -> void:
	air_plane.set_process(true)
	
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
	
