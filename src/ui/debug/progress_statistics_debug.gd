extends Control

@export var pdata: PDataProgress
@export var stats_label: Label
@export var refresh_interval: float = 0.5

var _refresh_accumulator: float = 0.0

func _ready() -> void:
	if not OS.has_feature("editor"):
		queue_free()
		return
	_refresh()

func _process(delta: float) -> void:
	_refresh_accumulator += delta
	if _refresh_accumulator < refresh_interval:
		return
	_refresh_accumulator = 0.0
	_refresh()

func _refresh() -> void:
	if pdata == null or stats_label == null:
		return
	stats_label.text = ProgressStatistics.build_debug_text(pdata.progress)
