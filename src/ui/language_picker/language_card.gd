class_name LanguageCard
extends Button

## One language in `LanguageOverlay`: flag + native name (never translated). Active one = green border + check.

@export var flag_rect: TextureRect
@export var name_label: Label
@export var active_badge: Control

var code: String = ""


func setup(lang: String, flag: Texture2D, is_active: bool) -> void:
	code = lang
	flag_rect.texture = flag
	name_label.text = GameLocale.native_name(lang)
	set_active(is_active)


func set_active(is_active: bool) -> void:
	active_badge.visible = is_active
	disabled = is_active
	mouse_default_cursor_shape = Control.CURSOR_ARROW if is_active else Control.CURSOR_POINTING_HAND
