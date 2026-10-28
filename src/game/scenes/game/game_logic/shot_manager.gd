extends Node

@export var shot_scene: PackedScene
@export var explosion_scene: PackedScene
@export var game_events: GameEvents
@export var air_plane: AirPlane
## Battle Background (HUD) — receives fountain-pen ink drips from shots.
@export var background: Node

var _locked: bool = false
## Equipped shot look (`apply_style`); null → classic ink.
var _style: ShotItem = null

func _ready() -> void:
	air_plane.ev_shoot.connect(_on_air_plane_ev_shoot)
	game_events.ev_lock_shoot.connect(_on_lock_shoot)

func _exit_tree() -> void:
	if game_events.ev_lock_shoot.is_connected(_on_lock_shoot):
		game_events.ev_lock_shoot.disconnect(_on_lock_shoot)

func _on_lock_shoot(locked: bool) -> void:
	_locked = locked


func apply_style(item: ShotItem) -> void:
	_style = item

func _on_air_plane_ev_shoot(position: Vector2) -> void:
	if _locked:
		return
	game_events.ev_shoot.emit()
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.init(position)
		shot.speed *= air_plane.shot_speed_mult
		if _style != null:
			shot.modulate = _style.shot_tint
			if _style.drip_spacing > 0.0:
				shot.ink_spacing = _style.drip_spacing
		shot.ev_explosion.connect(_on_explosion)
		shot.ev_target_hit.connect(_on_target_hit)
		shot.ev_ink_drip.connect(_on_ink_drip)
		owner.add_child(shot)
		_on_ink_drip(position)

func _on_ink_drip(global_pos: Vector2) -> void:
	if background != null and background.has_method("spawn_ink_blot"):
		background.spawn_ink_blot(global_pos, _style)

func _on_explosion(answer: Answer, hit_point: Vector2) -> void:
	var explosion := Explosion.spawn_attached(explosion_scene, answer, hit_point)
	if _style != null:
		explosion.modulate = _style.shot_tint
	game_events.ev_explosion.emit(answer, hit_point)

func _on_target_hit(target: Area2D, hit_point: Vector2) -> void:
	var explosion := Explosion.spawn_attached(explosion_scene, target, hit_point)
	if _style != null:
		explosion.modulate = _style.shot_tint
	game_events.ev_target_shot.emit(target, hit_point)
