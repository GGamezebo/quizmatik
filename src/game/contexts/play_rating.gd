class_name PlayRating
extends RefCounted

## Google Play rating for `GooglePlayContext` and the fake Play `DevShopContext`: Play Core in-app review sheet
## (`ReviewManager` through `JavaClassWrapper`; library `com.google.android.play:review` comes from the export
## plugin `addons/play_review_deps/`) + the game's Play page. Off Android (editor) → prints only.
## Play shows the sheet only to an app installed from Play and within its quota; other builds finish silently.

const PLAY_PACKAGE := "com.quizmatic.app"
const PLAY_STORE_PACKAGE := "com.android.vending"
const PLAY_URL := "https://play.google.com/store/apps/details?id=" + PLAY_PACKAGE
const POLL_SEC := 0.25
const TIMEOUT_SEC := 15.0

var _is_busy: bool = false


func open_store_page() -> void:
	if OS.get_name() != "Android":
		print("PlayRating: store page %s" % PLAY_PACKAGE)
		return
	if not _open_play_app():
		OS.shell_open(PLAY_URL)


## A generic market:// link can be claimed by another installed store.
func _open_play_app() -> bool:
	if not Engine.has_singleton("AndroidRuntime"):
		return false
	var activity = Engine.get_singleton("AndroidRuntime").getActivity()
	var intent_class = JavaClassWrapper.wrap("android.content.Intent")
	var uri_class = JavaClassWrapper.wrap("android.net.Uri")
	if activity == null or intent_class == null or uri_class == null:
		return false
	var uri = uri_class.parse(PLAY_URL)
	var intent = intent_class.Intent("android.intent.action.VIEW")
	if uri == null or intent == null:
		return false
	intent.setData(uri)
	intent.setPackage(PLAY_STORE_PACKAGE)
	activity.startActivity(intent)
	if JavaClassWrapper.get_exception() != null:
		_warn_exception("open Play Store")
		return false
	return true


func request_review() -> void:
	if _is_busy:
		return
	if not Engine.has_singleton("AndroidRuntime"):
		print("PlayRating: in-app review requested (no Android runtime)")
		return
	var activity = Engine.get_singleton("AndroidRuntime").getActivity()
	var factory = JavaClassWrapper.wrap("com.google.android.play.core.review.ReviewManagerFactory")
	if activity == null or factory == null:
		push_warning("PlayRating: Play Core review library missing")
		return
	var manager = factory.create(activity)
	if manager == null:
		_warn_exception("create")
		return
	_is_busy = true
	print("PlayRating: requesting review flow")
	var request = manager.requestReviewFlow()
	if await _succeeded(request):
		await _succeeded(manager.launchReviewFlow(activity, request.getResult()))
		print("PlayRating: review flow finished")
	_is_busy = false


## Polls a Play `Task` on the game thread (its listeners would run on the Android UI thread).
func _succeeded(task) -> bool:
	if task == null:
		_warn_exception("task")
		return false
	var tree := Engine.get_main_loop() as SceneTree
	var waited := 0.0
	while not task.isComplete():
		if waited >= TIMEOUT_SEC:
			push_warning("PlayRating: task timed out")
			return false
		await tree.create_timer(POLL_SEC, true).timeout
		waited += POLL_SEC
	if not task.isSuccessful():
		push_warning("PlayRating: task failed")
		return false
	return true


func _warn_exception(step: String) -> void:
	push_warning("PlayRating: %s failed: %s" % [step, JavaClassWrapper.get_exception()])
