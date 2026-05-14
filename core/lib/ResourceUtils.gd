class_name ResourceUtils
extends RefCounted

static func update_resource(target: Resource, source: Resource) -> void:
	if not target or not source:
		push_error("Resource update failed: Target or Source is null.")
		return
	
	if target.get_script() != source.get_script():
		push_warning("Resource update: Target and Source scripts mismatch.")

	# Iterate through all object properties
	for property in source.get_property_list():
		var prop_name: String = property["name"]
		var prop_usage: int = property["usage"]

		# Filter properties:
		# 1. PROPERTY_USAGE_STORAGE: include only exported or persistent variables
		# 2. Skip "script" and "resource_path" to avoid breaking object logic or identity
		if prop_usage & PROPERTY_USAGE_STORAGE and prop_name != "script" and prop_name != "resource_path":
			var value = source.get(prop_name)
			
			if value == null:
				target.set(prop_name, null)
				continue

			# Handle reference types to ensure deep copy where necessary
			if value is Array or value is Dictionary:
				target.set(prop_name, value.duplicate(true))
			elif value is Resource:
				# Duplicate nested resources to avoid shared state
				target.set(prop_name, value.duplicate(true))
			else:
				# Atomic types (int, float, bool, Vector3, etc.) are passed by value
				target.set(prop_name, value)
	
	# Notify all subscribers that the data has been updated
	target.emit_changed()
