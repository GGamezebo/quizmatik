extends HBoxContainer

@export var icon_rect: TextureRect
@export var title_label: Label
@export var value_label: Label


func initialize(key: String, title: String, value_text: String) -> void:
	if icon_rect:
		icon_rect.texture = AchievementUiArt.get_stat_icon(key)
	if title_label:
		title_label.text = title
	if value_label:
		value_label.text = value_text
