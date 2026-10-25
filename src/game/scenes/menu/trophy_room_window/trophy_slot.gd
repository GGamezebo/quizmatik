class_name TrophySlot
extends VBoxContainer

## Award slot asks for its hint (magister cup not earned yet: pulses, tap → rules).
signal ev_hint_pressed

const _LOCKED_TROPHY_EXTRA_DOWN := 3.0

@export var pedestal_rect: TextureRect
@export var trophy_rect: TextureRect
@export var name_label: Label
@export var progress_label: Label
## Invisible tap target over the cup; shown only with `initialize_award(..., with_hint = true)`.
@export var hint_button: BaseButton
@export var pulse_scale: float = 1.12
## Shelf tag under the cup: the valley record battle time (keeps its place while hidden — cups stay aligned).
@export var record_tag: Control
@export var record_label: Label
@export var pulse_period: float = 1.2


func initialize(
	container_id: String,
	is_unlocked: bool,
	completed_count: int,
	total_count: int,
) -> void:
	if name_label:
		name_label.text = ValleyTrophyArt.get_short_name(container_id)
	if progress_label:
		if is_unlocked:
			progress_label.text = "%d/%d" % [completed_count, total_count]
		else:
			progress_label.text = "—/%d" % total_count
	if trophy_rect:
		trophy_rect.texture = (
			ValleyTrophyArt.get_trophy(container_id)
			if is_unlocked
			else ValleyTrophyArt.get_locked_trophy()
		)
		trophy_rect.modulate = Color(1, 1, 1, 1)
		if not is_unlocked:
			trophy_rect.offset_top += _LOCKED_TROPHY_EXTRA_DOWN
			trophy_rect.offset_bottom += _LOCKED_TROPHY_EXTRA_DOWN
	if pedestal_rect:
		pedestal_rect.texture = AchievementUiArt.PEDESTAL
		pedestal_rect.modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.78, 0.78, 0.8, 0.75)


## Non-valley award (magister): own art and name; locked = the shared locked silhouette, «—».
## `with_hint`: the cup pulses and a tap emits `ev_hint_pressed` (rules) — only while not earned.
func initialize_award(award_name: String, award_texture: Texture2D, is_unlocked: bool, with_hint: bool = false) -> void:
	if name_label:
		name_label.text = award_name
	if progress_label:
		progress_label.text = "10:00" if is_unlocked else "—"
	if trophy_rect:
		trophy_rect.texture = award_texture if is_unlocked else ValleyTrophyArt.get_locked_trophy()
		if not is_unlocked:
			trophy_rect.offset_top += _LOCKED_TROPHY_EXTRA_DOWN
			trophy_rect.offset_bottom += _LOCKED_TROPHY_EXTRA_DOWN
	if pedestal_rect:
		pedestal_rect.texture = AchievementUiArt.PEDESTAL
		pedestal_rect.modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.78, 0.78, 0.8, 0.75)
	if hint_button:
		hint_button.visible = with_hint
		if with_hint and not hint_button.pressed.is_connected(ev_hint_pressed.emit):
			hint_button.pressed.connect(ev_hint_pressed.emit)
	if with_hint and trophy_rect:
		_pulse.call_deferred()


## Valley record battle best time on the shelf tag; `seconds` < 0 = no record battle here (tag hidden).
func set_record(seconds: int) -> void:
	if record_tag == null:
		return
	record_tag.modulate.a = 1.0 if seconds >= 0 else 0.0
	if record_label and seconds >= 0:
		record_label.text = ProgressStatistics.format_clock(seconds) if seconds > 0 else "—"


func _pulse() -> void:
	trophy_rect.pivot_offset = trophy_rect.size * Vector2(0.5, 1.0)
	var half: float = pulse_period * 0.5
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(trophy_rect, "scale", Vector2.ONE * pulse_scale, half)
	tween.tween_property(trophy_rect, "scale", Vector2.ONE, half)
