class_name AndroidContext
extends PlatformContext

## `Platform/Android`: generic Android hooks (any store). Store branch chosen by export custom feature.
## Feature `dev_shop` (preset `Android-Test-Shop`, never release): fake Play store `AndroidDevShop` to check
## paid valleys / paywall on a phone without Google Play.


func _enter() -> void:
	if OS.has_feature("google_play"):
		open_child("ev.open_google_play")
	elif OS.has_feature("rustore"):
		open_child("ev.open_rustore")
	elif OS.has_feature("dev_shop"):
		open_child("ev.open_dev_shop", {"dev_shop_model": "play"})
