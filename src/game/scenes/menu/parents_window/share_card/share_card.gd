class_name ShareCard
extends Control

## «Наш пилот» picture for the parents' share sheet (1080×1080, rendered off-screen by `ParentsWindow`):
## the pilot's plane in its paint over the pencil valley, three numbers and the valleys with exam stamps.
## Only good news and no personal data: never the pilot's name, never weak examples.

@export var plane_rect: TextureRect
@export var solved_label: Label
@export var levels_label: Label
@export var time_label: Label
@export var valley_row: HBoxContainer
@export var valley_scene: PackedScene


func setup(plane_id: String, paint: PaintItem, solved: int, levels_done: int, time_text: String) -> void:
	PlaneCatalog.apply_preview(plane_rect, plane_id, paint)
	solved_label.text = str(solved)
	levels_label.text = str(levels_done)
	time_label.text = time_text
	for child in valley_row.get_children():
		valley_row.remove_child(child)
		child.free()


func add_valley(container_id: String, completed: int, total: int, exam_stars: int) -> void:
	var valley: ShareCardValley = valley_scene.instantiate()
	valley_row.add_child(valley)
	valley.setup(container_id, completed, total, exam_stars)
