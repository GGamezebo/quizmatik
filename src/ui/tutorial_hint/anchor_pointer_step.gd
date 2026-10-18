class_name AnchorPointerStep
extends Resource

## One pointer target for `AnchorPointer`: which anchor, what to say, where the arrow touches.

@export var anchor_id: String
@export_multiline var text: String
## Point on the anchor rect (0..1) the arrow tip touches.
@export var anchor_point: Vector2 = Vector2(0.5, 0.0)
@export var points_up: bool = false
## Non-empty → hint shows a confirm button; `AnchorPointer.ev_step_confirmed` fires on press.
@export var button_text: String = ""
## Host's CanvasLayer for the hint while this step shows (above overlays); 0 = host default.
@export var layer: int = 0

@export_group("Spotlight")
## Dim the screen around the anchor (only the hole stays clickable).
@export var dim: bool = true
## Hole = this sub-rect (0..1) of the anchor rect, grown by `hole_margin`.
@export var hole_rect: Rect2 = Rect2(0, 0, 1, 1)
@export var hole_margin: float = 12.0
