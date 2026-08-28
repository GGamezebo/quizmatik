class_name TrophySlot
extends VBoxContainer

const _LOCKED_TROPHY_EXTRA_DOWN := 3.0

@export var pedestal_rect: TextureRect
@export var trophy_rect: TextureRect
@export var name_label: Label
@export var progress_label: Label


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
