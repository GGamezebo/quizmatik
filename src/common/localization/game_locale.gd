class_name GameLocale
extends RefCounted

## UI languages. Source text = Russian (in scenes / scripts); other languages live in `translations.csv`
## (key = Russian text, one column per language). Controls auto-translate their `text`; scripts use `tr()` for formats.
## Each platform may offer only part of them (`PlatformServices.languages`, set by platform contexts).

const RU := "ru"
const EN := "en"
## Every UI language (`ru` = source, the rest = CSV columns). Picker order after the default language.
const SUPPORTED: PackedStringArray = ["ru", "en", "tr", "es", "pt", "de", "fr", "it", "pl", "uk", "id", "nl"]
## Name of each language in that language (picker labels — never translated).
const NATIVE_NAMES: Dictionary[String, String] = {
	"ru": "Русский",
	"en": "English",
	"tr": "Türkçe",
	"es": "Español",
	"pt": "Português",
	"de": "Deutsch",
	"fr": "Français",
	"it": "Italiano",
	"pl": "Polski",
	"uk": "Українська",
	"id": "Bahasa Indonesia",
	"nl": "Nederlands",
}
## System / platform languages that default to Russian when it is offered; any other unknown one → English.
const RUSSIAN_DEFAULT_FOR: PackedStringArray = ["ru", "be", "kk", "uz"]
## Legacy system codes → ours (Android reports Indonesian as `in`).
const ALIASES: Dictionary[String, String] = {"in": "id"}


## Languages the running platform offers, in `SUPPORTED` order (no platform list → all of them).
static func available(services: PlatformServices) -> PackedStringArray:
	if services == null or services.languages.is_empty():
		return SUPPORTED
	var langs := PackedStringArray()
	for code in SUPPORTED:
		if code in services.languages:
			langs.append(code)
	return langs if not langs.is_empty() else SUPPORTED


## System language: platform SDK (e.g. Yandex) first, then OS / browser locale. May be unsupported.
static func system_language(services: PlatformServices) -> String:
	var lang: String = services.language if services != null else ""
	if lang.is_empty():
		lang = OS.get_locale_language()
	var code := lang.to_lower().get_slice("_", 0).get_slice("-", 0)
	return ALIASES.get(code, code)


## Auto-detected language: the system one if offered, else Russian (for RU-speaking regions) / English / the first offered.
static func default_language(services: PlatformServices) -> String:
	var langs := available(services)
	var code := system_language(services)
	if code in langs:
		return code
	if code in RUSSIAN_DEFAULT_FOR and RU in langs:
		return RU
	if EN in langs:
		return EN
	return langs[0]


## Player choice (`UserSettings.language`) wins over the detected default while the platform offers it.
static func current(settings: UserSettings, services: PlatformServices) -> String:
	if settings != null and settings.language in available(services):
		return settings.language
	return default_language(services)


## Picker order: the default (system) language first, then the rest in `SUPPORTED` order.
static func ordered(services: PlatformServices) -> PackedStringArray:
	var first := default_language(services)
	var langs := PackedStringArray([first])
	for code in available(services):
		if code != first:
			langs.append(code)
	return langs


static func native_name(code: String) -> String:
	return NATIVE_NAMES.get(code, code)


## Russian word-form key for `n` (`one` = 1 секунду, `few` = 2 секунды, `many` = 5 секунд), picked by the
## active UI language's plural rule; the CSV gives each key that language's form. Caller still `tr()`s it.
static func plural(n: int, one: String, few: String, many: String) -> String:
	var lang := TranslationServer.get_locale().get_slice("_", 0)
	var mod10 := absi(n) % 10
	var mod100 := absi(n) % 100
	var is_few := mod10 >= 2 and mod10 <= 4 and (mod100 < 12 or mod100 > 14)
	match lang:
		"ru", "uk":
			if mod10 == 1 and mod100 != 11:
				return one
			return few if is_few else many
		"pl":
			if n == 1:
				return one
			return few if is_few else many
		"fr":
			return one if n == 0 or n == 1 else many
		"tr", "id":
			return many
	return one if n == 1 else many


static func apply(lang: String) -> void:
	if TranslationServer.get_locale() != lang:
		TranslationServer.set_locale(lang)
