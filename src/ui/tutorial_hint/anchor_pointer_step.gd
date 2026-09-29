class_name AnchorPointerStep
extends Resource

## One pointer target for `AnchorPointer`: which anchor, what to say, where the arrow touches.

@export var anchor_id: String
@export_multiline var text: String
## Point on the anchor rect (0..1) the arrow tip touches.
@export var anchor_point: Vector2 = Vector2(0.5, 0.0)
@export var points_up: bool = false
