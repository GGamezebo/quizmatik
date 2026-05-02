extends HBoxContainer

@export var eventManager:EventManager
@export var gameManager:GameManager


func _ready() -> void:
	eventManager.ev_health_changed.connect(_on_health_changed)
	_updateState()
	
func _exit_tree() -> void:
	eventManager.ev_health_changed.disconnect(_on_health_changed)


func _updateState() -> void:
	var health:int = gameManager.health
	var child_count:int = get_child_count()
	var count:int = health - child_count
	var action = createHealth if count > 0 else removeHealth
	for _index in range(abs(count)):
		action.call()
	


func _on_health_changed(_health):
	_updateState()
	

func createHealth():
	# 1. Создаем экземпляр TextureRect
	var new_texture_rect = TextureRect.new()
	
	# 2. Загружаем и устанавливаем текстуру
	# Используй путь к своей картинке
	new_texture_rect.texture = load("res://icon.svg")
	
	# 3. Настраиваем режим растягивания (опционально)
	# KEEP_ASPECT_CENTERED полезен, чтобы картинка не сплющилась в контейнере
	new_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 4. Задаем минимальный размер, иначе HBox может сжать её в 0
	new_texture_rect.custom_minimum_size = Vector2(64, 64)
	
	# 5. Добавляем в HBoxContainer
	# Предположим, что скрипт висит на самом HBoxContainer или у тебя есть на него ссылка
	add_child(new_texture_rect)
	
	
func removeHealth():
	var child_count = get_child_count()
	if child_count > 0:
		var last_child = get_child(child_count - 1)
		last_child.queue_free()
