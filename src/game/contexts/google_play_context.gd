class_name GooglePlayContext
extends PlatformContext

## `Platform/Android/GooglePlay`: Play-specific hooks. Cloud save lives in child `GooglePlayCloudSave`,
## purchases in child `GooglePlayShop` (opened unless `no_monetization`).
## UI languages: every `GameLocale.SUPPORTED` one (`PlatformServices.languages` stays empty).
## Rating (`PlatformServices.can_rate`): Play in-app review + Play page via `PlayRating`.

var _rating: PlayRating = PlayRating.new()
var _listener: EventListener = EventListener.new()


func _enter() -> void:
	open_cloud_save()
	open_shop()
	if services != null:
		_listener.add(services.ev_request_review, _rating.request_review)
		_listener.add(services.ev_request_rate_page, _rating.open_store_page)
		services.set_rate(true)

func deinit() -> void:
	_listener.deinit()
	if services != null:
		services.set_rate(false)
	super.deinit()
