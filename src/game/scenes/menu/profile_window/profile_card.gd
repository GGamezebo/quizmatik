class_name ProfileCard
extends Button

## Pilot polaroid in the profile switcher: plane photo + name + difficulty; active one is checked.

@export var photo: TextureRect
@export var name_label: Label
@export var difficulty_label: Label
@export var active_badge: Control
@export var difficulty_titles: Dictionary = {
	"easy": "Легко",
	"normal": "Нормально",
	"hard": "Сложно",
}

var profile_id: String = ""


func setup(id: String, display_name: String, difficulty: String, plane_id: String, is_active: bool) -> void:
	profile_id = id
	if name_label:
		name_label.text = ProfileController.display_name_or_default(display_name)
	if difficulty_label:
		difficulty_label.text = String(difficulty_titles.get(difficulty, difficulty_titles["normal"]))
	if photo:
		PlaneCatalog.apply_preview(photo, plane_id)
	if active_badge:
		active_badge.visible = is_active
	disabled = is_active
	mouse_default_cursor_shape = Control.CURSOR_ARROW if is_active else Control.CURSOR_POINTING_HAND
