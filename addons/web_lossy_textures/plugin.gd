@tool
extends EditorPlugin

## First-party export helper (not a third-party addon): presets with feature `web` ship big imported
## PNG/JPG textures as one lossy WebP (`PortableCompressedTexture2D`) instead of two VRAM-compressed
## copies (S3TC for desktop + ETC2 for phones). Import settings stay VRAM Compressed, so Android /
## desktop exports and the editor are untouched. Tuning: Project Settings → `export/web_lossy_textures/*`
## (Advanced): `enabled`, `quality`, `min_pixels`, `exclude` / `lossless` (globs on the res:// path).

var _export_plugin: WebLossyExportPlugin


func _enter_tree() -> void:
	WebLossyExportPlugin.register_settings()
	_export_plugin = WebLossyExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class WebLossyExportPlugin extends EditorExportPlugin:
	const VERSION := 1
	const PREFIX := "export/web_lossy_textures/"
	const DEFAULTS := {
		"enabled": true,
		"quality": 0.8,
		"min_pixels": 100000,
		"exclude": ["*_atlas*", "*spritesheet*", "res://assets/ui/icons/*"],
		"lossless": [],
	}
	const HINTS := {
		"enabled": [TYPE_BOOL, PROPERTY_HINT_NONE, ""],
		"quality": [TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.1,1.0,0.01"],
		"min_pixels": [TYPE_INT, PROPERTY_HINT_RANGE, "0,4194304,1,or_greater"],
		"exclude": [TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_NONE, ""],
		"lossless": [TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_NONE, ""],
	}
	const SOURCE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
	const IMPORT_MODE_VRAM_COMPRESSED := 2

	var _quality := 0.8
	var _min_pixels := 0
	var _exclude := PackedStringArray()
	var _lossless := PackedStringArray()
	var _converted := 0

	static func register_settings() -> void:
		for key: String in DEFAULTS:
			var setting_name := PREFIX + key
			var value: Variant = _default(key)
			if not ProjectSettings.has_setting(setting_name):
				ProjectSettings.set_setting(setting_name, value)
			ProjectSettings.set_initial_value(setting_name, value)
			ProjectSettings.add_property_info({
				"name": setting_name, "type": HINTS[key][0], "hint": HINTS[key][1], "hint_string": HINTS[key][2],
			})

	static func setting(key: String) -> Variant:
		return ProjectSettings.get_setting(PREFIX + key, _default(key))

	static func _default(key: String) -> Variant:
		var value: Variant = DEFAULTS[key]
		if value is Array:
			return PackedStringArray(value)
		return value

	func _get_name() -> String:
		return "WebLossyTextures"

	func _get_customization_configuration_hash() -> int:
		var values := [VERSION]
		for key: String in DEFAULTS:
			values.append(setting(key))
		return str(values).hash()

	func _begin_customize_resources(_platform: EditorExportPlatform, features: PackedStringArray) -> bool:
		if not features.has("web") or not bool(setting("enabled")):
			return false
		_quality = clampf(float(setting("quality")), 0.1, 1.0)
		_min_pixels = int(setting("min_pixels"))
		_exclude = PackedStringArray(setting("exclude"))
		_lossless = PackedStringArray(setting("lossless"))
		_converted = 0
		return true

	func _end_customize_resources() -> void:
		if _converted > 0:
			print("WebLossyTextures: %d textures exported as WebP" % _converted)

	func _customize_resource(resource: Resource, path: String) -> Resource:
		if path.is_empty() or not (resource is CompressedTexture2D):
			return null
		if not SOURCE_EXTENSIONS.has(path.get_extension().to_lower()) or _matches(path, _exclude):
			return null
		var texture := resource as CompressedTexture2D
		var width := texture.get_width()
		var height := texture.get_height()
		if width * height < _min_pixels:
			return null
		var params := _import_params(path)
		if int(params.get("compress/mode", -1)) != IMPORT_MODE_VRAM_COMPRESSED:
			return null
		var image := _source_image(path, width, height, params)
		if image == null:
			return null
		var out := PortableCompressedTexture2D.new()
		out.keep_compressed_buffer = true
		var mode := PortableCompressedTexture2D.COMPRESSION_MODE_LOSSY
		if _matches(path, _lossless):
			mode = PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS
		out.create_from_image(image, mode, false, _quality)
		_converted += 1
		return out

	## Source file, processed like the texture importer does (size limit, alpha border, premultiply).
	## Read from disk instead of the imported VRAM data so the art is not compressed twice.
	func _source_image(path: String, width: int, height: int, params: Dictionary) -> Image:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			push_warning("WebLossyTextures: cannot read %s, keeping VRAM texture" % path)
			return null
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		if image.get_width() != width or image.get_height() != height:
			image.resize(width, height, Image.INTERPOLATE_CUBIC)
		var has_alpha := image.detect_alpha() != Image.ALPHA_NONE
		if has_alpha and bool(params.get("process/fix_alpha_border", true)):
			image.fix_alpha_edges()
		if has_alpha and bool(params.get("process/premult_alpha", false)):
			image.premultiply_alpha()
		if not has_alpha:
			image.convert(Image.FORMAT_RGB8)
		if bool(params.get("mipmaps/generate", false)):
			image.generate_mipmaps()
		return image

	func _import_params(path: String) -> Dictionary:
		var config := ConfigFile.new()
		if config.load(path + ".import") != OK or not config.has_section("params"):
			return {}
		var params := {}
		for key in config.get_section_keys("params"):
			params[key] = config.get_value("params", key)
		return params

	func _matches(path: String, patterns: PackedStringArray) -> bool:
		for pattern in patterns:
			if path.match(pattern) or path.get_file().match(pattern):
				return true
		return false
