# bg_parallax — stackable pencil layers

5 **RGBA PNG** layers (800px wide) for parallax over a shared grid-paper sky. Magenta keyed → transparent. **Not wired into the game.**

Stack bottom → top:

| File | Depth | Suggested scroll |
|------|-------|------------------|
| `01_sky.png` | farthest | slowest |
| `02_far_mountains.png` | far | slow |
| `03_mid_yard.png` | mid (yard / path) | medium |
| `04_near_trees.png` | near | faster |
| `05_foreground.png` | closest (sill / doodles) | fastest |

Put `../bg_grid_paper.png` (or grayscale sky) under them if you need the notebook sheet.
