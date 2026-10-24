class_name AndroidShare
extends RefCounted

## System share sheet for Android store contexts (`GooglePlayContext`, `RuStoreContext`, fake Play `DevShopContext`):
## `JavaClassWrapper` calls from the game thread, no plugin. With an image: PNG → `content://` URI from Godot's own
## `FileProvider` (`<package>.fileprovider`, files dir) → `ShareCompat.IntentBuilder` (stream + text caption, read
## grant); without one or when that fails → `Intent.ACTION_SEND` text/plain chooser. Off Android (editor) or when
## nothing works → text goes to the clipboard (Android shows its own «copied» toast). No personal data leaves the game.

const ACTION_SEND := "android.intent.action.SEND"
const EXTRA_TEXT := "android.intent.extra.TEXT"
const CHOOSER_TITLE := "Поделиться"


## `url` = store page; tagged with `utm_source=share&utm_campaign=<placement>` for store acquisition reports.
static func tagged_url(url: String, placement: StringName) -> String:
	var joiner := "&" if url.contains("?") else "?"
	return "%s%sutm_source=share&utm_campaign=%s" % [url, joiner, String(placement).uri_encode()]


## `image_path` = `user://` PNG ("" = text only).
func share(text: String, url: String, image_path: String = "") -> void:
	var message := "%s\n%s" % [text, url]
	if not Engine.has_singleton("AndroidRuntime"):
		print("AndroidShare: %s%s" % [message, "\n[image] " + ProjectSettings.globalize_path(image_path) if not image_path.is_empty() else ""])
		DisplayServer.clipboard_set(message)
		return
	# Game thread, like `PlayRating`: a GDScript callable on `runOnUiThread` deadlocks the game.
	var activity = Engine.get_singleton("AndroidRuntime").getActivity()
	if activity == null:
		_fallback(message, "activity")
		return
	if not image_path.is_empty() and _share_image(activity, message, ProjectSettings.globalize_path(image_path)):
		return
	_share_text(activity, message)


func _share_image(activity, message: String, file_path: String) -> bool:
	var file_class = JavaClassWrapper.wrap("java.io.File")
	var provider_class = JavaClassWrapper.wrap("androidx.core.content.FileProvider")
	var builder_class = JavaClassWrapper.wrap("androidx.core.app.ShareCompat$IntentBuilder")
	if file_class == null or provider_class == null or builder_class == null:
		return _warn("image share classes")
	var file = file_class.File(file_path)
	var uri = provider_class.getUriForFile(activity, "%s.fileprovider" % activity.getPackageName(), file) if file != null else null
	if uri == null:
		return _warn("getUriForFile")
	var builder = builder_class.from(activity) if builder_class.has_java_method(&"from") else builder_class.IntentBuilder(activity)
	if builder == null:
		return _warn("IntentBuilder")
	builder.setType("image/png")
	builder.setStream(uri)
	builder.setText(message)
	builder.setChooserTitle(TranslationServer.translate(CHOOSER_TITLE))
	builder.startChooser()
	return true


func _share_text(activity, message: String) -> void:
	var intent_class = JavaClassWrapper.wrap("android.content.Intent")
	if intent_class == null:
		_fallback(message, "Intent class")
		return
	var intent = intent_class.Intent(ACTION_SEND)
	if intent == null:
		_fallback(message, "Intent()")
		return
	intent.setType("text/plain")
	intent.putExtra(EXTRA_TEXT, message)
	var chooser = intent_class.createChooser(intent, TranslationServer.translate(CHOOSER_TITLE))
	if chooser == null:
		_fallback(message, "createChooser")
		return
	activity.startActivity(chooser)


func _warn(step: String) -> bool:
	push_warning("AndroidShare: %s failed: %s" % [step, JavaClassWrapper.get_exception()])
	return false


func _fallback(message: String, step: String) -> void:
	_warn(step)
	DisplayServer.clipboard_set(message)
