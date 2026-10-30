---
paths:
  - "src/common/events/april_fools/**/*"
  - "src/features/boss/boss_april_fools*"
  - "src/features/answer/jester*"
  - "src/ui/backgrounds/april_fools/**/*"
---

# April Fools content

- `april_fools_event.tres`: id `april_fools`, title «1 апреля», 6 gifts + `cover_april_fools`; same resource refs in cosmetic catalog.
- Calendar: 11 runs 01.04–16.04 inclusive UTC, 2027–2037 = first upcoming season + ten annual repeats. Independent EventWindow keys.
- `april_fools_background.tscn`: BackgroundBase, mirror_seamless; curated ImageGen `bg_upside_down.png` 1080×720; `battle_music` = april_fools_music.ogg, `answer_scene` = jester_answer.tscn. Both follow the sky in any battle.
- `jester_balloons_atlas.png`: alpha, 1280×720, 5×3; standard Answer.BALLOON_TINTS order. Keep number centers clear.
- `boss_april_fools_airship.tscn` inherits boss_airship.tscn; mint/peach wings; preserve anchors.
- Banner 1344×320, displayed 672×160; actual menu btn_cta_wide.png frame via cta_frame; keep text/timer area clear.
- `generate_april_fools_art.py` = boss/gifts/banner only, never overwrite curated background/atlas. `pack_april_watercolor.gd` = input PNG sizing, alpha-preserving atlas packing; `-- banner` composes watercolor banner art.
- No event-id gameplay branches or new shader patterns; Paint TEXTURE, Trail SIGNS + sign_textures.
- Checks: tools/check_april_fools.gd + tools/check_event_preview.gd; memory-only profiles. Art prompts/context: `.Codex/doc/april_fools_event.md`.
