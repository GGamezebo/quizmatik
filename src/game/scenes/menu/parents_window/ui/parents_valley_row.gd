class_name ParentsValleyRow
extends HBoxContainer

## One valley in the parents report: thumbnail, name, «12 / 20» (or key + «В полной версии»), exam stamp.

@export var art_rect: TextureRect
@export var name_label: Label
@export var status_label: Label
@export var key_icon: Control
@export var stamp_rect: TextureRect

const PAID_TEXT := "В полной версии"


func setup(container_id: String, title: String, completed: int, total: int, exam_stars: int, is_paywalled: bool) -> void:
	art_rect.texture = LevelPackArt.get_art(container_id)
	name_label.text = title
	key_icon.visible = is_paywalled
	status_label.text = PAID_TEXT if is_paywalled else "%d / %d" % [completed, total]
	var stamp := LevelPackArt.get_exam_stamp(exam_stars)
	stamp_rect.texture = stamp
	stamp_rect.modulate.a = 1.0 if stamp != null else 0.0
