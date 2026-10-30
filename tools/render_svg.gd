extends SceneTree

## Offline SVG rasterizer using the same renderer as Godot's texture importer.
## --script tools/render_svg.gd -- input.svg output.png scale
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3:
		quit(1)
		return
	var image := Image.new()
	var error: Error = image.load_svg_from_string(FileAccess.get_file_as_string(args[0]), float(args[2]))
	if error == OK:
		error = image.save_png(args[1])
	quit(0 if error == OK else 1)
