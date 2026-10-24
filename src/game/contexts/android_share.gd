class_name AndroidShare
extends RefCounted

## System share sheet for Android store contexts (`GooglePlayContext`, `RuStoreContext`, fake Play `DevShopContext`):
## `Intent.ACTION_SEND` text/plain + chooser through `JavaClassWrapper` from the game thread, no plugin.
## Off Android (editor) or when the intent can't be built → text goes to the clipboard (Android shows its own
## «copied» toast). Nothing is read back; no personal data leaves the game.

const ACTION_SEND := "android.intent.action.SEND"
const EXTRA_TEXT := "android.intent.extra.TEXT"


## `url` = store page; tagged with `utm_source=share&utm_campaign=<placement>` for store acquisition reports.
static func tagged_url(url: String, placement: StringName) -> String:
	var joiner := "&" if url.contains("?") else "?"
	return "%s%sutm_source=share&utm_campaign=%s" % [url, joiner, String(placement).uri_encode()]


func share(text: String, url: String) -> void:
	var message := "%s\n%s" % [text, url]
	if not Engine.has_singleton("AndroidRuntime"):
		print("AndroidShare: %s" % message)
		DisplayServer.clipboard_set(message)
		return
	# Game thread, like `PlayRating`: a GDScript callable on `runOnUiThread` deadlocks the game.
	_open_chooser(Engine.get_singleton("AndroidRuntime").getActivity(), message)


func _open_chooser(activity, message: String) -> void:
	var intent_class = JavaClassWrapper.wrap("android.content.Intent")
	if activity == null or intent_class == null:
		_fallback(message, "Intent class")
		return
	var intent = intent_class.Intent(ACTION_SEND)
	if intent == null:
		_fallback(message, "Intent()")
		return
	intent.setType("text/plain")
	intent.putExtra(EXTRA_TEXT, message)
	var chooser = intent_class.createChooser(intent, TranslationServer.translate("Поделиться"))
	if chooser == null:
		_fallback(message, "createChooser")
		return
	activity.startActivity(chooser)


func _fallback(message: String, step: String) -> void:
	push_warning("AndroidShare: %s failed: %s" % [step, JavaClassWrapper.get_exception()])
	DisplayServer.clipboard_set(message)
