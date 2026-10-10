class_name GooglePlayShopContext
extends PlatformContext

## `Platform/Android/GooglePlay/GooglePlayShop`: Play Billing via the `GodotGooglePlayBilling` plugin
## (singleton called by name → project compiles without it; missing plugin = nothing sold, all open).
## Model: no ads; one non-consumable `full_version` (price in Play Console) unlocks paid valleys.
## Content is locked only after Play confirms «not owned» → offline / no Play services = everything open.

const PLUGIN_NAME := "GodotGooglePlayBilling"
const PRODUCT_FULL_VERSION := "full_version"
const PRODUCT_TYPE := "inapp"
# BillingClient.BillingResponseCode / PurchaseState values (plugin `BillingClient.gd`).
const RESPONSE_OK := 0
const RESPONSE_ITEM_ALREADY_OWNED := 7
const STATE_PURCHASED := 1

var _billing: Object = null
var _listener: EventListener = EventListener.new()
var _is_owned: bool = false
var _price: String = ""


func _enter() -> void:
	if services == null:
		return
	if not Engine.has_singleton(PLUGIN_NAME):
		push_warning("GooglePlayShopContext: %s plugin missing — nothing for sale" % PLUGIN_NAME)
		return
	_billing = Engine.get_singleton(PLUGIN_NAME)
	_billing.initPlugin()
	_listener.add(Signal(_billing, "connected"), _on_connected)
	_listener.add(Signal(_billing, "query_product_details_response"), _on_product_details)
	_listener.add(Signal(_billing, "query_purchases_response"), _on_purchases_response)
	_listener.add(Signal(_billing, "on_purchase_updated"), _on_purchase_updated)
	_listener.add(services.ev_request_purchase, _purchase)
	_billing.startConnection()
	open_monetization()

func deinit() -> void:
	_listener.deinit()
	if services != null:
		services.set_offer(&"", "")
		services.set_content_locked(false)
	if _billing != null:
		_billing.endConnection()
	_billing = null
	super.deinit()


func _on_connected() -> void:
	_billing.queryPurchases(PRODUCT_TYPE, false)
	_billing.queryProductDetails(PackedStringArray([PRODUCT_FULL_VERSION]), PRODUCT_TYPE)

func _on_purchases_response(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		return
	_set_owned(_has_full_version(response.get("purchases", [])))

func _on_product_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		return
	for product: Dictionary in response.get("product_details", []):
		if String(product.get("product_id", "")) != PRODUCT_FULL_VERSION:
			continue
		var offers: Variant = product.get("one_time_purchase_offer_details_list")
		if offers is Array and not (offers as Array).is_empty():
			_price = String((offers as Array)[0].get("formatted_price", ""))
	_publish_offer()

func _purchase() -> void:
	if _billing == null or _is_owned:
		services.ev_purchase_result.emit(_is_owned)
		return
	var launch: Dictionary = _billing.purchase(PRODUCT_FULL_VERSION, "", "", false)
	var code := int(launch.get("response_code", -1))
	if code == RESPONSE_ITEM_ALREADY_OWNED:
		_set_owned(true)
		services.ev_purchase_result.emit(true)
	elif code != RESPONSE_OK:
		services.ev_purchase_result.emit(false)

func _on_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code == RESPONSE_ITEM_ALREADY_OWNED:
		_set_owned(true)
		services.ev_purchase_result.emit(true)
		return
	var owned := code == RESPONSE_OK and _has_full_version(response.get("purchases", []))
	if owned:
		_set_owned(true)
	# Pending (slow card / cash) stays «not owned» until a later update or next launch.
	services.ev_purchase_result.emit(owned)


## Also acknowledges new purchases (unacknowledged one-time purchases are refunded by Play after 3 days).
func _has_full_version(purchases: Array) -> bool:
	var owned := false
	for purchase: Dictionary in purchases:
		if not PRODUCT_FULL_VERSION in Array(purchase.get("product_ids", [])):
			continue
		if int(purchase.get("purchase_state", 0)) != STATE_PURCHASED:
			continue
		owned = true
		if not bool(purchase.get("is_acknowledged", false)):
			_billing.acknowledgePurchase(String(purchase.get("purchase_token", "")))
	return owned

func _set_owned(owned: bool) -> void:
	_is_owned = owned
	services.set_content_locked(not owned)
	_publish_offer()

func _publish_offer() -> void:
	if _is_owned:
		services.set_offer(&"", "")
	else:
		services.set_offer(PlatformServices.OFFER_FULL_VERSION, _price)
