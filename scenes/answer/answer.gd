extends Area2D

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


func setup(x:float, y:float, new_value:int) -> void:
	self.position = Vector2(x, y)
	self.value = new_value


func take_damage():
	queue_free()
