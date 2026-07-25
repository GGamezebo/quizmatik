# SaveData.gd
class_name SaveData
extends Save

static func  CURRENT_SAVE_VERSION() -> int:
	return 1
	
static var _migrations: Dictionary = {
	#1: _migrate_1_to_2,
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


#static func _migrate_1_to_2(_data: Dictionary) -> void:
	#print("Version 2")
