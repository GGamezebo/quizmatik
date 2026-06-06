extends Node

func _ready():
	# Create and save on startup (or from an editor tool button)
	var my_theme = create_stylish_theme()
	save_theme_to_disk(my_theme, "res://ui/modern_sci_fi.tres")

func create_stylish_theme() -> Theme:
	var theme = Theme.new()
	
	# --- Color palette ---
	var color_cyan = Color("#00f2ff")
	var color_dark = Color("#0a192f")
	var color_glass = Color(0.1, 0.2, 0.4, 0.6)
	
	# --- Button (normal) ---
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = color_glass
	btn_normal.border_width_left = 4
	btn_normal.border_color = color_cyan
	btn_normal.corner_radius_top_left = 12
	btn_normal.corner_radius_bottom_right = 12
	btn_normal.skew = Vector2(0.1, 0) # Slight skew for a dynamic look
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_right = 20
	
	# --- Button (hover) ---
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(color_cyan, 0.3)
	btn_hover.border_color = Color.WHITE
	btn_hover.shadow_color = Color(color_cyan, 0.4)
	btn_hover.shadow_size = 10

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_normal)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new()) # Hide default focus outline

	# --- PROGRESS BAR ---
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.05, 0.1, 0.2, 0.8)
	pb_bg.set_border_width_all(1)
	pb_bg.border_color = Color(color_cyan, 0.3)
	pb_bg.set_corner_radius_all(4)

	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = color_cyan
	pb_fill.set_corner_radius_all(2)
	pb_fill.shadow_color = Color(color_cyan, 0.5)
	pb_fill.shadow_size = 6
	
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	
	return theme

func save_theme_to_disk(theme: Theme, path: String):
	# Create the target directory if needed
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	# Save the resource
	var error = ResourceSaver.save(theme, path)
	if error == OK:
		print("Успех! Тема сохранена по пути: ", path)
	else:
		print("Ошибка при сохранении темы: ", error)
