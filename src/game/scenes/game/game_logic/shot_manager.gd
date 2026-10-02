extends Node

@export var shot_scene: PackedScene
@export var explosion_scene: PackedScene
@export var game_events: GameEvents
@export var air_plane: AirPlane
## Battle Background (HUD) — receives fountain-pen ink drips from shots.
@export var background: Node

var _locked: bool = false

func _ready() -> void:
	air_plane.ev_shoot.connect(_on_air_plane_ev_shoot)
	game_events.ev_lock_shoot.connect(_on_lock_shoot)

func _exit_tree() -> void:
	if game_events.ev_lock_shoot.is_connected(_on_lock_shoot):
		game_events.ev_lock_shoot.disconnect(_on_lock_shoot)

func _on_lock_shoot(locked: bool) -> void:
	_locked = locked

func _on_air_plane_ev_shoot(position: Vector2) -> void:
	if _locked:
		return
	game_events.ev_shoot.emit()
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.init(position)
		shot.speed *= air_plane.shot_speed_mult
		shot.ev_explosion.connect(_on_explosion)
		shot.ev_ink_drip.connect(_on_ink_drip)
		owner.add_child(shot)
		_on_ink_drip(position)

func _on_ink_drip(global_pos: Vector2) -> void:
	if background != null and background.has_method("spawn_ink_blot"):
		background.spawn_ink_blot(global_pos)

func _on_explosion(answer: Answer, hit_point: Vector2) -> void:
	Explosion.spawn_attached(explosion_scene, answer, hit_point)
	game_events.ev_explosion.emit(answer, hit_point)
