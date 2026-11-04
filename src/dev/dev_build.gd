class_name DevBuild
extends RefCounted

## Dev hooks on: Godot editor, or a test export with custom feature `dev_lab` (`Android-RuStore-Test`).
## Release presets never carry `dev_lab`.

static func is_enabled() -> bool:
	return OS.has_feature("editor") or OS.has_feature("dev_lab")
