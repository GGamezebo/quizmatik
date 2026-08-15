# Quizmatik — Visual Concept

Canonical art direction. Match this folder before restyling UI or battle.

## Recipe

| Piece | Source |
|-------|--------|
| **Layout (menu)** | `menu_notebook_modern_v3.png` — hero center, 2 big CTAs bottom, circular utilities on right |
| **Look & feel** | Graphite / colored pencil on cream grid paper — sticker HUD, ink stamps (`post_battle_notebook_concept_v3.png`, `battle_notebook_modern_v1.png`) |
| **Battle answers** | Paper **balloons** with big numbers (`ref_answer_balloon.png`) |

Menu frames: `menu_notebook_modern_v3.png` (canonical), `menu_notebook_modern_v2.png` (alt: school doodles + parchment title). Achievements / trophy room: `achievements_notebook_concept_v1.png`. Battle: `battle_notebook_modern_v1.png`. HUD kit: `concepts/notebook_pencil/ui_pack/`.

## Mood

Handmade kids’ notebook adventure: graphite pencil on grid paper, cream parchment UI — not neon arcade, not grim sci‑fi.

## Palette

| Token | Approx | Use |
|-------|--------|-----|
| Cream parchment | `#F3E6C8` | Buttons, panels, quest notes |
| Ink graphite | `#2A3340` | Titles, button text, borders |

Battle sprites (plane + balloons): thick cream/white **sticker outline** (die-cut look), matching `battle_notebook_modern_v1.png`.

Font: theme `core/theme/game_font.tres` = `SystemFont` (rounded-first fallbacks: Arial Rounded MT Bold → SF Pro Rounded → Segoe UI / Roboto / Noto Sans) — no bundled TTF required for Mobile / Steam / HTML.
| Paper hover | `#FAF0DB` | Button hover fill |
| Paper pressed | `#E0D1B3` | Button pressed fill |
| Accent warm | `#F0C94A` | Stars / highlights |
| Heart red | `#E85A5A` | Health |
| Win green | `#38704D` | Post-battle win title |
| Lose red | `#B34742` | Post-battle lose title |

Avoid as primary look: cyan neon HUD, purple-on-white AI gradients, flat Material cards.

## Materials & edges

- Cream paper fills with graphite outlines (theme `core/theme/style.tres`)
- Runtime textures live under `assets/` or `src/` — never keep playable assets only in `concepts/`
- Soft drop shadows like sticker depth on notebook
- Stickers, pins OK as decoration — sparingly

## Main menu layout (required)

Match `menu_notebook_modern_v3.png` (alt `menu_notebook_modern_v2.png`). Same sticker/stamp language as battle HUD + post-battle.

1. Background = scrolling **classic sky** (`classic_sky/`). Color clarity follows completed dailies (`paint_from_daily`): 0 = soft graphite wash, 5/5 = **full color**. UI stickers/CTAs stay notebook-pencil on top.  
2. Title **Улётная математика** — green sticker letters or parchment banner (not a 5-button stack)  
3. Center: mascot (“Нулик”) sticker + speech bubble («Полетели!»)  
4. Left: music HUD circle + **Дейлики** scrap + 5 rubber-ink stamps (sun / flower / cat / star / check — same as post-battle)  
5. **Bottom:** two wide cream sticker CTAs  
   - Left: Приключение → уровни  
   - Right: Практика → тренировка  
6. **Right column:** three circular HUD stickers (same as `src/ui/hud/` / `ui_pack` buttons) — Настройки, Достижения (Зал трофеев), Выход  

No single vertical stack of equal menu buttons (old Играть / Тренировка / Трофеи / Настройки / Выход list is retired).

## Level pack window (required)

Keep the live carousel: horizontal pack cards, selected center, next peeking right, back bottom-left. Restyle to notebook — `concepts/levels_pack_notebook_concept_v1.png`.

