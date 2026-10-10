class_name YandexShopContext
extends PlatformContext

## `Platform/WEB/Yandex/YandexShop`: Yandex ads + payments. Opened by YandexContext after SDK init
## (payload `ysdk`); never in `no_monetization` builds. Model: all valleys free, ads; one purchase
## `no_ads` (catalog id, price set in the Yandex console) turns interstitials off.
## Purchases are checked on every launch (`getPurchases`, moderation requirement); non-consumable → never consumed.

const PRODUCT_NO_ADS := "no_ads"

var _ysdk: JavaScriptObject = null
var _payments: JavaScriptObject = null
var _json: JavaScriptObject = null
var _listener: EventListener = EventListener.new()
var _is_alive: bool = true
var _is_owned: bool = false
var _price: String = ""
var _rewarded_placement: StringName = &""
var _is_rewarded_granted: bool = false
# JS callbacks must stay referenced, otherwise the browser drops them.
var _shop_callbacks: Array[JavaScriptObject] = []
var _ad_callbacks: Array[JavaScriptObject] = []


func _enter() -> void:
	_ysdk = data.get("ysdk") as JavaScriptObject
	_json = JavaScriptBridge.get_interface("JSON")
	if _ysdk == null or services == null:
		return
	_listener.add(services.ev_request_interstitial, _show_interstitial)
	_listener.add(services.ev_request_rewarded, _show_rewarded)
	_listener.add(services.ev_request_purchase, _purchase)
	services.set_ads(true, true)
	_ysdk.getPayments().then(_keep(_shop_callbacks, _on_payments))
	open_monetization()

func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	if services != null:
		services.set_ads(false, false)
		services.set_offer(&"", "")
	_ysdk = null
	_payments = null
	_shop_callbacks.clear()
	_ad_callbacks.clear()
	super.deinit()


# --- Payments ---

func _on_payments(args: Array) -> void:
	if not _is_alive or args.is_empty():
		return
	_payments = args[0]
	_payments.getPurchases().then(_keep(_shop_callbacks, _on_purchases))
	_payments.getCatalog().then(_keep(_shop_callbacks, _on_catalog))

func _on_purchases(args: Array) -> void:
	if not _is_alive or args.is_empty():
		return
	for purchase: Variant in _to_array(args[0]):
		if purchase is Dictionary and String(purchase.get("productID", "")) == PRODUCT_NO_ADS:
			_set_owned()
			return

func _on_catalog(args: Array) -> void:
	if not _is_alive or args.is_empty():
		return
	for product: Variant in _to_array(args[0]):
		if product is Dictionary and String(product.get("id", "")) == PRODUCT_NO_ADS:
			_price = String(product.get("price", ""))
	_publish_offer()

func _purchase() -> void:
	if _payments == null or _is_owned:
		services.ev_purchase_result.emit(_is_owned)
		return
	var options: JavaScriptObject = JavaScriptBridge.create_object("Object")
	options.set("id", PRODUCT_NO_ADS)
	_payments.purchase(options).then(
		_keep(_shop_callbacks, _on_purchase_done),
		_keep(_shop_callbacks, _on_purchase_failed),
	)

func _on_purchase_done(_args: Array) -> void:
	if not _is_alive:
		return
	_set_owned()
	services.ev_purchase_result.emit(true)

func _on_purchase_failed(_args: Array) -> void:
	if _is_alive:
		services.ev_purchase_result.emit(false)

func _set_owned() -> void:
	_is_owned = true
	services.set_ads(false, true)
	_publish_offer()

func _publish_offer() -> void:
	if _is_owned:
		services.set_offer(&"", "")
	else:
		services.set_offer(PlatformServices.OFFER_NO_ADS, _price)


# --- Ads ---

func _show_interstitial(_placement: StringName) -> void:
	if _is_owned:
		return
	_ysdk.adv.showFullscreenAdv(_ad_options({
		"onOpen": _on_ad_open,
		"onClose": _on_ad_close,
		"onError": _on_ad_close,
	}))

func _show_rewarded(placement: StringName) -> void:
	_rewarded_placement = placement
	_is_rewarded_granted = false
	_ysdk.adv.showRewardedVideo(_ad_options({
		"onOpen": _on_ad_open,
		"onRewarded": _on_rewarded,
		"onClose": _on_rewarded_close,
		"onError": _on_rewarded_close,
	}))

func _on_ad_open(_args: Array) -> void:
	_set_visible(false)

func _on_ad_close(_args: Array) -> void:
	_set_visible(true)

func _on_rewarded(_args: Array) -> void:
	_is_rewarded_granted = true

func _on_rewarded_close(_args: Array) -> void:
	_set_visible(true)
	if _is_alive:
		services.ev_rewarded_result.emit(_rewarded_placement, _is_rewarded_granted)

func _set_visible(is_visible: bool) -> void:
	if _is_alive and root_events != null:
		root_events.ev_app_visibility_changed.emit(is_visible)


# --- JS helpers ---

## `{ callbacks: { name: fn } }` for `ysdk.adv.*`; replaces callbacks of the previous ad.
func _ad_options(handlers: Dictionary) -> JavaScriptObject:
	_ad_callbacks.clear()
	var callbacks: JavaScriptObject = JavaScriptBridge.create_object("Object")
	for key: String in handlers:
		callbacks.set(key, _keep(_ad_callbacks, handlers[key]))
	var options: JavaScriptObject = JavaScriptBridge.create_object("Object")
	options.set("callbacks", callbacks)
	return options

## JS array → GDScript Array of Dictionaries (JSON round-trip drops SDK methods, keeps data fields).
func _to_array(js_value: Variant) -> Array:
	if _json == null or not js_value is JavaScriptObject:
		return []
	var parsed: Variant = JSON.parse_string(String(_json.stringify(js_value)))
	return parsed if parsed is Array else []

func _keep(store: Array[JavaScriptObject], method: Callable) -> JavaScriptObject:
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(method)
	store.append(cb)
	return cb
