class_name RuStoreContext
extends PlatformContext

## `Platform/Android/RuStore`: RuStore build (export feature `rustore`, preset `Android-RuStore`) for players
## in Russia, where Play Billing doesn't work. Purchases in child `RuStoreShop` (opened unless `no_monetization`).
## No cloud save (save stays local). Russian-only UI.
## Share (`PlatformServices.can_share`): system share sheet with the RuStore page link via `AndroidShare`.

const LANGUAGES: PackedStringArray = [GameLocale.RU]
const SHARE_URL := "https://www.rustore.ru/catalog/app/" + PlayRating.PLAY_PACKAGE

var _share: AndroidShare = AndroidShare.new()
var _listener: EventListener = EventListener.new()


func _enter() -> void:
	if services != null:
		services.set_languages(LANGUAGES)
		_listener.add(services.ev_request_share, _on_share)
		services.set_share(true)
	open_shop()

func deinit() -> void:
	_listener.deinit()
	if services != null:
		services.set_languages([])
		services.set_share(false)
	super.deinit()


func _on_share(placement: StringName, text: String, image_path: String) -> void:
	_share.share(text, AndroidShare.tagged_url(SHARE_URL, placement), image_path)