- Graph-paper page + spiral holes + margin doodles (same language as post-battle)
- Pack = cream paper card (graphite outline, sticker shadow); selected has a colored-pencil valley sketch + torn title banner + progress scrap `N / 17`
- Locked / next: graphite-only sketch, outline title, lock stamp — still cream paper, never charcoal fill
- Back: round cream HUD button (same as post-battle)
- Scroll: graphite / paper strip, not a dark digital bar

## Achievements / trophy room (required)

Restyle stats window to notebook — `concepts/achievements_notebook_concept_v1.png`. Same graph-paper page + margin doodles as pack / post-battle. Not cyan neon gradient.

- Assets (separate): `src/game/scenes/menu/trophy_room_window/ui/` — `bg_achievements`, `plaque_achievements`, `pencil_achievements`, `trophy_sticker`, `title_dostizheniya`
- Center cream parchment plaque + title scrap + winged trophy sticker + pencil doodle
- Two-column stats: muted graphite labels / warm amber values — same rows as `ProgressStatistics.DISPLAY_ROWS`
- Soft pencil row dividers — no digital table chrome
- Back: round cream HUD circle bottom-left (`levels/ui/btn_back.png`, same as pack)

## Battle layout (required)

Same **Paper Sky** papercraft as `ref_style_paper_sky.png` (cut paper clouds, grain, soft shadows).

1. **Horizontal flight:** plane on the **left**, nose **right**; shots go **right**  
2. Exactly **4 horizontal lanes** (rows) across the playfield  
3. **One round paper balloon per lane** on the right — style of `ref_answer_balloon.png` (watercolor fill, white rim, knot + string, big number); balloons move along the lane toward the plane  
4. Layered paper clouds drifting in the sky  
5. HUD on torn parchment / paper chips (score, hearts, exit, question banner) — battle sprites in `src/ui/hud/` (notebook sticker set)  
6. Lane guides: thin **white paper ribbons** across the playfield (`ui/lines.gd`) — soft shadow, cut-paper edges; see `concepts/gameplay_preview/02_battle.png`  
7. Numbers always readable  
8. Post-battle: smooth framed paper card + school ink stamps (not stars) + round HUD icon buttons; score as Label font (no number textures) — `concepts/post_battle_notebook_concept_v3.png`  

See `battle_concept.png`, notebook modern ref `concepts/notebook_pencil/battle_modern_v1.png`, HUD kit `concepts/notebook_pencil/ui_pack/`.

## Motion

- Menu: gentle bob on Nulik / speech bubble, soft “paste-on” pops on CTAs and stamps  
- Battle: balloon sway + float, short watercolor pop on hit (`balloon_pop_atlas.png`), light plane motion  
- Prefer 2–3 intentional motions

## Implementation mapping

| Concept | Code home |
|---------|-----------|
| Menu layout / windows | `src/game/scenes/menu/` |
| Level pack carousel | `src/ui/backgrounds/levels_pack/` + `src/game/scenes/menu/levels/` |
| Battle HUD / world | `src/game/scenes/game/` |
| Answer look → balloons | `src/features/answer/` (+ art) |
| Balloon pop VFX | `src/features/answer/balloon_pop.tscn` |
| Plane / shot / ink trail | `src/features/plane/`, `shot/`, `ink_blot/` |

| Theme | `core/theme/` — cream paper + graphite ink (`style.tres`) |
| Backgrounds | `src/ui/backgrounds/` — battle `BackgroundHost` + variants; main menu: scrolling `classic_sky/` + daily paint; pack / level-select: `paper_page/` / `levels_pack/` |

## Rules for agents

1. Read this file + look at `menu_notebook_modern_v3.png` / `battle_notebook_modern_v1.png` / `post_battle_notebook_concept_v3.png` before UI work.  
2. Prefer editor-built UI; templates for repeated balloon/level items.  
3. Mobile / Steam / HTML landscape: big touch CTAs, readable balloon numbers.  
4. Do not revert to cyan neon arcade skin unless the user asks.
