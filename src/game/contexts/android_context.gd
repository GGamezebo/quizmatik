class_name AndroidContext
extends PlatformContext

## `Platform/Android`: generic Android hooks (any store). Store branch chosen by export custom feature.


func _enter() -> void:
	if OS.has_feature("google_play"):
		open_child("ev.open_google_play")
