extends Area2D

signal ev_explosion(answer: Answer, hit_point: Vector2)
signal ev_ink_drip(global_pos: Vector2)

@export var speed: float = 600.0
@export var ray_cast: RayCast2D
## Distance between fountain-pen ink drips along the shot path.
@export var ink_spacing: float = 28.0
@export var ink_enabled: bool = true
@onready var visibleNotifier = $VisibleOnScreenNotifier2D

var _ink_traveled: float = 0.0


func _ready() -> void:
	visibleNotifier.screen_exited.connect(self._on_visible_on_screen_notifier_2d_screen_exited)


func init(_position: Vector2) -> void:
	self.position = _position
	_ink_traveled = 0.0


func _get_collision_point() -> Variant:
	ray_cast.force_raycast_update()
	var hit_point: Variant = null
	if ray_cast.is_colliding():
		hit_point = ray_cast.get_collision_point()
	return hit_point


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position.x += step
	if not ink_enabled:
		return
	_ink_traveled += step
	while _ink_traveled >= ink_spacing:
		_ink_traveled -= ink_spacing
		var jitter := Vector2(randf_range(-1.5, 1.5), randf_range(-5.0, 5.0))
		# Occasional skip keeps the stroke from looking too even.
		if randf() > 0.12:
			ev_ink_drip.emit(global_position + jitter)


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_area_entered(answer: Answer) -> void:
	if answer.is_in_group("answers") and answer.is_hittable():
		var collision_point = _get_collision_point()
		var hit_point: Vector2 = answer.global_position if collision_point == null else collision_point
		ev_explosion.emit(answer, hit_point)
		queue_free()
