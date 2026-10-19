class_name LanguagePicker
extends HBoxContainer

## Settings row «🌐 Язык»: languages the platform offers (`GameLocale.ordered` → default/system one first).
## Up to `inline_max` → flags right in the row; more → one button «flag + name» that opens `LanguageOverlay`.
## One language → the whole row hides. Choice → `UserSettings.language` + save; `LocaleController` applies it.

@export var user_settings: UserSettings
@export var platform_services: PlatformServices
## Language code → flag texture (`GameLocale.SUPPORTED`).
@export var flags: Dictionary[String, Texture2D] = {}
@export var flag_scene: PackedScene
@export var inline_max: int = 3
@export var inline_flags: HBoxContainer
@export var current_button: BaseButton
@export var current_flag: TextureRect
@export var current_name: Label
@export var overlay: LanguageOverlay

var _listener: EventListener = EventListener.new()
var _inline_langs: PackedStringArray = []


func _ready() -> void:
	current_button.pressed.connect(_open_overlay)
	overlay.ev_chosen.connect(_choose)
	if user_settings != null:
		_listener.add(user_settings.ev_changed, refresh)
	if platform_services != null:
		_listener.add(platform_services.ev_language_changed, refresh)
	refresh()


func _exit_tree() -> void:
	_listener.deinit()


func refresh() -> void:
	var langs := GameLocale.ordered(platform_services)
	var active := GameLocale.current(user_settings, platform_services)
	visible = langs.size() > 1
	var is_inline := langs.size() <= inline_max
	inline_flags.visible = is_inline
	current_button.visible = not is_inline
	if is_inline:
		_build_inline(langs)
		for flag in inline_flags.get_children():
			if flag is LanguageFlag:
				flag.set_active(flag.language == active)
	current_flag.texture = flags.get(active)
	current_name.text = GameLocale.native_name(active)


func _build_inline(langs: PackedStringArray) -> void:
	if langs == _inline_langs:
		return
	_inline_langs = langs
	for child in inline_flags.get_children():
		inline_flags.remove_child(child)
		child.free()
	for code in langs:
		var flag: LanguageFlag = flag_scene.instantiate()
		flag.language = code
		flag.texture_normal = flags.get(code)
		flag.tooltip_text = GameLocale.native_name(code)
		flag.pressed.connect(_choose.bind(code))
		inline_flags.add_child(flag)


func _open_overlay() -> void:
	overlay.open(
		GameLocale.ordered(platform_services),
		GameLocale.current(user_settings, platform_services),
		flags,
	)


func _choose(language: String) -> void:
	if user_settings == null or user_settings.language == language:
		return
	user_settings.language = language
	user_settings.save()
