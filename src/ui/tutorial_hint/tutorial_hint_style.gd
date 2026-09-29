class_name TutorialHintStyle
extends Resource

## Look of a `TutorialHint` (cloud, arrow, text). Neutral defaults; each project ships its own `.tres`.
## Font face comes from the parent theme; color/size here override it only when set.

@export_group("Cloud")
@export var fill_color: Color = Color(1.0, 1.0, 1.0)
## Alpha at the cloud rim → in the text area (soft, semi-transparent edge).
@export_range(0.0, 1.0) var edge_alpha: float = 0.45
@export_range(0.0, 1.0) var core_alpha: float = 0.85
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.7)
@export var outline_width: float = 3.0

@export_group("Arrow")
@export var arrow_color: Color = Color(1.0, 1.0, 1.0)
@export var arrow_outline_color: Color = Color(0.0, 0.0, 0.0)

@export_group("Text")
@export var font_color: Color = Color(0.0, 0.0, 0.0)
## 0 → keep the theme's font size.
@export var font_size: int = 0
## Extra px between wrapped lines (negative tightens tall fonts).
@export var line_spacing: int = 0
