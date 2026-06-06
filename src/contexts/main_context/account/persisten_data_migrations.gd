class_name PDataMigrator
extends RefCounted

static var migrations: Dictionary = {
	#0: _migrate_0_to_1,
	#1: _migrate_1_to_2,
}

static func migrate(data_dict: Dictionary, from_version: int, to_version: int) -> void:
	var current_v = from_version
	while current_v < to_version:
		var migration_func = migrations[current_v]
		migration_func.call(data_dict)
		current_v += 1
	print("Migration passed successful: ", current_v)


#static func _migrate_0_to_1(data: Dictionary) -> void:
	#if data.has("statistics") and not data["statistics"].has("coins_earned"):
		#data["statistics"]["coins_earned"] = 0
#
#static func _migrate_1_to_2(data: Dictionary) -> void:
	#if data.has("levels"):
		#data["levels"]["subtraction"] = {
			#"completed_levels": {},
			#"exam_passed": true,
		#}
