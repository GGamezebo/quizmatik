@tool
extends EditorPlugin

## First-party export helper (not a third-party addon): Android presets with custom feature `google_play`
## or `dev_shop` get the Maven library `com.google.android.play:review`; RuStore / tester builds stay without it.

var _export_plugin: PlayReviewExportPlugin


func _enter_tree() -> void:
	_export_plugin = PlayReviewExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class PlayReviewExportPlugin extends EditorExportPlugin:
	const DEPENDENCY := "com.google.android.play:review:2.0.2"
	const FEATURES := ["google_play", "dev_shop"]

	func _get_name() -> String:
		return "PlayReviewDeps"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		var preset := get_export_preset()
		if preset == null:
			return PackedStringArray()
		for feature in preset.get_custom_features().split(",", false):
			if FEATURES.has(feature.strip_edges()):
				return PackedStringArray([DEPENDENCY])
		return PackedStringArray()
