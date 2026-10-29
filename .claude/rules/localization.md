---
description: UI languages (ru source + 11 CSV columns), per-platform language sets, plurals, language picker
paths:
  - "**/*.{gd,tscn,tres,csv}"
---

# Localization

- Languages = `GameLocale.SUPPORTED` (`src/common/localization/game_locale.gd`): `ru` (source text in scenes/scripts) + CSV columns `en tr es pt de fr it pl uk id nl` (`pt` = Brazilian). Table `src/common/localization/translations.csv` (`keys` = exact Russian text); every column registered in `project.godot` `internationalization/locale/translations` as `translations.<lang>.translation`. `locale/fallback="ru"` — never `en`
- New/changed player-visible Russian text → add/update its row in the CSV with **all** columns in the same task (key byte-for-byte, real newlines, same `%d`/`%s` order and same line breaks as the key; no leading/trailing spaces). Parent-facing lines (paywall, parental gate, store statuses) = formal address; kid-facing = informal
- Static text in `.tscn` and Russian assigned to `Label`/`Button` `.text` / `tooltip_text` from code → auto-translated; no `tr()`
- Formats / concatenation → `tr("... %d ...") % value` (format string is the key; insert translated names via `tr(name)`); static funcs / RefCounted → `TranslationServer.translate()`
- Text built in code and visible during a language switch → re-render on `NOTIFICATION_TRANSLATION_CHANGED` (guard `is_node_ready()`); menu windows re-render on `on_window_enter`
- Player-typed text (pilot names) and language names → `auto_translate_mode = 2` (disabled); empty pilot name → `ProfileController.display_name_or_default`
- Number + word → `GameLocale.plural(n, one, few, many)` with the three Russian keys («секунду», «секунды», «секунд» / «минута», «минуты», «минут»), then `tr()`; it picks the key by the active language's rule (ru/uk, pl, fr, tr/id, other one/other). Never hand-roll mod-10 logic. CSV gives each key that language's form (non-Slavic: few = many = plural)
- Art with baked text → `*_<lang>.png` per CSV column + `LocaleTextureSwap` (`src/ui/locale_texture_swap/`) child of the TextureRect; never edit the Russian source art. Trophy room titles = `tools/generate_achievements_en_titles.py` (reads the CSV; new column → re-run + add PNGs to both swaps in `trophy_room_window.tscn`)
- Language choice (`GameLocale`): offered set = `available(PlatformServices)` (`services.languages`, empty = all); default = system language (`PlatformServices.language` from the platform SDK, else `OS.get_locale_language()`, alias `in`→`id`) if offered → else `ru` for `ru/be/kk/uz` when offered → else `en` → else first offered; `UserSettings.language` wins only while offered. Picker order = `ordered()` (default first)
- Per-platform sets only via platform contexts `services.set_languages(...)` on enter (`[]` on deinit): `YandexContext` = ru + en, `RuStoreContext` = ru; Google Play / others = all. Never `OS.has_feature` in UI for languages
- Apply only via `LocaleController` (`src/features/locale/`, AppRoot) → `TranslationServer.set_locale`; UI never calls `set_locale`
- Picker: `LanguagePicker` (`src/ui/language_picker/`) = the whole settings row `RowLanguage` (globe + «Язык» + choice): 1 language → row hidden; ≤ `inline_max` (3) → `LanguageFlag` template per language in the row; more → button «flag + native name» → `LanguageOverlay` (CanvasLayer, grid of `LanguageCard` template, default first, active = green border + check, tap = choose + close). Flags = `flag_<code>.svg` in `LanguagePicker.flags`; names = `GameLocale.NATIVE_NAMES`
- New language = CSV column + `project.godot` translation entry + `GameLocale.SUPPORTED` / `NATIVE_NAMES` (+ `plural` rule if new) + `flag_<code>.svg` in `LanguagePicker.flags` + title art re-run; check fonts cover it (Nunito / Rubik Doodle: Latin + Cyrillic only)
- Store listing texts (Google Play, 12 languages) → `.claude/doc/google_play_listing.md`
- `src/dev/` lab stays Russian-only
