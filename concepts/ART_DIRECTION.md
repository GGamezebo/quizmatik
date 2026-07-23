# Quizmatik — Visual Concept

Canonical art direction. Match this folder before restyling UI or battle.

## Recipe

| Piece | Source |
|-------|--------|
| **Layout (menu)** | `ref_layout_jetmath.png` — hero character center, 2 big CTAs bottom, utilities on right |
| **Look & feel** | `ref_style_paper_sky.png` — watercolor papercraft / scrapbook |
| **Battle answers** | Paper **balloons / hot-air balloons** with big numbers (`ref_battle_balloons.png` + balloon from Jet Math) |

Final frames: `menu_concept.png`, `battle_concept.png`.

## Mood

Handmade kids’ sky adventure: cut paper, soft shadows, cheerful — not neon arcade, not grim sci‑fi.

## Palette

| Token | Approx | Use |
|-------|--------|-----|
| Sky wash | `#A8D4F0` → `#E8F4FC` | Background |
| Cloud paper | `#FFFFFF` / `#D6EAF8` | Layered cutouts |
| Cream parchment | `#F3E6C8` | Quest notes, question banner |
| CTA purple | `#6B4FA2` | Adventure button |
| CTA green | `#3FA86A` | Practice button |
| Accent warm | `#F0C94A` | Sun, stars, plates |
| Ink | `#2A3340` | Titles / numbers (high contrast) |
| Heart red | `#E85A5A` | Health |

Avoid as primary look: cyan neon HUD, purple-on-white AI gradients, flat Material cards.

## Materials & edges

- Textured paper grain, watercolor blotches
- Irregular / torn / hand-cut edges on panels and buttons
- Soft drop shadows between layers (papercraft depth)
- Stickers, pins, origami birds OK as decoration — sparingly

## Main menu layout (required)

Top → bottom / sides:

1. Soft paper-cloud sky background  
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
5. HUD on torn parchment / paper chips (score, hearts, exit, question banner)  
6. Numbers always readable  

See `battle_concept.png` and gameplay ref `ref_current_battle_hud.png`.

## Motion

- Menu: gentle bob on balloons/clouds, soft “paste-on” pops  
- Battle: balloon sway + float, short pop on hit, light plane motion  
- Prefer 2–3 intentional motions

## Implementation mapping

| Concept | Code home |
|---------|-----------|
| Menu layout / windows | `src/game/scenes/menu/` |
| Battle HUD / world | `src/game/scenes/game/` |
| Answer look → balloons | `src/features/answer/` (+ art) |
| Plane / shot | `src/features/plane/`, `shot/` |
| Theme | `core/theme/` — retarget toward paper buttons over neon StyleBoxes |
| Background | `src/ui/background/` |

## Rules for agents

1. Read this file + look at `menu_concept.png` / `battle_concept.png` before UI work.  
2. Prefer editor-built UI; templates for repeated balloon/level items.  
3. Mobile / Steam / HTML landscape: big touch CTAs, readable balloon numbers.  
4. Do not revert to cyan neon arcade skin unless the user asks.
