class_name DevShopContext
extends PlatformContext

## Fake store answering PlatformServices like YandexShop / GooglePlayShop — ads «play» for a moment and
## always reward, purchase always succeeds (until restart). `Platform/Desktop/DevShop`: editor only,
## `--dev-shop=yandex|play`. `Platform/Android/AndroidDevShop`: export feature `dev_shop` (preset `Android-Test-Shop`),
## model play. Never in release presets.

const AD_SEC := 0.6

var _model: String = ""
var _listener: EventListener = EventListener.new()
## Model play also answers rating + share like `GooglePlayContext` (real Play Core / share sheet on a phone).
var _rating: PlayRating = PlayRating.new()
var _share: AndroidShare = AndroidShare.new()
var _is_alive: bool = true


func _enter() -> void:
	_model = String(data.get("dev_shop_model", "yandex"))
	if services == null:
		return
	_listener.add(services.ev_request_interstitial, _on_interstitial)
	_listener.add(services.ev_request_rewarded, _on_rewarded)
	_listener.add(services.ev_request_purchase, _on_purchase)
	if _model == "play":
		services.set_content_locked(true)
		services.set_offer(PlatformServices.OFFER_FULL_VERSION, "$2.99")
		_listener.add(services.ev_request_review, _rating.request_review)
		_listener.add(services.ev_request_rate_page, _rating.open_store_page)
		services.set_rate(true)
		_listener.add(services.ev_request_share, _on_share)
		services.set_share(true)
	else:
		services.set_ads(true, true)
		services.set_offer(PlatformServices.OFFER_NO_ADS, "199 ₽")
	print("DevShopContext: model=%s" % _model)
	open_monetization()

func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	if services != null:
		services.set_ads(false, false)
		services.set_offer(&"", "")
		services.set_content_locked(false)
		services.set_rate(false)
		services.set_share(false)
	super.deinit()


func _on_interstitial(placement: StringName) -> void:
	print("DevShopContext: interstitial at %s" % placement)
	_fake_ad(func() -> void: pass)

func _on_rewarded(placement: StringName) -> void:
	print("DevShopContext: rewarded at %s" % placement)
	_fake_ad(func() -> void: services.ev_rewarded_result.emit(placement, true))

func _on_purchase() -> void:
	print("DevShopContext: purchase %s" % services.offer_kind)
	if _model == "play":
		services.set_content_locked(false)
	else:
		services.set_ads(false, true)
	services.set_offer(&"", "")
	services.ev_purchase_result.emit(true)


func _on_share(placement: StringName, text: String, image_path: String) -> void:
	_share.share(text, AndroidShare.tagged_url(GooglePlayContext.SHARE_URL, placement), image_path)


## Same pause contract as a real ad: hidden → pause + mute, then resume and answer.
func _fake_ad(on_done: Callable) -> void:
	_set_visible(false)
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(AD_SEC, true).timeout.connect(func() -> void:
		if not _is_alive:
			return
		_set_visible(true)
		on_done.call()
	)

func _set_visible(is_visible: bool) -> void:
	if root_events != null:
		root_events.ev_app_visibility_changed.emit(is_visible)
