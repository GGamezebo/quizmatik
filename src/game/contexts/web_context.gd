class_name WEBContext
extends HfsmBoundEntity

## Generic HTML5 platform hooks. Opens nested Yandex when export feature is set.


func _init(_data: Dictionary = {}) -> void:
	print("WEBContext _init")
	
	if OS.has_feature("yandex_games"):
		add_event("ev.open_yandex", _data)
