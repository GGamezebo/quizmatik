class_name RuStoreShopContext
extends PlatformContext

## `Platform/Android/RuStore/RuStoreShop`: RuStore Pay SDK via the official Godot plugin (wrapper class
## `RuStoreGodotPayClient`, looked up by name in the global class list → project compiles without the plugin;
## missing plugin = nothing sold, all open). Model = GooglePlayShop: no ads; one non-consumable `full_version`
## (price in RuStore Console) unlocks paid valleys. Content is locked only after RuStore confirms «not owned»
## (`get_purchase_availability` ok + `get_purchases` ok) AND `get_products` lists `full_version`
## → no RuStore app / not signed in / offline / product not live = everything open.
## Plugin API names from RuStore Pay Godot docs 9.x — not verified on a device.

const CLIENT_CLASS := &"RuStoreGodotPayClient"
const PRODUCT_ID_CLASS := &"RuStorePayProductId"
const PURCHASE_PARAMS_CLASS := &"RuStorePayProductPurchaseParams"
const PURCHASE_TYPE_ENUM := &"ERuStorePayPreferredPurchaseType"
const PURCHASE_STATUS_ENUM := &"ERuStorePayPurchaseStatus"
const PRODUCT_FULL_VERSION := "full_version"
# One-step non-consumable lands in CONFIRMED; PAID = money held (two-step), not owned yet.
const STATUS_OWNED := "CONFIRMED"

var _client: Object = null
var _listener: EventListener = EventListener.new()
var _is_owned: bool = false
var _is_owned_known: bool = false
var _is_listed: bool = false
var _price: String = ""


func _enter() -> void:
	if services == null:
		return
	var client_script := _global_script(CLIENT_CLASS)
	if client_script == null:
		push_warning("RuStoreShopContext: %s plugin missing — nothing for sale" % CLIENT_CLASS)
		return
	_client = client_script.call("get_instance")
	if _client == null:
		return
	_connect("on_get_purchase_availability_success", _on_availability)
	_connect("on_get_purchases_success", _on_purchases)
	_connect("on_get_products_success", _on_products)
	_connect("on_purchase_success", _on_purchase_success)
	_connect("on_purchase_failure", _on_purchase_failure)
	_listener.add(services.ev_request_purchase, _purchase)
	_client.call("get_purchase_availability")
	open_monetization()

func deinit() -> void:
	_listener.deinit()
	if services != null:
		services.set_offer(&"", "")
		services.set_content_locked(false)
	_client = null
	super.deinit()


## Failure signals of availability / purchases / products are not connected: no answer = content stays open.
func _on_availability(result: Object) -> void:
	if result == null or not bool(_value(result.get("isAvailable"))):
		return
	_client.call("get_purchases")
	var ids: Array = [_new_global(PRODUCT_ID_CLASS, [PRODUCT_FULL_VERSION])]
	_client.call("get_products", ids)

func _on_purchases(purchases: Array) -> void:
	var owned := false
	for purchase: Object in purchases:
		if purchase == null or _str(purchase.get("productId")) != PRODUCT_FULL_VERSION:
			continue
		if _enum_name(PURCHASE_STATUS_ENUM, _value(purchase.get("status"))) == STATUS_OWNED:
			owned = true
	_set_owned(owned)

func _on_products(products: Array) -> void:
	for product: Object in products:
		if product != null and _str(product.get("productId")) == PRODUCT_FULL_VERSION:
			_is_listed = true
			_price = _str(product.get("amountLabel"))
	_publish()

func _purchase() -> void:
	if _client == null or _is_owned or not _is_listed:
		services.ev_purchase_result.emit(_is_owned)
		return
	var params := _new_global(PURCHASE_PARAMS_CLASS, [_new_global(PRODUCT_ID_CLASS, [PRODUCT_FULL_VERSION])])
	if params == null:
		services.ev_purchase_result.emit(false)
		return
	_client.call("purchase", params, _enum_value(PURCHASE_TYPE_ENUM, "ONE_STEP"))

func _on_purchase_success(result: Object) -> void:
	var owned := result != null and _str(result.get("productId")) == PRODUCT_FULL_VERSION
	if owned:
		_set_owned(true)
	services.ev_purchase_result.emit(owned)

## Also cancel (`ProductPurchaseCancelled`) — popup closes, nothing unlocked.
func _on_purchase_failure(_product_id: Variant, _error: Variant) -> void:
	services.ev_purchase_result.emit(false)


func _set_owned(owned: bool) -> void:
	_is_owned = owned
	_is_owned_known = true
	_publish()

func _publish() -> void:
	services.set_content_locked(_is_owned_known and not _is_owned and _is_listed)
	if _is_owned or not _is_listed:
		services.set_offer(&"", "")
	else:
		services.set_offer(PlatformServices.OFFER_FULL_VERSION, _price)


# --- Plugin helpers (plugin types unknown at compile time) ---

func _connect(signal_name: StringName, callback: Callable) -> void:
	if _client.has_signal(signal_name):
		_listener.add(Signal(_client, signal_name), callback)
	else:
		push_warning("RuStoreShopContext: plugin has no signal %s" % signal_name)

## Plugin GDScript `class_name` → its script, or null when the plugin is not in the project.
func _global_script(global_name: StringName) -> Script:
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if StringName(entry.get("class", "")) == global_name:
			return load(String(entry.get("path", ""))) as Script
	return null

func _new_global(global_name: StringName, args: Array) -> Object:
	var script := _global_script(global_name)
	return script.callv("new", args) if script != null else null

## Plugin enums live as `Item` in `E*` classes; returns the int value (0 when unknown).
func _enum_value(enum_class: StringName, key: String) -> int:
	var items := _enum_items(enum_class)
	return int(items.get(key, 0))

func _enum_name(enum_class: StringName, value: Variant) -> String:
	if value is String or value is StringName:
		return String(value)
	var key: Variant = _enum_items(enum_class).find_key(value)
	return "" if key == null else String(key)

func _enum_items(enum_class: StringName) -> Dictionary:
	var script := _global_script(enum_class)
	if script == null:
		return {}
	var items: Variant = script.get_script_constant_map().get("Item")
	return items if items is Dictionary else {}

## Plugin wraps ids / labels in value objects (`.value`); plain values pass through.
func _value(v: Variant) -> Variant:
	if v is Object and v != null and "value" in v:
		return (v as Object).get("value")
	return v

func _str(v: Variant) -> String:
	var raw: Variant = _value(v)
	return "" if raw == null else str(raw)
