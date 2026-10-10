class_name DesktopContext
extends PlatformContext

## `Platform/Desktop`: generic PC hooks (Windows / Linux / macOS, incl. editor). Store branch by export feature.
## Editor only: user arg `--dev-shop=yandex|play` (Project Settings → Run → Main Run Args: `-- --dev-shop=play`)
## opens the fake `DevShop` to try monetization UI without a store.

const DEV_SHOP_ARG := "--dev-shop="


func _enter() -> void:
	if OS.has_feature("steam"):
		open_child("ev.open_steam")
	elif OS.has_feature("editor"):
		var model := _dev_shop_model()
		if not model.is_empty():
			open_shop({"dev_shop_model": model})


func _dev_shop_model() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(DEV_SHOP_ARG):
			return arg.trim_prefix(DEV_SHOP_ARG)
	return ""
