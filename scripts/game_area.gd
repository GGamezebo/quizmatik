extends Node

class_name GameArea
# Сигнал для UI, если зона вдруг изменится (например, при смене разрешения)
signal boundary_changed(new_rect)

# Текущая игровая зона
var gameplay_area: Rect2

func _ready():
	update_boundaries()
	# Соединяем с сигналом изменения размера окна
	get_tree().root.size_changed.connect(update_boundaries)

func update_boundaries():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Оставляем отступы (например, 50 пикселей для UI)
	var margin_top = 160.0
	var margin_bottom = 20.0
	var margin_side = 20.0
	
	gameplay_area = Rect2(
		margin_side, 
		margin_top, 
		screen_size.x - (margin_side * 2), 
		screen_size.y - margin_top - margin_bottom
	)

	boundary_changed.emit(gameplay_area)
