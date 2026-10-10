class_name GooglePlayContext
extends PlatformContext

## `Platform/Android/GooglePlay`: Play-specific hooks. Purchases live in child `GooglePlayShop`
## (opened unless `no_monetization`).


func _enter() -> void:
	open_shop()
