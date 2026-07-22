extends Control

@export var pdata: PDataProgress
@export var stats_list: VBoxContainer
@export var stat_row_scene: PackedScene


func on_window_enter() -> void:
	_rebuild_stats()


func _rebuild_stats() -> void:
	if pdata == null or stats_list == null or stat_row_scene == null:
		return

	for child in stats_list.get_children():
		stats_list.remove_child(child)
		child.free()

	var stats: Dictionary = pdata.progress.get("statistics", {})
	for row_data in ProgressStatistics.DISPLAY_ROWS:
		var key: String = row_data[0]
		var title: String = row_data[1]
		var row: Control = stat_row_scene.instantiate()
		var title_label := row.get_node("Title") as Label
		var value_label := row.get_node("Value") as Label
		title_label.text = title
		value_label.text = ProgressStatistics.format_stat_value(key, stats.get(key, 0))
		stats_list.add_child(row)
