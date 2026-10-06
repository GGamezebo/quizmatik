class_name GameLocale
extends RefCounted

## UI languages. Source text = Russian (in scenes / scripts); English lives in `translations.csv`
## (key = Russian text). Controls auto-translate their `text`; scripts use `tr()` for formats.

const RU := "ru"
const EN := "en"
const SUPPORTED: PackedStringArray = [RU, EN]
## System / platform languages that default to Russian; any other one → English.
const RUSSIAN_DEFAULT_FOR: PackedStringArray = ["ru", "be", "kk", "uz"]


## Auto-detected language: platform SDK (e.g. Yandex) first, then OS / browser locale.
static func default_language(services: PlatformServices) -> String:
	var lang: String = services.language if services != null else ""
	if lang.is_empty():
		lang = OS.get_locale_language()
	return normalize(lang)


## Player choice (`UserSettings.language`) wins over the detected default.
static func current(settings: UserSettings, services: PlatformServices) -> String:
	if settings != null and settings.language in SUPPORTED:
		return settings.language
	return default_language(services)


static func normalize(lang: String) -> String:
	var code := lang.to_lower().get_slice("_", 0).get_slice("-", 0)
	if code in SUPPORTED:
		return code
	return RU if code in RUSSIAN_DEFAULT_FOR else EN


static func apply(lang: String) -> void:
	if TranslationServer.get_locale() != lang:
		TranslationServer.set_locale(lang)
