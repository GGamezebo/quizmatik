class_name ProfileController
extends Node

signal ev_profiles_changed
signal ev_plane_unlocked(plane_id: String)

const MAX_PROFILES: int = 4
const DEFAULT_NAME: String = "Пилот"

@export var pdata: PData
@export var root_events: RootEvents


static func find_in_tree(tree: SceneTree) -> ProfileController:
	if tree == null:
		return null
	return tree.root.find_child("ProfileController", true, false) as ProfileController


func _save_manager() -> SaveManager:
	var parent := get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null("SaveManager") as SaveManager
		if sibling != null:
			return sibling
	return get_tree().root.find_child("SaveManager", true, false) as SaveManager


func save() -> void:
	root_events.ev_save_progress.emit()
	# Deferred: UI must not free the button/card still in this call stack.
	if root_events != null:
		root_events.ev_profiles_changed.emit.call_deferred()
	ev_profiles_changed.emit.call_deferred()


func has_profiles() -> bool:
	var sm := _save_manager()
	if sm == null:
		return not String(pdata.profile_id).is_empty()
	return sm.has_profiles()


func profile_count() -> int:
	var sm := _save_manager()
	if sm == null:
		return 1 if has_profiles() else 0
	return sm.profiles.size()


func can_create() -> bool:
	return profile_count() < MAX_PROFILES


func can_delete() -> bool:
	return profile_count() > 1


func list_summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var sm := _save_manager()
	if sm == null:
		if pdata != null and not pdata.profile_id.is_empty():
			result.append(_summary_from_pdata(pdata))
		return result
	sm._stash_live()
	for profile_id in sm.profiles:
		var raw: Variant = sm.profiles[profile_id]
		if raw is Dictionary:
			result.append(_summary_from_dict(profile_id, raw))
	return result


func active_profile_id() -> String:
	var sm := _save_manager()
	if sm != null:
		return sm.active_profile_id
	return pdata.profile_id


func create_profile(display_name: String, difficulty: StringName = BattleDifficulty.NORMAL) -> String:
	if not can_create():
		return ""
	var unique := unique_name(display_name)
	var sm := _save_manager()
	if sm != null:
		sm._stash_live()
	var profile_id := _next_id()
	pdata.reset_to_defaults()
	pdata.profile_id = profile_id
	pdata.display_name = unique
	pdata.difficulty = String(BattleDifficulty.sanitize(difficulty))
	pdata.gold = 0
	pdata.equipped_plane_id = PlaneCatalog.STARTER_ID
	pdata.unlocked_planes = [PlaneCatalog.STARTER_ID]
	if sm != null:
		sm.active_profile_id = profile_id
		sm.profiles[profile_id] = pdata.to_dict()
	save()
	return profile_id


func switch_profile(profile_id: String) -> bool:
	var sm := _save_manager()
	if sm == null or not sm.profiles.has(profile_id):
		return false
	if sm.active_profile_id == profile_id:
		return true
	sm._stash_live()
	sm.active_profile_id = profile_id
	pdata.apply_dict(sm.profiles[profile_id])
	save()
	return true


func wipe_all_profiles() -> void:
	var sm := _save_manager()
	if sm != null:
		sm.wipe_all_profiles()
	elif pdata != null:
		pdata.reset_to_defaults()
	if root_events != null:
		root_events.ev_profiles_changed.emit.call_deferred()
	ev_profiles_changed.emit.call_deferred()


func delete_profile(profile_id: String) -> bool:
	if not can_delete():
		return false
	var sm := _save_manager()
	if sm == null or not sm.profiles.has(profile_id):
		return false
	var was_active := sm.active_profile_id == profile_id
	sm.profiles.erase(profile_id)
	if was_active:
		var next_id := String(sm.profiles.keys()[0])
		sm.active_profile_id = next_id
		pdata.apply_dict(sm.profiles[next_id])
	save()
	return true


func rename_profile(display_name: String) -> void:
	pdata.display_name = display_name_or_default(display_name)
	save()


