extends IScene

const SCROLL_OFFSET_PARAM := &"scroll_offset"
const SCROLL_WRAP := 2.0

## Sky drift in texture widths per second. 0 keeps the sky static (menu, post battle).
@export_range(0.0, 0.2, 0.001) var sky_scroll_speed: float = 0.0
## Fountain-pen ink stains left while shots fly (battle). Safe empty default for menu.
@export var ink_blot_scene: PackedScene
@export_range(8, 300, 1) var max_ink_blots: int = 140

@onready var _sky: TextureRect = $TextureRect
@onready var _ink_layer: Node2D = $InkLayer

var _sky_material: ShaderMaterial = null
var _scroll_offset: float = 0.0


func _ready() -> void:
	_sky_material = _sky.material as ShaderMaterial
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()


func _process(delta: float) -> void:
	if _sky_material == null or is_zero_approx(sky_scroll_speed):
		return
	_scroll_offset = fmod(_scroll_offset + sky_scroll_speed * delta, SCROLL_WRAP)
	_sky_material.set_shader_parameter(SCROLL_OFFSET_PARAM, _scroll_offset)
	# sky_scroll.gdshader ping-pongs UVs across [0..2]; match that so ink sticks to the paper.
	var paper_px_per_sec := sky_scroll_speed * _sky.size.x
	var dir := 1.0 if _scroll_offset >= 1.0 else -1.0
	_ink_layer.position.x += dir * paper_px_per_sec * delta


func spawn_ink_blot(global_pos: Vector2) -> void:
	if ink_blot_scene == null or _ink_layer == null:
		return
	while _ink_layer.get_child_count() >= max_ink_blots:
		var oldest: Node = _ink_layer.get_child(0)
		_ink_layer.remove_child(oldest)
		oldest.queue_free()
	var blot: InkBlot = ink_blot_scene.instantiate() as InkBlot
	if blot == null:
		return
	_ink_layer.add_child(blot)
	blot.setup(_ink_layer.to_local(global_pos))


func _fit_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_sky.position = Vector2.ZERO
	_sky.size = viewport_size

	for child in get_children():
		if child is GPUParticles2D:
			child.position = Vector2(viewport_size.x + 520.0, viewport_size.y * 0.5)
