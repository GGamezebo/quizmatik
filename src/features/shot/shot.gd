extends Area2D

signal ev_explosion(answer: Answer, hit_point: Vector2)

@export var speed: float = 600.0
@export var ray_cast: RayCast2D
@onready var visibleNotifier = $VisibleOnScreenNotifier2D


func _ready() -> void:
	visibleNotifier.screen_exited.connect(self._on_visible_on_screen_notifier_2d_screen_exited)

func init(_position:Vector2) -> void:
	self.position = _position
	
func _get_collision_point() -> Variant:
	ray_cast.force_raycast_update()
	var hit_point: Variant = null
	if ray_cast.is_colliding():
		hit_point = ray_cast.get_collision_point()
	return hit_point
	
func _physics_process(delta: float) -> void:
	position.x += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(answer: Answer) -> void:
	if answer.is_in_group("answers"): 
		var collision_point = _get_collision_point()
		var hit_point: Vector2 = answer.position if collision_point == null else collision_point
		ev_explosion.emit(answer, hit_point)
		queue_free()
