# SaveData.gd
class_name SaveData
extends Save

static func  CURRENT_SAVE_VERSION() -> int:
	return 6

static var _migrations: Dictionary = {
	1: _migrate_1_to_2,
	2: _migrate_2_to_3,
	3: _migrate_3_to_4,
	4: _migrate_4_to_5,
	5: _migrate_5_to_6,
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


## v4: tutorial chapters. Profiles that already won a battle skip the whole tutorial.
static func _migrate_3_to_4(data: Dictionary) -> void:
	var profiles: Variant = data.get("profiles", {})
	if not (profiles is Dictionary):
		return
	for profile_id in profiles as Dictionary:
		var profile: Variant = profiles[profile_id]
		if not (profile is Dictionary):
			continue
		var state: Dictionary = profile.get("state", {}) if profile.get("state", {}) is Dictionary else {}
		var stats: Variant = profile.get("statistics", {})
		if stats is Dictionary and int(stats.get("total_wins", 0)) > 0:
			state["tutorial_completed"] = true
		if not state.has("tutorial_steps"):
			state["tutorial_steps"] = {}
		profile["state"] = state


## v5: per-profile weak examples (`mistakes.weights` / `misses`) start empty.
static func _migrate_4_to_5(data: Dictionary) -> void:
	var profiles: Variant = data.get("profiles", {})
	if not (profiles is Dictionary):
		return
	for profile_id in profiles as Dictionary:
		var profile: Variant = profiles[profile_id]
		if profile is Dictionary and not (profile.get("mistakes", null) is Dictionary):
			profile["mistakes"] = {"weights": {}, "misses": {}}


## v6: per-valley `unlocked` override (dev lab «open all valleys»); existing valleys stay closed.
static func _migrate_5_to_6(data: Dictionary) -> void:
	var profiles: Variant = data.get("profiles", {})
	if not (profiles is Dictionary):
		return
	for profile_id in profiles as Dictionary:
		var profile: Variant = profiles[profile_id]
		if not (profile is Dictionary) or not (profile.get("levels", null) is Dictionary):
			continue
		var levels: Dictionary = profile["levels"]
		for container_id in levels:
			var container: Variant = levels[container_id]
			if container is Dictionary and not container.has("unlocked"):
				container["unlocked"] = false
