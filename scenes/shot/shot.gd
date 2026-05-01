extends Area2D

@export var speed: float = 600.0
@onready var visibleNotifier = $VisibleOnScreenNotifier2D

func _ready() -> void:
	visibleNotifier.screen_exited.connect(self.on_visible_on_screen_notifier_2d_screen_exited)

func _physics_process(delta: float) -> void:
	position.x += speed * delta

func on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	area.take_damage()
	if area.is_in_group("answers"): 
		area.take_damage()
		queue_free()
