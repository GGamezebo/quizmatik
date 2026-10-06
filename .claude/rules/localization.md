---
description: UI languages (ru source + en), translation table, language choice
paths:
  - "**/*.{gd,tscn,tres,csv}"
---

# Localization

- Languages: `ru` (source text, written in scenes/scripts) + `en`. Table `src/common/localization/translations.csv` (`keys` = exact Russian text, column `en`; registered in `project.godot` `internationalization/locale/translations` as `translations.en.translation`). `locale/fallback="ru"` — never `en` (no `ru` column → Russian would fall back to English)
- New/changed player-visible Russian text → add/update its row in the CSV in the same task (key must match byte-for-byte, incl. `\n` as real newlines; no leading/trailing spaces in keys)
- Static text in `.tscn` and Russian assigned to `Label`/`Button` `.text` / `tooltip_text` from code → auto-translated; no `tr()`
- Formats / concatenation → `tr("... %d ...") % value` (format string is the key; insert translated names via `tr(name)`); static funcs / RefCounted → `TranslationServer.translate()`
- Text built in code and visible during a language switch → re-render on `NOTIFICATION_TRANSLATION_CHANGED` (guard `is_node_ready()`); menu windows re-render on `on_window_enter`
- Player-typed text (pilot names) → `auto_translate_mode = 2` (disabled) on its Label; empty name → `ProfileController.display_name_or_default` (localized `DEFAULT_NAME`)
- Russian plural words: keep RU logic, `tr()` each word form (see `timed_intro.gd`)
- Art with baked text → `*_en.png` variant + `LocaleTextureSwap` (`src/ui/locale_texture_swap/`) child of the TextureRect; never edit the Russian source art. Ref: trophy room (`tools/generate_achievements_en_titles.py`)
- Language choice: `GameLocale` (`src/common/localization/`) = `UserSettings.language` (settings flags; empty = auto) → else `PlatformServices.language` (set only by platform contexts, Yandex `environment.i18n.lang`) → else `OS.get_locale_language()`; `ru/be/kk/uz` → ru, other → en
- Apply only via `LocaleController` (`src/features/locale/`, AppRoot) → `TranslationServer.set_locale`; UI never calls `set_locale`
- Flags: `LanguagePicker` (`src/ui/language_picker/`, settings window first row `RowLanguage`); one `LanguageFlag` child per language; detected default language flag first. New language = CSV column + `GameLocale.SUPPORTED` + flag child
- `src/dev/` lab stays Russian-only
