extends CharacterBody2D

@export var min_speed: float = 200.0
@export var max_speed: float = 400.0

func _ready():
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity = direction * randf_range(min_speed, max_speed)

func _physics_process(delta):
	# move_and_collide returns KinematicCollision2D on impact
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		# Reflect velocity off the collision normal
		velocity = velocity.bounce(collision.get_normal())
		
		# Small random rotation to avoid perfectly repeating trajectories
		velocity = velocity.rotated(randf_range(-0.1, 0.1))
