class_name ShareCardValley
extends VBoxContainer

## One valley on the share card: thumbnail, «done / total», exam stamp once passed; not started = faded.

@export var art_rect: TextureRect
@export var stamp_rect: TextureRect
@export var count_label: Label
@export var faded_alpha: float = 0.45


func setup(container_id: String, completed: int, total: int, exam_stars: int) -> void:
	art_rect.texture = LevelPackArt.get_art(container_id)
	count_label.text = "%d / %d" % [completed, total]
	var stamp := LevelPackArt.get_exam_stamp(exam_stars)
	stamp_rect.texture = stamp
	stamp_rect.visible = stamp != null
	modulate.a = 1.0 if completed > 0 or exam_stars > 0 else faded_alpha
