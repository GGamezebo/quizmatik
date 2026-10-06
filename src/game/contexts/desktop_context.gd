class_name DesktopContext
extends PlatformContext

## `Platform/Desktop`: generic PC hooks (Windows / Linux / macOS, incl. editor). Store branch by export feature.


func _enter() -> void:
	if OS.has_feature("steam"):
		open_child("ev.open_steam")
