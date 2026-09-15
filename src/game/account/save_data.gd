# SaveData.gd
class_name SaveData
extends Save

static func  CURRENT_SAVE_VERSION() -> int:
	return 3
	
static var _migrations: Dictionary = {
	1: _migrate_1_to_2,
	2: _migrate_2_to_3,
}

func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
	var d = data.duplicate(true)
	_migrate(d, from_version)
	return d

static func _migrate(data_dict: Dictionary, from_version: int) -> void:
	var current_v = from_version
	while current_v < CURRENT_SAVE_VERSION():
		var migration_func = _migrations[current_v]
		migration_func.call(data_dict)
		current_v += 1
	print("Migration passed successful: ", current_v)


static func _migrate_1_to_2(data: Dictionary) -> void:
	if not data.has("trophies") or not (data["trophies"] is Dictionary):
		data["trophies"] = {"unlocked": {}}

	var trophies: Dictionary = data["trophies"]
	if not trophies.has("unlocked") or not (trophies["unlocked"] is Dictionary):
		trophies["unlocked"] = {}

	var unlocked: Dictionary = trophies["unlocked"]
	var levels: Variant = data.get("levels", {})
	if levels is Dictionary:
		for container_id in levels as Dictionary:
			var container: Variant = levels[container_id]
			if container is Dictionary and bool(container.get("exam_passed", false)):
				unlocked[String(container_id)] = true


static func _migrate_2_to_3(data: Dictionary) -> void:
	if data.has("profiles"):
		return
	var has_levels := data.has("levels")
	var payload: Dictionary = data.duplicate(true)
	data.clear()
	if not has_levels:
		data["active_profile_id"] = ""
		data["profiles"] = {}
		return
	var profile_id := "profile_1"
	payload["profile_id"] = profile_id
	payload["name"] = String(payload.get("name", "Пилот"))
	if String(payload.get("name", "")).is_empty():
		payload["name"] = "Пилот"
	payload["gender"] = String(payload.get("gender", "boy"))
	if payload["gender"] != "girl":
		payload["gender"] = "boy"
	payload["age"] = int(payload.get("age", 8))
	payload["gold"] = int(payload.get("gold", 0))
	payload["equipped_plane_id"] = String(payload.get("equipped_plane_id", "starter"))
	if not payload.has("unlocked_planes"):
		payload["unlocked_planes"] = ["starter"]
	data["active_profile_id"] = profile_id
	data["profiles"] = {profile_id: payload}
