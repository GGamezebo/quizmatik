extends CharacterBody2D

@export var min_speed: float = 200.0
@export var max_speed: float = 400.0

func _ready():
	# Выбираем случайное направление
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Задаем начальную скорость
	velocity = direction * randf_range(min_speed, max_speed)

func _physics_process(delta):
	# move_and_collide возвращает объект KinematicCollision2D, если произошло столкновение
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		# bounce() вычисляет вектор отражения относительно нормали поверхности
		# normal — это перпендикуляр к стене, в которую мы врезались
		velocity = velocity.bounce(collision.get_normal())
		
		# Немного случайности при отскоке, чтобы полет не был зацикленным
		velocity = velocity.rotated(randf_range(-0.1, 0.1))
