---
paths:
  - "src/common/events/**/*"
  - "src/features/boss/boss_new_year*"
  - "src/features/answer/ornament*"
  - "src/ui/backgrounds/new_year/**/*"
---

# New Year seasonal content

- `src/common/events/new_year/new_year_event.tres`: id `new_year`; 6 gifts + `cover_new_year`; catalog references same resources.
- `event_calendar.tres`: 10 runs, 2026-12-25–2027-01-10 through 2035-12-25–2036-01-10; UTC inclusive end; same content, independent `EventWindow.key()` progress.
- `boss_new_year_airship.tscn` inherits `boss_airship.tscn`; wing scene supplies ice/berry textures; preserve body/plate anchors.
- `ornament_answer.tscn` inherits `answer.tscn`; `ornaments_atlas.svg` = 1280×720, 5×3 cells; keep number area clear.
- `new_year_background.tscn`: BackgroundBase, mirror_seamless, `new_year_music.ogg`; unique scenery central, quiet edges.
- `tools/generate_new_year_art.py`: only New Year SVG outputs. `tools/generate_music.py new_year_music.ogg`: only New Year audio.
- Content-only extension: no event-id branches, new shader patterns or glyph code. Paint TEXTURE; trail SIGNS + sign_textures.
- Validation: `godot_console --headless --path . --script tools/check_new_year.gd`; no disk profile writes.

- Dev preview: EventCalendar.set_debug_window(key) / debug_window() = editor-only, runtime-only shared calendar override; empty key restores dates; explicit unix queries stay real. current_unix() clamps preview time to selected run for banner countdown.
- Lab BlockEvent/EventPicker lists unexpired windows by date; windows without content disabled. Selection emits RootEvents.ev_profiles_changed. Menu EventEntry allows preview before first flight. Preview persists across scenes, clears on process restart; rewards use real selected run keys.
- Preview integration check: tools/check_event_preview.gd (picker → calendar → menu banner → battle payload, annual banner override, reset).

- New Year banner: banner.png (1344×320 for 672×160 UI), generated from banner.svg via tools/render_svg.gd + existing generate_halloween_art.cta_frame (menu btn_cta_wide.png, margins 70/60). Rebuild: python tools/generate_new_year_art.py banner. Keep timer area free of decorations.
