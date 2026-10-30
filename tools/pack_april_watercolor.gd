extends SceneTree

## Offline asset sizing/atlas packing, preserves generated watercolor and alpha.
## --script tools/pack_april_watercolor.gd -- background.png atlas.png
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] == "banner":
		make_banner()
		quit()
		return
	if args.size() != 2:
		quit(1)
		return
	var background := Image.load_from_file(args[0])
	background.resize(1080, 720, Image.INTERPOLATE_LANCZOS)
	var error: Error = background.save_png("res://src/ui/backgrounds/april_fools/bg_upside_down.png")
	var source := Image.load_from_file(args[1])
	source.convert(Image.FORMAT_RGBA8)
	var atlas := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	for row in 3:
		for col in 5:
			var left: int = roundi(float(col) * source.get_width() / 5.0)
			var top: int = roundi(float(row) * source.get_height() / 3.0)
			var right: int = roundi(float(col + 1) * source.get_width() / 5.0)
			var bottom: int = roundi(float(row + 1) * source.get_height() / 3.0)
			var cell := source.get_region(Rect2i(left, top, right - left, bottom - top))
			var fit: float = minf(224.0 / cell.get_width(), 224.0 / cell.get_height())
			cell.resize(roundi(cell.get_width() * fit), roundi(cell.get_height() * fit), Image.INTERPOLATE_LANCZOS)
			var dest := Vector2i(col * 256 + (256 - cell.get_width()) / 2, row * 240 + (240 - cell.get_height()) / 2)
			atlas.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), dest)
	if error == OK:
		error = atlas.save_png("res://src/features/answer/jester_balloons_atlas.png")
	print("APRIL_WATERCOLOR_PACK: ", error_string(error))
	quit(0 if error == OK else 1)


func make_banner() -> void:
	var background := Image.load_from_file("res://src/ui/backgrounds/april_fools/bg_upside_down.png")
	var sky := background.get_region(Rect2i(0, 0, 1080, 270))
	sky.resize(672, 160, Image.INTERPOLATE_LANCZOS)
	sky.convert(Image.FORMAT_RGBA8)
	for y in sky.get_height():
		for x in sky.get_width():
			sky.set_pixel(x, y, sky.get_pixel(x, y).lerp(Color("515d7a"), .6))
	var atlas := Image.load_from_file("res://src/features/answer/jester_balloons_atlas.png")
	var jester := atlas.get_region(Rect2i(0, 0, 256, 240))
	jester.resize(112, 105, Image.INTERPOLATE_LANCZOS)
	sky.blend_rect(jester, Rect2i(Vector2i.ZERO, jester.get_size()), Vector2i(27, 28))
	sky.resize(1344, 320, Image.INTERPOLATE_LANCZOS)
	sky.save_png("res://bin/april_banner_art.png")
