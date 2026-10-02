extends Answer

class_name BonusBalloon

## Golden balloon flying ahead of a round: popping it grants gold, never counts as an answer.

@export var gold_amount: int = 1
@export var label_text: String = "+1"
## Yellow frame of `balloons_atlas` (also tints the pop VFX).
@export var gold_frame: int = 1
@export var gold_tint: Color = Color(1.25, 1.1, 0.55)


func _ready() -> void:
	set_balloon_frame(gold_frame)
	super._ready()
	if _sprite:
		_sprite.modulate = gold_tint
	if label:
		label.text = label_text
