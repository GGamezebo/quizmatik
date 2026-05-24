extends Control

const SAVE_PATH = "user://training_settings.tres"
const BLACK_LIST = [
		"RefCounted", 
		"Resource", 
		"GDScript", 
		"Built-in Scripts"
	]

@export var config: GameConfig
@export var params_container: VBoxContainer


func _ready():
	var new_config = _load_saved_config()
	ResourceUtils.update_resource(config, new_config)
	if config:
		regenerate_ui()

func _load_saved_config() -> GameConfig:
	if ResourceLoader.exists(SAVE_PATH):
		print("load config: ", SAVE_PATH)
		return load(SAVE_PATH)
	elif config:
		print("Clone training room game config")
		return config.duplicate(true)
	return null

func _save_config_to_disk():
	ResourceUtils.save_resource_to_disk(config, SAVE_PATH)
	
func regenerate_ui():
	# Очистка старых элементов, кроме кнопки выхода
	for child in params_container.get_children():
		child.queue_free()

	var properties = config.get_property_list()
	
	for prop in properties:
		if prop.usage & PROPERTY_USAGE_CATEGORY:
			if prop.name.ends_with(".gd") or prop.name in BLACK_LIST:
				continue
			_create_category_label(prop.name)
			continue
		
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_create_editor_row(prop.name, prop.type)

func _create_category_label(cat_name: String):
	var label = Label.new()
	label.text = "\n— " + cat_name.to_upper() + " —"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.YELLOW)
	params_container.add_child(label)

func _create_editor_row(prop_name: String, type: int):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var label = Label.new()
	label.text = prop_name.capitalize().replace("_", " ") + ":"
	label.custom_minimum_size.x = 250
	hbox.add_child(label)

	var current_value = config.get(prop_name)
	
	# ХАК/ПРОВЕРКА: Если это наше битовое поле операций, 
	# обрабатываем его отдельно, игнорируя стандартный TYPE_INT
	if prop_name == "allowed_operations":
		var flags_container = VBoxContainer.new() # Контейнер для списка галочек
		
		# Массив с названиями для UI и соответствующими битовыми масками из нашего enum
		var operations_data = [
			{"name": "Addition", "value": GameConfig.Operations.ADDITION},
			{"name": "Subtraction", "value": GameConfig.Operations.SUBTRACTION},
			{"name": "Multiplication", "value": GameConfig.Operations.MULTIPLICATION},
			{"name": "Division", "value": GameConfig.Operations.DIVISION}
		]
		
		for op in operations_data:
			var check_box = CheckBox.new()
			check_box.text = op["name"]
			
			# Проверяем, включен ли этот бит в текущем значении конфига
			check_box.button_pressed = (current_value & op["value"]) != 0
			
			# При переключении флага обновляем битовую маску в конфиге
			check_box.toggled.connect(func(is_checked):
				var flags = config.get(prop_name)
				if is_checked:
					flags |= op["value"]  # Включаем бит (Побитовое ИЛИ)
				else:
					flags &= ~op["value"] # Выключаем бит (Побитовое И НЕ)
				
				config.set(prop_name, flags)
				_save_config_to_disk()
			)
			flags_container.add_child(check_box)
		
		hbox.add_child(flags_container)
		params_container.add_child(hbox)
		return # Выходим из метода, чтобы не срабатывал match ниже
		
	# Стандартная обработка остальных типов
	match type:
		TYPE_INT, TYPE_FLOAT:
			var spin_box = SpinBox.new()
			spin_box.step = 0.1 if type == TYPE_FLOAT else 1.0
			spin_box.allow_greater = true
			spin_box.allow_lesser = true
			spin_box.value = current_value

			spin_box.value_changed.connect(func(val): 
				config.set(prop_name, val)
				_save_config_to_disk()
			)
			hbox.add_child(spin_box)
			
		TYPE_BOOL:
			var check_box = CheckBox.new()
			check_box.button_pressed = current_value
			check_box.toggled.connect(func(val): 
				config.set(prop_name, val)
				_save_config_to_disk()
			)
			hbox.add_child(check_box)

	params_container.add_child(hbox)


func _on_reset_setting_pressed() -> void:
	ResourceUtils.update_resource(config, GameConfig.new())
	_save_config_to_disk()
	regenerate_ui()
