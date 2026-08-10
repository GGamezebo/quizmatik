class_name BackgroundHost
extends Node2D

## Picks and mounts a BackgroundBase variant.
## Battle: set pick_random + fill variants[] in the editor — add a new folder scene to the array to ship it.

@export var variants: Array[PackedScene] = []
@export var pick_random: bool = true
## When pick_random is false, use this index (clamped).
@export var fixed_variant_index: int = 0

@export_group("Forwarded to variant")
@export_range(0.0, 0.2, 0.001) var sky_scroll_speed: float = 0.0
@export var paint_from_score: bool = false
@export var player: Player
@export var game_config: GameConfig
@export var paint_from_daily: bool = false
@export var daily_controller: DailyChallengesController
@export_range(0.15, 2.0, 0.05) var paint_tween_seconds: float = 0.65
@export_range(1.0, 5.0, 0.1) var paint_curve_power: float = 2.8
@export_range(0.0, 1.0, 0.01) var idle_color_amount: float = 0.1
@export var ink_blot_scene: PackedScene
@export_range(8, 300, 1) var max_ink_blots: int = 140

var _active: BackgroundBase = null


func _ready() -> void:
	_spawn_variant()


func get_active() -> BackgroundBase:
	return _active


func spawn_ink_blot(global_pos: Vector2) -> void:
	if _active != null:
		_active.spawn_ink_blot(global_pos)


func _spawn_variant() -> void:
	var packed := _pick_packed()
	if packed == null:
		push_error("BackgroundHost: no variants assigned")
		return
	var node := packed.instantiate()
	_active = node as BackgroundBase
	if _active == null:
		push_error("BackgroundHost: variant root must use BackgroundBase")
		node.queue_free()
		return
	_active.apply_host_config({
		"sky_scroll_speed": sky_scroll_speed,
		"paint_from_score": paint_from_score,
		"player": player,
		"game_config": game_config,
		"paint_from_daily": paint_from_daily,
		"daily_controller": daily_controller,
		"paint_tween_seconds": paint_tween_seconds,
		"paint_curve_power": paint_curve_power,
		"idle_color_amount": idle_color_amount,
		"ink_blot_scene": ink_blot_scene,
		"max_ink_blots": max_ink_blots,
	})
	add_child(_active)


func _pick_packed() -> PackedScene:
	var usable: Array[PackedScene] = []
	for packed in variants:
		if packed != null:
			usable.append(packed)
	if usable.is_empty():
		return null
	if pick_random:
		return usable[randi() % usable.size()]
	return usable[clampi(fixed_variant_index, 0, usable.size() - 1)]
