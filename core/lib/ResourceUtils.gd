class_name ResourceUtils
extends RefCounted

const USAGE_PROPERY = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE

static func update_resource(target: Resource, source: Resource) -> void:
	if not target or not source:
		push_error("Resource update failed: Target or Source is null.")
		return
	
	# Different scripts mean properties cannot be copied safely — abort early.
	if target.get_script() != source.get_script():
		push_error("Resource update failed: Target and Source scripts mismatch. Cannot override.")
		return

	# Properties that must not be overwritten
	var property_blacklist = [
		"script", 
		"resource_path", 
		"resource_name", 
		"resource_local_to_scene"
	]

	# Iterate over source properties
	for property in source.get_property_list():
		var prop_name: String = property["name"]
		var prop_usage: int = property["usage"]

		# 1. Check STORAGE flag
		# 2. Skip blacklisted properties
		if (prop_usage & USAGE_PROPERY) and not (prop_name in property_blacklist):
			
			# Safety: skip if target does not have this property
			if not prop_name in target:
				continue
				
			var value = source.get(prop_name)
			
			if value == null:
				target.set(prop_name, null)
				continue

			# Handle value types
			if value is Array or value is Dictionary:
				target.set(prop_name, value.duplicate(true))
			elif value is Resource:
				# Option A: deep duplicate (independent sub-resource copy)
				target.set(prop_name, value.duplicate(true))
				
				# Option B: for recursive nested resource override, use:
				# var target_sub_res = target.get(prop_name)
				# if target_sub_res and target_sub_res.get_script() == value.get_script():
				#     update_resource(target_sub_res, value)
				# else:
				#     target.set(prop_name, value.duplicate(true))
			else:
				# Atomic types (int, float, Vector, etc.)
				target.set(prop_name, value)
	
	# Notify listeners of changes
	target.emit_changed()
	
static func reset_resource_to_default(resource: Resource, default_resource: Resource) -> void:
	update_resource(resource, default_resource)
	
static func save_resource_to_disk(resource: Resource, path: String) -> void:
	var error = ResourceSaver.save(resource, path)
	if error == OK:
		print("resource %s is saved " % path)
	else:
		print("Error %s while saving resource %s" % [str(error), path])

static func hard_reset_resource(path: String, resource: Resource, default_resource: Resource) -> void:
	reset_resource_to_default(resource, default_resource)
	save_resource_to_disk(resource, path)
