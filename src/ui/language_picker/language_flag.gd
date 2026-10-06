class_name LanguageFlag
extends TextureButton

## One flag in `LanguagePicker`: `language` = `GameLocale.SUPPORTED` code. Active = full color + ink underline.

@export var language: String = GameLocale.RU
@export var underline: Control
@export_range(0.0, 1.0) var inactive_alpha: float = 0.5


func set_active(is_active: bool) -> void:
	self_modulate.a = 1.0 if is_active else inactive_alpha
	if underline != null:
		underline.visible = is_active
