extends Label

## Укажите отступ от краев рамки (в пикселях)
@export var padding: float = 0.0

func _ready():
	# Устанавливаем точку опоры в центр, чтобы текст сжимался к середине
	# Для этого Layout должен быть центрирован
	pivot_offset = size / 2
	
	# Подписываемся на сигнал изменения размера самого Label 
	# (сработает при ресайзе окна, если Label в контейнере)
	item_rect_changed.connect(_on_resized)
	
	# Первичная настройка
	_update_best_fit()

func _on_resized():
	# Обновляем точку опоры при изменении размеров
	pivot_offset = size / 2
	_update_best_fit()

## Эту функцию вызывайте при смене текста (например, новый ответ в игре)
func set_answer_text(new_text: String):
	text = new_text
	# Ждем конца кадра, чтобы Godot обновил внутренний размер текста
	await owner.process_frame
	_update_best_fit()

func _update_best_fit():
	# Сбрасываем масштаб для замеров
	scale = Vector2.ONE
	
	# Получаем шрифт и его размер из настроек Label
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	
	# Используем TextServer для точного замера ширины текста
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# Доступная ширина (ширина самого узла Label минус паддинги)
	var available_width = size.x - (padding * 2)
	
	if text_width > available_width and available_width > 0:
		# Вычисляем коэффициент сжатия
		var fit_factor = available_width / text_width
		# Применяем масштаб (равномерно по X и Y)
		scale = Vector2(fit_factor, fit_factor)
	else:
		scale = Vector2.ONE
