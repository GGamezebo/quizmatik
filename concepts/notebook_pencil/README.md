# Notebook pencil concept (exploratory)

**Not wired into the game.** Assets here are a style pack only — current shipping look remains Paper Sky / watercolor in `concepts/ART_DIRECTION.md`.

## Source look

Hand-drawn **colored pencil + graphite on school grid paper** (see `battle_concept_ref.png`):

- Cream squared notebook background
- Sketchy imperfect outlines, visible hatching
- Glossy sticker-like highlights on balloons / hearts
- Paper HUD scraps (score chip, question banner)
- Blocky toy plane (purple / blue accents)

## Contents

| File | Role |
|------|------|
| `battle_concept_ref.png` | Full battle mockup (source concept) |
| `bg_grid_paper.png` | Grid-paper background (opaque RGB) |
| `clouds_atlas.png` | Cloud sheet, **RGBA** transparent; trial: 3 slices → `src/ui/background/cloud_notebook_*.png` |
| `ui_atlas.png` | Score scrap, question banner, hearts — **RGBA** |
| `balloons_atlas.png` | **16** blank balloons (4×4), no strings, no numbers — **RGBA**; pencil style + `BALLOON_TINTS` order |
| `plane_idle.png` / `plane_up.png` / `plane_down.png` | Same 3 orientations as `src/features/plane/`, notebook style — **RGBA** |
| `bg_gameplay_sky.png` | Pencil landscape on grid paper (style ref for sketches) |
| `bg_sketches/` | 10 hand-colored school sketches; battle reveals paint with score (`color_amount`) |
| `bg_parallax/` | 5 transparent stack layers for parallax |
| `_process_assets.py` | Optional regen helper (chroma-key + balloon atlas) |

## Balloon colors

Cells 0–14 match `BALLOON_TINTS` in `src/features/answer/answer.gd` (same order as the live atlas).  
Cell 15 is an extra warm peach (game still uses 15 tints).

Numbers are drawn by the game `Label`, so concept balloons stay blank.

## Next steps (when integrating)

1. Swap battle background / cloud textures to these.
2. Slice `ui_atlas.png` into HUD nodes (or keep as atlas regions).
3. Point answer balloons at `balloons_atlas.png` (16 frames or keep 15).
4. Replace `Plane.png` / `PlaneUp.png` / `PlaneDown.png` with the three plane files.
5. Update `ART_DIRECTION.md` if this becomes the canonical look.
