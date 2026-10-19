class_name RuStoreContext
extends PlatformContext

## `Platform/Android/RuStore`: RuStore build (export feature `rustore`, preset `Android-RuStore`) for players
## in Russia, where Play Billing doesn't work. Purchases in child `RuStoreShop` (opened unless `no_monetization`).
## No cloud save (save stays local). Russian-only UI.

const LANGUAGES: PackedStringArray = [GameLocale.RU]


func _enter() -> void:
	if services != null:
		services.set_languages(LANGUAGES)
	open_shop()

func deinit() -> void:
	if services != null:
		services.set_languages([])
	super.deinit()
