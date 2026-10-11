class_name CloudSaveCodec
extends RefCounted

## Platform-cloud copy of the save: JSON text of the SaveManager envelope
## `{ version, saved_at, active_profile_id, profiles }`. Pure functions, no I/O.

## Yandex `player.setData` limit is 200 KB; stay below it.
const MAX_BYTES := 190000


static func encode(envelope: Dictionary) -> String:
	var body := envelope.duplicate()
	body["version"] = SaveData.CURRENT_SAVE_VERSION()
	return JSON.stringify(body)


## Cloud text → envelope migrated to the current schema; `{}` when empty / corrupt / written by a newer game.
static func decode(json: String) -> Dictionary:
	if json.is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(json) != OK or not (parser.data is Dictionary):
		return {}
	var envelope := parser.data as Dictionary
	var version := int(envelope.get("version", 1))
	if version > SaveData.CURRENT_SAVE_VERSION():
		push_warning("CloudSaveCodec: cloud save v%d is newer than game v%d — ignored" % [version, SaveData.CURRENT_SAVE_VERSION()])
		return {}
	if not (envelope.get("profiles", {}) is Dictionary):
		return {}
	var migrated := SaveData.migrate_envelope(envelope, version)
	migrated["saved_at"] = int(envelope.get("saved_at", 0))
	return migrated


static func is_too_big(json: String) -> bool:
	return json.to_utf8_buffer().size() > MAX_BYTES
