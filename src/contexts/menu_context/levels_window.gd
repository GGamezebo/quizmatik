class_name LevelsWindow
extends Control

signal ev_start_level(config: GameConfig)

# Путь к папке, где лежат ваши ресурсы GameConfig
@export_dir var levels_dir: String = "res://levels/"

# Ссылка на контейнер, где будут кнопки
@export var grid_container: HBoxContainer

func _ready() -> void:
	_load_levels()

func _load_levels() -> void:
	# Очищаем сетку на случай повторного вызова
	for child in grid_container.get_children():
		child.queue_free()
	
	var dir = DirAccess.open(levels_dir)
	if dir:
		var files: PackedStringArray = dir.get_files()
		for file_name in files:
			# Учитываем особенности экспорта (tres или remap для импортированных ресурсов)
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".remap")):
				var clean_path = levels_dir + '/' +file_name.replace(".remap", "")
				var resource = load(clean_path)
				
				if resource is GameConfig:
					_create_level_button(resource, clean_path)
	else:
		print("Ошибка: Не удалось открыть папку ", levels_dir)

func _create_level_button(config: GameConfig, path: String) -> void:
	var btn = Button.new()
	
	# Текст на кнопке (берём имя файла или можно добавить поле 'level_name' в сам ресурс)
	var level_name = path.get_file().get_basename().capitalize()
	btn.text = level_name
	
	# --- Стилизация кнопки (Красивости) ---
	btn.custom_minimum_size = Vector2(200, 150) # Размер "карточки" уровня
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Пример добавления иконки, если в вашем GameConfig есть поле icon
	# if config.has_method("get_icon"): btn.icon = config.icon 
	
	# Логика при нажатии
	btn.pressed.connect(func(): _on_level_pressed(config))
	
	grid_container.add_child(btn)

func _on_level_pressed(config: GameConfig) -> void:
	print("Выбран уровень с HP: ", config.health)
	ev_start_level.emit(config)
	# Здесь передаем конфиг в глобальный синглтон и меняем сцену
	# GameContext.current_config = config.clone()
	# get_tree().change_scene_to_file("res://scenes/Game.tscn")
