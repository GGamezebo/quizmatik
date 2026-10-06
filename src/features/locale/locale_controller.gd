class_name LocaleController
extends Node

## App-root language: player choice (`UserSettings.language`, menu flags) or the auto-detected one
## (platform SDK → OS locale) → `TranslationServer`. Re-applies on settings save / platform language.

@export var user_settings: UserSettings
@export var platform_services: PlatformServices

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if user_settings != null:
		_listener.add(user_settings.ev_changed, apply)
	if platform_services != null:
		_listener.add(platform_services.ev_language_changed, apply)
	apply()


func _exit_tree() -> void:
	_listener.deinit()


func apply() -> void:
	GameLocale.apply(GameLocale.current(user_settings, platform_services))
