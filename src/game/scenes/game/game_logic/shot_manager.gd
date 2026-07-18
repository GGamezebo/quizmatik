extends Node

@export var shot_scene: PackedScene
@export var explosion_scene: PackedScene
@export var game_events: GameEvents
@export var air_plane: AirPlane

func _ready() -> void:
	air_plane.ev_shoot.connect(_on_air_plane_ev_shoot)

func _on_air_plane_ev_shoot(position: Vector2) -> void:
	game_events.ev_shoot.emit()
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.init(position)
		shot.ev_explosion.connect(_on_explosion)
		owner.add_child(shot)
		
func _on_explosion(answer: Answer, hit_point: Vector2) -> void:
	Explosion.spawn_attached(explosion_scene, answer, hit_point)
	game_events.ev_explosion.emit(answer, hit_point)
