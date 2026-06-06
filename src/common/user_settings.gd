class_name UserSettings
extends Resource

const SAVE_PATH: String = "user://settings.tres"

@export_category("Audio")
@export var is_music_mute = false

@export_category("Controls")
## AirPlane.MovementMode: 0 = DIRECT, 1 = DISCRETE
@export var movement_mode: int = 1


func save():
	var error = ResourceSaver.save(self, SAVE_PATH)
	if error == OK:
		print("settings is saved on the disc")
