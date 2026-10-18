class_name RuStoreContext
extends PlatformContext

## `Platform/Android/RuStore`: RuStore build (export feature `rustore`, preset `Android-RuStore`) for players
## in Russia, where Play Billing doesn't work. Purchases in child `RuStoreShop` (opened unless `no_monetization`).
## No cloud save (save stays local).


func _enter() -> void:
	open_shop()
