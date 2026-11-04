extends Button

## Dev only: «+30 с» under the exit button in the editor or a `dev_lab` test export (`DevBuild`) while the lab
## checkbox (`UserSettings.debug_time_skip`) is on, in timed / staged battles. Press → `GameEvents.ev_skip_time`.

@export var game_events: GameEvents
@export var user_settings: UserSettings
@export var seconds: float = 30.0


func _ready() -> void:
	visible = false
	pressed.connect(_on_pressed)


func initialize(game_config: GameConfig) -> void:
	visible = DevBuild.is_enabled() and user_settings != null and user_settings.debug_time_skip \
		and game_config != null and (game_config.is_timed() or game_config.is_staged())


func _on_pressed() -> void:
	if game_events != null:
		game_events.ev_skip_time.emit(seconds)
