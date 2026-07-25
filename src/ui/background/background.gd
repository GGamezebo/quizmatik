extends IScene

const SCROLL_OFFSET_PARAM := &"scroll_offset"
const SCROLL_WRAP := 2.0

## Sky drift in texture widths per second. 0 keeps the sky static (menu, post battle).
@export_range(0.0, 0.2, 0.001) var sky_scroll_speed: float = 0.0

@onready var _sky: TextureRect = $TextureRect

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

func _fit_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_sky.position = Vector2.ZERO
	_sky.size = viewport_size

	for child in get_children():
		if child is GPUParticles2D:
			child.position = Vector2(viewport_size.x + 520.0, viewport_size.y * 0.5)
