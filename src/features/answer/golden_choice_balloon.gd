extends BonusBalloon

class_name GoldenChoiceBalloon

## Final pick of the golden flight: a golden balloon showing only a coin and «?».
## `reveal(true)` = the picked one (grows with «+N», then pops); `reveal(false)` shows what the others held, fades.

@export var mystery_text: String = "?"
@export var picked_color: Color = Color(0.55, 0.38, 0.05)
@export var missed_color: Color = Color(0.35, 0.38, 0.45)
## How long the revealed amounts stay readable before pop / fade.
@export var show_picked_sec: float = 0.7
@export var show_missed_sec: float = 1.0


func _ready() -> void:
	super._ready()
	if label:
		label.visible = true
		label.text = mystery_text


func reveal(picked: bool) -> void:
	if label:
		label.text = ("+%d" % gold_amount) if picked else str(gold_amount)
		label.label_settings.font_color = picked_color if picked else missed_color
	_disable_collision()
	var tween := create_tween()
	if picked:
		tween.tween_property(self, "scale", scale * 1.3, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(show_picked_sec)
		tween.tween_callback(take_damage.bind(true))
	else:
		tween.tween_interval(show_missed_sec)
		tween.tween_callback(take_damage.bind(false))
