class_name GooglePlayContext
extends PlatformContext

## `Platform/Android/GooglePlay`: Play-specific hooks. Cloud save lives in child `GooglePlayCloudSave`,
## purchases in child `GooglePlayShop` (opened unless `no_monetization`).


func _enter() -> void:
	open_cloud_save()
	open_shop()
