class_name GooglePlayShopContext
extends PlatformContext

## `Platform/Android/GooglePlay/GooglePlayShop`: Play Billing via the `GodotGooglePlayBilling` plugin
## (singleton called by name → project compiles without it; missing plugin = nothing sold, all open).
## Model: no ads; one non-consumable `full_version` (price in Play Console) unlocks paid valleys.
## Content is locked only while Play confirms «not owned» AND the product can be sold here:
## no Play services / country without Play billing (e.g. RU) / product not live → everything open.
## Network errors on the catalog keep the lock (owned purchases still come from Play's offline cache).

const PLUGIN_NAME := "GodotGooglePlayBilling"
const PRODUCT_FULL_VERSION := "full_version"
const PRODUCT_TYPE := "inapp"
# BillingClient.BillingResponseCode / PurchaseState values (plugin `BillingClient.gd`).
const RESPONSE_OK := 0
const RESPONSE_BILLING_UNAVAILABLE := 3
const RESPONSE_ITEM_UNAVAILABLE := 4
const RESPONSE_ITEM_ALREADY_OWNED := 7
const STATE_PURCHASED := 1
const STATE_PENDING := 2

var _billing: Object = null
var _listener: EventListener = EventListener.new()
var _is_owned: bool = false
var _is_owned_known: bool = false
## false once Play says `full_version` cannot be sold to this account / country.
var _is_sellable: bool = true
var _is_purchasing: bool = false
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
	# Back from Play Store (promo code, pending payment done while away) → re-check entitlements.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		_listener.add(tree.root.focus_entered, _query_purchases)
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
	_query_purchases()
	_billing.queryProductDetails(PackedStringArray([PRODUCT_FULL_VERSION]), PRODUCT_TYPE)

func _query_purchases() -> void:
	if _billing != null and _billing.isReady():
		_billing.queryPurchases(PRODUCT_TYPE, false)

func _on_purchases_response(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		return
	var owned := _has_full_version(response.get("purchases", []))
	_set_owned(owned)
	if owned:
		_finish_purchase(true)

func _on_product_details(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if _is_unsellable_code(code):
		_set_sellable(false)
		return
	if code != RESPONSE_OK:
		return
	var is_listed := false
	for product: Dictionary in response.get("product_details", []):
		if String(product.get("product_id", "")) != PRODUCT_FULL_VERSION:
			continue
		is_listed = true
		var offers: Variant = product.get("one_time_purchase_offer_details_list")
		if offers is Array and not (offers as Array).is_empty():
			_price = String((offers as Array)[0].get("formatted_price", ""))
	_set_sellable(is_listed)

func _purchase() -> void:
	if _billing == null or _is_owned or not _is_sellable:
		services.ev_purchase_result.emit(_is_owned)
		return
	_is_purchasing = true
	var launch: Dictionary = _billing.purchase(PRODUCT_FULL_VERSION, "", "", false)
	var code := int(launch.get("response_code", -1))
	if code == RESPONSE_ITEM_ALREADY_OWNED:
		_set_owned(true)
		_finish_purchase(true)
	elif code != RESPONSE_OK:
		if _is_unsellable_code(code):
			_set_sellable(false)
		_finish_purchase(false)

## Also fires without a purchase in flight (pending payment completed later).
func _on_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code == RESPONSE_ITEM_ALREADY_OWNED:
		_set_owned(true)
		_finish_purchase(true)
		return
	if code != RESPONSE_OK:
		_finish_purchase(false)
		return
	var purchases: Array = response.get("purchases", [])
	if _has_full_version(purchases):
		_set_owned(true)
		_finish_purchase(true)
	elif _has_pending(purchases):
		# Slow card / cash: stays «not owned» until a later update or the next launch.
		if _is_purchasing:
			_is_purchasing = false
			services.ev_purchase_pending.emit()
	else:
		_finish_purchase(false)


## Also acknowledges new purchases (unacknowledged one-time purchases are refunded by Play after 3 days).
func _has_full_version(purchases: Array) -> bool:
	var owned := false
	for purchase: Dictionary in purchases:
		if not _is_full_version(purchase) or int(purchase.get("purchase_state", 0)) != STATE_PURCHASED:
			continue
		owned = true
		if not bool(purchase.get("is_acknowledged", false)):
			_billing.acknowledgePurchase(String(purchase.get("purchase_token", "")))
	return owned

func _has_pending(purchases: Array) -> bool:
	for purchase: Dictionary in purchases:
		if _is_full_version(purchase) and int(purchase.get("purchase_state", 0)) == STATE_PENDING:
			return true
	return false

func _is_full_version(purchase: Dictionary) -> bool:
	return PRODUCT_FULL_VERSION in Array(purchase.get("product_ids", []))

func _is_unsellable_code(code: int) -> bool:
	return code == RESPONSE_BILLING_UNAVAILABLE or code == RESPONSE_ITEM_UNAVAILABLE

func _finish_purchase(is_success: bool) -> void:
	if not _is_purchasing:
		return
	_is_purchasing = false
	services.ev_purchase_result.emit(is_success)

func _set_owned(owned: bool) -> void:
	_is_owned = owned
	_is_owned_known = true
	_publish()

func _set_sellable(sellable: bool) -> void:
	if not sellable:
		push_warning("GooglePlayShopContext: %s not sellable here — all valleys open" % PRODUCT_FULL_VERSION)
	_is_sellable = sellable
	_publish()

func _publish() -> void:
	services.set_content_locked(_is_owned_known and not _is_owned and _is_sellable)
	if _is_owned or not _is_sellable:
		services.set_offer(&"", "")
	else:
		services.set_offer(PlatformServices.OFFER_FULL_VERSION, _price)
