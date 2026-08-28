extends VBoxContainer

@export var icon_rect: TextureRect
@export var title_label: Label
@export var subtitle_label: Label


func initialize(key: String, title: String, subtitle: String) -> void:
	if icon_rect:
		icon_rect.texture = AchievementUiArt.get_stat_icon(key)
	if title_label:
		title_label.text = title
	if subtitle_label:
		subtitle_label.text = subtitle
