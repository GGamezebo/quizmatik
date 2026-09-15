class_name PlaneCatalog
extends RefCounted

## Data for the five player planes. UI and combat read this — do not hardcode stats in windows.

const STARTER_ID := "starter"
const ORDER: Array[String] = ["starter", "fast", "green", "red", "gold"]

const DEFS: Dictionary = {
	"starter": {
		"id": "starter",
		"name": "Фиолетовый",
		"tint": Color(0.72, 0.48, 0.98),
		"speed_mult": 0.65,
		"blast_lanes": 0,
		"hint_on_miss": false,
		"gold_cost": 0,
		"exam_container_id": "",
		"badge": "",
	},
	"fast": {
		"id": "fast",
		"name": "Быстрый",
		"tint": Color(1.0, 1.0, 1.0),
		"speed_mult": 1.0,
		"blast_lanes": 0,
		"hint_on_miss": false,
		"gold_cost": 1,
		"exam_container_id": "addition",
		"badge": "быстрый",
	},
	"green": {
		"id": "green",
		"name": "Зелёный",
		"tint": Color(0.52, 0.88, 0.58),
		"speed_mult": 1.15,
		"blast_lanes": 1,
		"hint_on_miss": false,
		"gold_cost": 5,
		"exam_container_id": "subtraction",
		"badge": "бласт 1",
	},
	"red": {
		"id": "red",
		"name": "Красный",
		"tint": Color(0.96, 0.46, 0.42),
		"speed_mult": 1.15,
		"blast_lanes": 1,
		"hint_on_miss": true,
		"gold_cost": 10,
		"exam_container_id": "multiplication",
		"badge": "подсказка",
	},
	"gold": {
		"id": "gold",
		"name": "Золотой",
		"tint": Color(1.0, 0.84, 0.32),
		"speed_mult": 1.3,
		"blast_lanes": 2,
		"hint_on_miss": true,
		"gold_cost": 20,
		"exam_container_id": "division",
		"badge": "бласт 2",
	},
}


static func get_def(plane_id: String) -> Dictionary:
	if DEFS.has(plane_id):
		return DEFS[plane_id]
	return DEFS[STARTER_ID]


static func plane_id_for_exam(container_id: String) -> String:
	if container_id.is_empty():
		return ""
	for plane_id in ORDER:
		if String(DEFS[plane_id].get("exam_container_id", "")) == container_id:
			return plane_id
	return ""


static func atlas_texture() -> Texture2D:
	return preload("res://src/features/plane/planes_atlas_spaced.png")
