extends AudioStreamPlayer

## Thrust loop: fades in/out and glides pitch on direction change — never hard restart/stop.
@export var max_volume_db: float = -12.0
@export var fade_in_time: float = 0.2
@export var fade_out_time: float = 0.35
@export var pitch_up: float = 1.04
@export var pitch_down: float = 0.96
@export var pitch_glide_time: float = 0.25

var _target_level: float = 0.0
var _target_pitch: float = 1.0
var _level: float = 0.0

func initialize(parent: Node) -> void:
	_updateSound(parent.direction_y)

func update(_delta: float) -> void:
	pass

func setDirection(direction_y: float) -> void:
	_updateSound(direction_y)

func _updateSound(direction_y: float) -> void:
	_target_level = 1.0 if direction_y != 0 else 0.0
	if direction_y < 0:
		_target_pitch = pitch_up
	elif direction_y > 0:
		_target_pitch = pitch_down
	if _target_level > 0.0 and not playing:
		_level = 0.0
		volume_linear = 0.0
		play(randf() * stream.get_length() if stream else 0.0)
	set_process(true)

# Own _process: keeps fading after the plane disables its processing (death / win).
func _process(delta: float) -> void:
	var fade_time := fade_in_time if _target_level > _level else fade_out_time
	_level = move_toward(_level, _target_level, delta / maxf(fade_time, 0.001))
	pitch_scale = lerpf(pitch_scale, _target_pitch, 1.0 - exp(-delta * 4.0 / maxf(pitch_glide_time, 0.001)))
	volume_linear = db_to_linear(max_volume_db) * _level * _level
	if _level <= 0.0 and _target_level <= 0.0:
		stop()
		set_process(false)
