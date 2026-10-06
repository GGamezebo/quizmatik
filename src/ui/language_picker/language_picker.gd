class_name LanguagePicker
extends HBoxContainer

## Menu language flags (`LanguageFlag` children). The auto-detected default language goes first,
## the active one is highlighted. Press → `UserSettings.language` + save; `LocaleController` applies it.

@export var user_settings: UserSettings
@export var platform_services: PlatformServices

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	for flag in _flags():
		flag.pressed.connect(_on_flag_pressed.bind(flag.language))
	if user_settings != null:
		_listener.add(user_settings.ev_changed, refresh)
	if platform_services != null:
		_listener.add(platform_services.ev_language_changed, refresh)
	refresh()


func _exit_tree() -> void:
	_listener.deinit()


func refresh() -> void:
	var default_language := GameLocale.default_language(platform_services)
	var active := GameLocale.current(user_settings, platform_services)
	for flag in _flags():
		if flag.language == default_language:
			move_child(flag, 0)
		flag.set_active(flag.language == active)


func _flags() -> Array[LanguageFlag]:
	var flags: Array[LanguageFlag] = []
	for child in get_children():
		if child is LanguageFlag:
			flags.append(child)
	return flags


func _on_flag_pressed(language: String) -> void:
	if user_settings == null or user_settings.language == language:
		return
	user_settings.language = language
	user_settings.save()
