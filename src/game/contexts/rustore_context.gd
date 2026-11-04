class_name RuStoreContext
extends PlatformContext

## `Platform/Android/RuStore`: RuStore build (export feature `rustore`, preset `Android-RuStore`) for players
## in Russia. No monetization at all: `RuStoreShop` is never opened (no ads, no purchases, every valley open,
## no `App/Monetization`); shop code stays only for a possible later paid build. No cloud save (save stays
## local). Russian-only UI.
## Child `RuStoreGreeting` (scene `rustore_greeting`): «Привет от разработчиков» card with the studio's channels,
## pops up by itself on the post-battle screen of the first win after 20 battles.
## Rating (`PlatformServices.can_rate`): RuStore page (no in-app review sheet — `ev_request_review` unanswered).
## Share (`PlatformServices.can_share`): system share sheet with the RuStore page link via `AndroidShare`.

const LANGUAGES: PackedStringArray = [GameLocale.RU]
const SHARE_URL := "https://www.rustore.ru/catalog/app/" + PlayRating.PLAY_PACKAGE

var _share: AndroidShare = AndroidShare.new()
var _listener: EventListener = EventListener.new()


func _enter() -> void:
	if services != null:
		services.set_languages(LANGUAGES)
		_listener.add(services.ev_request_rate_page, _on_rate_page)
		services.set_rate(true)
		_listener.add(services.ev_request_share, _on_share)
		services.set_share(true)
	open_child("ev.open_rustore_greeting")

func deinit() -> void:
	_listener.deinit()
	if services != null:
		services.set_languages([])
		services.set_rate(false)
		services.set_share(false)
	super.deinit()


## RuStore app claims its https catalog links; without it the browser opens the page.
func _on_rate_page() -> void:
	if OS.get_name() != "Android":
		print("RuStoreContext: store page %s" % SHARE_URL)
		return
	OS.shell_open(SHARE_URL)


func _on_share(placement: StringName, text: String, image_path: String) -> void:
	_share.share(text, AndroidShare.tagged_url(SHARE_URL, placement), image_path)
