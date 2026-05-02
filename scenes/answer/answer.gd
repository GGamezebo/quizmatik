extends Area2D

class_name Answer

signal ev_killed(answer:Answer)

var value: int = 0:
	set(new_value):
		value = new_value
		$Label.text = str(value)
		
var speed = 50


func _process(delta):
	position.x -= speed * delta
	
	# Удаляем, если вылетел за экран
	if position.x < -100:
		queue_free()
		
	$Sprite2D.rotation += delta


func setup(x:float, y:float, new_value:int) -> void:
	self.position = Vector2(x, y)
	self.value = new_value

func _disable_collision():
	collision_layer = 0
	collision_mask = 0

func take_damage():
	self._disable_collision()
	
	var tween = create_tween().set_parallel(true)
	
	# Плавное исчезновение
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	# Небольшое увеличение
	tween.tween_property(self, "scale", scale * 1.5, 0.5)
	# Сдвиг вверх
	tween.tween_property(self, "position:y", position.y, 0.5)
   	
   	# Удаляем объект после завершения анимации
	tween.chain().tween_callback(queue_free)

func _exit_tree() -> void:
	ev_killed.emit(self)
