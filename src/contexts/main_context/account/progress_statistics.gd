class_name ProgressStatistics
extends RefCounted

static func format_stat_value(key: String, value: Variant) -> String:
	if key.ends_with("_time") and value is float:
		return format_duration(float(value))
	return str(value)


static func format_duration(seconds: float) -> String:
	var total_seconds: int = maxi(0, int(seconds))
	var minutes: int = int(total_seconds / 60.0)
	var secs: int = total_seconds % 60
	return "%d:%02d (%.1fs)" % [minutes, secs, seconds]


static func build_debug_text(progress: Dictionary) -> String:
	var stats: Dictionary = progress["statistics"]
	var lines: PackedStringArray = ["Statistics"]
	var keys: Array = stats.keys()
	keys.sort()
	for key in keys:
		lines.append("%s: %s" % [key, format_stat_value(str(key), stats[key])])
	return "\n".join(lines)
