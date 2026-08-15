class_name UserSettings
extends Resource

const SAVE_PATH: String = "user://settings.json"

@export_category("Audio")
@export var is_music_mute = false
## Mutes the Master bus (all game audio).
@export var is_sound_mute = false
@export_range(0.0, 1.0) var music_volume: float = 1.0
@export_range(0.0, 1.0) var sfx_volume: float = 1.0

@export_category("Vibration")
@export var is_vibration_enabled: bool = true
@export_range(0.0, 1.0) var vibration_intensity: float = 1.0

@export_category("Controls")
## AirPlane.MovementMode: 0 = DIRECT, 1 = DISCRETE
@export var movement_mode: int = 0


func save() -> void:
	if ResourceUtils.save_json(SAVE_PATH, ResourceUtils.resource_to_dict(self)) == OK:
		print("settings is saved on the disc")
