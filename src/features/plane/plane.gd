#@tool
class_name AirPlane
extends Area2D

#@export_tool_button("test_die") var test_die_animation = die_animation
#@export_tool_button("test_win") var test_win_animation = win_animation

signal ev_shoot
signal ev_air_plane_colladed(airPlane: AirPlane, area: Area2D)
signal ev_dead_animation_finished
signal ev_win_animation_finished

const SPEED_DEFAULTS: float = 100.0

enum MovementMode {
	DIRECT,
	DISCRETE
}

@export var components:Array[Node] = []
@export var directionComponents:Array[Node] = []
@export var animated_sprite: AnimatedSprite2D
@export var dead_animation_time = 2.5
@export var win_anticipation_animation_time: float = 0.35
@export var win_fly_animation_time: float = 1.6
@export var explosion_scene: PackedScene
@export var movement_mode: MovementMode = MovementMode.DIRECT

var direction_y: int = 0
var speed: float = SPEED_DEFAULTS
var movement: IMovementComponent = null
var discrete_positions: Array[float] = []


func initialize(_speed: float, _movement_mode=MovementMode.DIRECT) -> void:
	direction_y = 0
	speed = _speed
	movement_mode = movement_mode
	set_movement(_movement_mode)
	
func _ready() -> void:
	set_movement(movement_mode)
	
	for component in components:
		component.initialize(self)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if Input.is_action_just_pressed("shoot"):
			ev_shoot.emit(self.position + Vector2(get_size().x / 2.0, 0.0))
		
	movement.update(delta)
	for component in components:
		component.update(delta)
	
	var dirY = movement.get_direction()
	if dirY != direction_y:
		direction_y = dirY
		for component in directionComponents:
			component.setDirection(direction_y)

func set_movement(_movement_mode: MovementMode) -> void:
	if movement:
		movement.deinit()
	movement_mode = _movement_mode
	movement = MOVEMENT_COMPONENTS[movement_mode].new(self)

func set_discret_positions(positions: Array[float]) -> void:
	discrete_positions = positions

# TODO: do refactoring of this fuction and movement system
func get_discret_lane() -> int:
	return movement.current_line_index

func get_size() -> Vector2:
	# Read the current animation frame texture
	var anim_name = animated_sprite.animation
	var frame_index = animated_sprite.frame
	var texture = animated_sprite.sprite_frames.get_frame_texture(anim_name, frame_index)
	
	if texture:
		# Scale texture size by the sprite's global scale
		return texture.get_size() * animated_sprite.global_scale
	return Vector2.ZERO

func get_contact_point_with(target: Node2D) -> Vector2:
	var nose := global_position + Vector2(get_size().x * 0.5, 0.0)
	return nose.lerp(target.global_position, 0.5)

func _on_area_entered(area: Area2D) -> void:
	ev_air_plane_colladed.emit(self, area)


func _disable_collision() -> void:
	collision_layer = 0
	collision_mask = 0

func _disable() -> void:
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	_disable_collision()
	_stop()

func _stop() -> void:
	direction_y = 0
	for component in directionComponents:
		component.setDirection(0)

func die_animation() -> void:
	_disable()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", rotation + randf_range(-3, 3), dead_animation_time * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), dead_animation_time).set_ease(Tween.EASE_IN) # Shrink

	for i in range(4):
		await get_tree().create_timer(0.15).timeout # Pause between explosions
		_spawn_explosion_at_random_pos()

	_spawn_explosion_at_random_pos(Vector2.ZERO, 1.5) # Large center explosion
	animated_sprite.visible = false
	
	await tween.finished
	ev_dead_animation_finished.emit()