func set_difficulty(difficulty: StringName) -> void:
	var id := String(BattleDifficulty.sanitize(difficulty))
	if pdata == null or pdata.difficulty == id:
		return
	pdata.difficulty = id
	save()


## Campaign valleys only; practice picks its own difficulty.
func valley_difficulty() -> StringName:
	if pdata == null:
		return BattleDifficulty.NORMAL
	return BattleDifficulty.sanitize(StringName(pdata.difficulty))


## Name not used by other pilots: «Пилот» → «Пилот 2», «Пилот 3», …
func unique_name(display_name: String) -> String:
	var base := display_name_or_default(display_name)
	var taken: Dictionary = {}
	for summary in list_summaries():
		taken[String(summary.get("name", "")).to_lower()] = true
	if not taken.has(base.to_lower()):
		return base
	var index := 2
	# «Пилот 2» taken → continue the counter («Пилот 3»), not «Пилот 2 2».
	var numbered := RegEx.create_from_string("^(.*\\S) (\\d+)$").search(base)
	if numbered != null:
		base = numbered.get_string(1)
		index = maxi(2, numbered.get_string(2).to_int() + 1)
	while taken.has(("%s %d" % [base, index]).to_lower()):
		index += 1
	return "%s %d" % [base, index]


## Empty → `DEFAULT_NAME` in the current UI language (typed names are never translated).
static func display_name_or_default(display_name: String) -> String:
	var clean := display_name.strip_edges()
	return String(TranslationServer.translate(DEFAULT_NAME)) if clean.is_empty() else clean


func add_gold(amount: int) -> void:
	if amount == 0:
		return
	pdata.gold = maxi(0, pdata.gold + amount)
	save()


func equipped_plane_id() -> String:
	if pdata == null or pdata.equipped_plane_id.is_empty():
		return PlaneCatalog.STARTER_ID
	return pdata.equipped_plane_id


func is_plane_unlocked(plane_id: String) -> bool:
	if plane_id == PlaneCatalog.STARTER_ID:
		return true
	if pdata == null:
		return false
	return pdata.unlocked_planes.has(plane_id)


func unlock_plane(plane_id: String) -> bool:
	if plane_id.is_empty() or not PlaneCatalog.DEFS.has(plane_id):
		return false
	if is_plane_unlocked(plane_id):
		return false
	pdata.unlocked_planes.append(plane_id)
	save()
	ev_plane_unlocked.emit(plane_id)
	return true


func equip_plane(plane_id: String) -> bool:
	if not is_plane_unlocked(plane_id):
		return false
	pdata.equipped_plane_id = plane_id
	save()
	return true


func try_buy_plane(plane_id: String) -> bool:
	if is_plane_unlocked(plane_id):
		return false
	var def: Dictionary = PlaneCatalog.get_def(plane_id)
	var cost: int = int(def.get("gold_cost", 0))
	if cost <= 0 or pdata.gold < cost:
		return false
	pdata.gold -= cost
	pdata.unlocked_planes.append(plane_id)
	pdata.equipped_plane_id = plane_id
	save()
	ev_plane_unlocked.emit(plane_id)
	return true


func _next_id() -> String:
	var sm := _save_manager()
	var index := 1
	while true:
		var candidate := "profile_%d" % index
		if sm == null or not sm.profiles.has(candidate):
			return candidate
		index += 1
	return "profile_1"


func _summary_from_pdata(live: PData) -> Dictionary:
	return {
		"id": live.profile_id,
		"name": display_name_or_default(live.display_name),
		"difficulty": live.difficulty,
		"gold": live.gold,
		"equipped_plane_id": live.equipped_plane_id,
	}


func _summary_from_dict(profile_id: String, data: Dictionary) -> Dictionary:
	return {
		"id": profile_id,
		"name": display_name_or_default(String(data.get("name", ""))),
		"difficulty": String(BattleDifficulty.sanitize(StringName(data.get("difficulty", "normal")))),
		"gold": int(data.get("gold", 0)),
		"equipped_plane_id": String(data.get("equipped_plane_id", PlaneCatalog.STARTER_ID)),
	}
