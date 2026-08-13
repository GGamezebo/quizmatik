# Notebook UI pack

RGBA kit matching `concepts/post_battle_notebook_concept_v3.png` and `concepts/battle_notebook_modern_v1.png`.

Cream parchment + graphite outlines, rubber-ink stamps, school doodle stickers. **Not wired into the game** — copy slices into `src/ui/hud/` / `src/game/scenes/post_battle/ui/` when integrating.

## Use these files

| File | Role |
|------|------|
| `ui_atlas_pack.png` | Packed atlas (transparent, no labels) |
| `ui_atlas_pack_preview.png` | Labeled catalog |
| `slices/*.png` | 54 individual sprites |
| `sheets/ui_pack_buttons.png` | 4×4 square cells, 20px gutters, transparent |
| `sheets/` | Other source grids |
| `_pack_ui_atlas.py` | Re-slice / re-pack (`buttons` = rebuild button grid) |

Circular buttons use **20px** transparent padding on every side — same as HUD `src/ui/hud/btn_restart.png`, enough for `sticker_drop_shadow` (offset 10 + blur 2). Grid cells are equal squares (262×262).

## Inventory

### Buttons (circular sticker)

`btn_sound_on` `btn_sound_off` `btn_movement_direct` `btn_movement_discrete` `btn_restart` `btn_exit` `btn_back` `btn_next` `btn_play` `btn_pause` `btn_settings` `btn_home` `btn_check` `btn_lock` `btn_menu` `btn_blank`

### Frames

`panel_card` — post-battle rounded window (9-slice)  
`banner_question` — question ribbon  
`chip_score` — torn score scrap  
`panel_scalloped` — cloud-edge panel  
`btn_wide` — wide CTA base  
`note_folded` — dog-eared note

### Stamps & icons

`stamp_sun` `stamp_flower` `stamp_cat` `stamp_empty`  
`heart` `heart_empty` `icon_paperclip` `icon_stars`  
`well_circle` `checkbox` `checkbox_checked` `lane_dash`

### Decor doodles

`doodle_sun` `doodle_clouds` `doodle_globe` `doodle_books`  
`doodle_pencil` `doodle_tree` `doodle_school` `doodle_flower`  
`notebook_holes` `doodle_stars` `doodle_airplane` `doodle_paperclip`

### Controls

`toggle_off` `toggle_on` `bar_empty` `bar_fill`  
`speech_bubble` `star_pin` `slider` `tab`

## Style tokens

- Cream fill `#F3E6C8`
- Graphite ink `#2A3340`
- Stamp red / blue / purple `#D85B4E` `#5B8DBE` `#A37CB7`
- Heart `#E85A5A` · win green `#38704D` · star/bar `#F0C94A`
