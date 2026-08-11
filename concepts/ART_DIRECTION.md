# Quizmatik — Visual Concept

Canonical art direction. Match this folder before restyling UI or battle.

## Recipe

| Piece | Source |
|-------|--------|
| **Layout (menu)** | `ref_layout_jetmath.png` — hero character center, 2 big CTAs bottom, utilities on right |
| **Look & feel** | `ref_style_paper_sky.png` — watercolor papercraft / scrapbook |
| **Battle answers** | Paper **balloons / hot-air balloons** with big numbers (`ref_battle_balloons.png` + balloon from Jet Math) |

Final frames: `menu_concept.png`, `battle_concept.png`.

Exploratory alt pack (unused): `concepts/notebook_pencil/` — colored-pencil on grid paper; see that folder’s README.

## Mood

Handmade kids’ notebook adventure: graphite pencil on grid paper, cream parchment UI — not neon arcade, not grim sci‑fi.

## Palette

| Token | Approx | Use |
|-------|--------|-----|
| Cream parchment | `#F3E6C8` | Buttons, panels, quest notes |
| Ink graphite | `#2A3340` | Titles, button text, borders |
| Paper hover | `#FAF0DB` | Button hover fill |
| Paper pressed | `#E0D1B3` | Button pressed fill |
| Accent warm | `#F0C94A` | Stars / highlights |
| Heart red | `#E85A5A` | Health |
| Win green | `#38704D` | Post-battle win title |
| Lose red | `#B34742` | Post-battle lose title |

Avoid as primary look: cyan neon HUD, purple-on-white AI gradients, flat Material cards.

## Materials & edges

- Cream paper fills with graphite outlines (theme `core/theme/style.tres`)
- Soft drop shadows like sticker depth on notebook
- Stickers, pins OK as decoration — sparingly

## Main menu layout (required)

Top → bottom / sides:

1. Soft grayscale paper-cloud sky background (color blooms with completed dailies; 5/5 = full paint)  
2. Title **Улётная математика** (paper letters or parchment banner)  
3. Center: mascot (“Нулик”) + speech bubble  
4. Optional feed quest: pinned parchment + plate slots (progression teaser)  
5. **Bottom:** two wide primary buttons  
   - Left: Приключение → уровни  
   - Right: Практика → тренировка  
6. **Right column:** circular cloud buttons — Настройки, Достижения (Зал трофеев), Выход  
7. Decorative balloon / paper plane OK (same balloon language as battle)

No single vertical stack of equal menu buttons (old cyan arcade layout is retired).

## Battle layout (required)

Same **Paper Sky** papercraft as `ref_style_paper_sky.png` (cut paper clouds, grain, soft shadows).

1. **Horizontal flight:** plane on the **left**, nose **right**; shots go **right**  
2. Exactly **4 horizontal lanes** (rows) across the playfield  
3. **One round paper balloon per lane** on the right — style of `ref_answer_balloon.png` (watercolor fill, white rim, knot + string, big number); balloons move along the lane toward the plane  
4. Layered paper clouds drifting in the sky  
5. HUD on torn parchment / paper chips (score, hearts, exit, question banner) — battle sprites in `src/ui/hud/` (notebook sticker set)  
6. Lane guides: graphite **dashed** center lines per row (`ui/lines.gd`) — not neon glow  
7. Numbers always readable  

See `battle_concept.png`, notebook modern ref `concepts/notebook_pencil/battle_modern_v1.png`, HUD atlas `concepts/notebook_pencil/ui_atlas_modern.png`.

## Motion

- Menu: gentle bob on balloons/clouds, soft “paste-on” pops  
- Battle: balloon sway + float, short watercolor pop on hit (`balloon_pop_atlas.png`), light plane motion  
- Prefer 2–3 intentional motions

## Implementation mapping

| Concept | Code home |
|---------|-----------|
| Menu layout / windows | `src/game/scenes/menu/` |
| Battle HUD / world | `src/game/scenes/game/` |
| Answer look → balloons | `src/features/answer/` (+ art) |
| Balloon pop VFX | `src/features/answer/balloon_pop.tscn` |
| Plane / shot / ink trail | `src/features/plane/`, `shot/`, `ink_blot/` |

| Theme | `core/theme/` — cream paper + graphite ink (`style.tres`) |
| Backgrounds | `src/ui/backgrounds/` — `BackgroundHost` (battle random) + variant folders |

## Rules for agents

1. Read this file + look at `menu_concept.png` / `battle_concept.png` before UI work.  
2. Prefer editor-built UI; templates for repeated balloon/level items.  
3. Mobile / Steam / HTML landscape: big touch CTAs, readable balloon numbers.  
4. Do not revert to cyan neon arcade skin unless the user asks.
