extends Answer

class_name HeartBalloon

## Endless battle extra life: popping or ramming it restores one heart, never counts as an answer.
## Shows a heart (`Visual/Heart` + white `HeartOutline`) instead of a number.

@export var heart_frame: int = 0
@export var heart_tint: Color = Color(1.3, 0.95, 1.0)


func _ready() -> void:
	set_balloon_frame(heart_frame)
	super._ready()
	if _sprite:
		_sprite.modulate = heart_tint
	if label:
		label.visible = false