func win_animation() -> void:
	_disable()
	
	var screen_size := get_viewport_rect().size
	
	# Randomize flight direction: 0 = Straight, 1 = Up-Right, 2 = Down-Right
	var flight_case := randi() % 3
	
	# Calculate target X position (Always far beyond the right edge of the screen)
	var target_position := Vector2.ZERO
	target_position.x = screen_size.x + 200.0
	
	# Offset variables for the anticipation stage (Stat 1)
	var ant_offset_x: float = -40.0
	var ant_offset_y: float = 0.0
	
	# Set up flight trajectory and animations based on the randomized case
	if flight_case == 0:
		# Trajectory: STRAIGHT forward
		target_position.y = global_position.y # Maintain current altitude
		animated_sprite.play("idle")           # Keep default flight sprite
		ant_offset_y = 0.0                     # Push straight back
		
	elif flight_case == 1:
		# Trajectory: UP and RIGHT
		target_position.y = -200.0             # Fly above the top boundary
		animated_sprite.play("up")             # Tilt sprite upwards
		ant_offset_y = 20.0                    # Dip slightly down during anticipation
		
	else:
		# Trajectory: DOWN and RIGHT
		target_position.y = screen_size.y + 200.0 # Fly below the bottom boundary
		animated_sprite.play("down")           # Tilt sprite downwards
		ant_offset_y = -20.0                   # Rise slightly up during anticipation
		
	# --- STAGE 1: Small backward recoil for inertia (Anticipation effect) ---
	var anticipation_pos := global_position + Vector2(ant_offset_x, ant_offset_y)
	var anticipation_tween := create_tween()
	anticipation_tween.tween_property(self, "global_position", anticipation_pos, win_anticipation_animation_time)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	await anticipation_tween.finished

	# --- STAGE 2: Extreme afterburner acceleration ---
	var victory_tween := create_tween().set_parallel(true)
	# TRANS_EXPO + EASE_IN creates a rocket-launch effect (slow start, massive final speed)
	victory_tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Launch movement toward the right destination
	victory_tween.tween_property(self, "global_position", target_position, win_fly_animation_time)
	
	# Simulate gaining altitude/depth via dynamic scaling
	victory_tween.tween_property(self, "scale", Vector2(0.15, 0.15), win_fly_animation_time)
	
	# Handle aircraft rotation based on the flight path
	var target_rotation: float = 0.0
	if flight_case == 1:
		target_rotation = deg_to_rad(-15.0) # Nose up
	elif flight_case == 2:
		target_rotation = deg_to_rad(15.0)  # Nose down
	# For case 0 (Straight), target_rotation stays 0.0
	
	victory_tween.tween_property(self, "rotation", target_rotation, win_fly_animation_time * 0.4)
	
	# Smoothly fade out into the clouds/distance near the end of the flight
	victory_tween.tween_property(self, "modulate:a", 0.0, win_fly_animation_time - 0.1).set_delay(0.1)
	
	await victory_tween.finished
	
	ev_win_animation_finished.emit()
	
func _spawn_explosion_at_random_pos(offset = Vector2.ZERO, scale_multiplier = 1.0):
	var explosion = explosion_scene.instantiate()
	
	if offset == Vector2.ZERO:
		var sprite = animated_sprite
		var current_frame_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		
		if current_frame_texture:
			var size = current_frame_texture.get_size()
			# Random point within the current frame bounds
			offset = Vector2(
				randf_range(-size.x / 2, size.x / 2),
				randf_range(-size.y / 2, size.y / 2)
			) * scale
		
	get_parent().add_child(explosion)
	explosion.global_position = global_position + offset
	explosion.scale = Vector2(scale_multiplier, scale_multiplier)
	
	
@abstract class IMovementComponent:
	var owner = null
	var dirY = 0
	
	func _init(_owner: Node) -> void:
		owner = _owner
	
	func deinit() -> void:
		owner = null
	
	func update(_delta: float) -> void:
		pass
		
	func get_direction() -> int:
		return dirY
		
		
class DirectMovementComponent extends IMovementComponent:
	func update(delta: float) -> void:
		dirY = sign(Input.get_axis("ui_up","ui_down"))
		owner.position.y = clamp(owner.position.y + dirY * owner.speed * delta, 0, owner.get_viewport_rect().size.y)

class DiscreteMovementComponent extends IMovementComponent:
	var current_line_index: int = 0
	var target_y: float = 0.0
	
	func _init(_owner: Node) -> void:
		super._init(_owner)
		current_line_index = 0
		target_y = owner.position.y
		_update_current_line_index_by_distance()
	
	func update(delta: float) -> void:
		if Input.is_action_just_pressed("ui_up"):
			if current_line_index > 0:
				current_line_index -= 1
				target_y = owner.discrete_positions[current_line_index]
				
		elif Input.is_action_just_pressed("ui_down"):
			# Check if we can move down (last index is the bottom lane)
			if current_line_index < owner.discrete_positions.size() - 1:
				current_line_index += 1
				target_y = owner.discrete_positions[current_line_index]
		
		owner.global_position.y = move_toward(owner.global_position.y, target_y, owner.speed * delta)
		
		if owner.global_position.y == target_y:
			dirY = 0
		elif owner.global_position.y < target_y:
			dirY = 1
		else:
			dirY = -1
			
	func _update_current_line_index_by_distance() -> void:
		var closest_index: int = 0
		var min_distance: float = INF 
		
		for i in range(owner.discrete_positions.size()):
			var distance: float = abs(owner.global_position.y - owner.discrete_positions[i])
			
			# Track the closest lane position
			if distance < min_distance:
				min_distance = distance
				closest_index = i
				
		current_line_index = closest_index
	
const MOVEMENT_COMPONENTS = {
	MovementMode.DIRECT: DirectMovementComponent,
	MovementMode.DISCRETE: DiscreteMovementComponent
}
