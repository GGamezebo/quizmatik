class_name HoverScaleButton
extends TextureButton

## Mouse-hover scale pop for TextureButton. Plain Button nodes use bind() / HoverScaleBinder.

const HOVER_SCALE_FACTOR: float = 1.12
const HOVER_TWEEN_DURATION: float = 0.12
const META_BOUND := &"hover_scale_bound"
const META_BASE_SCALE := &"hover_scale_base"
const META_TWEEN := &"hover_scale_tween"

var _base_scale: Vector2 = Vector2.ONE
var _hover_tween: Tween


func _ready() -> void:
	setup_hover_scale()


func setup_hover_scale() -> void:
	if has_meta(META_BOUND):
		return
	set_meta(META_BOUND, true)
	_base_scale = scale
	_update_hover_pivot()
	resized.connect(_update_hover_pivot)
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)


static func bind_tree(root: Node) -> void:
	if root == null:
		return
	if root is BaseButton:
		bind(root)
	for child in root.get_children():
		bind_tree(child)


static func bind(button: BaseButton) -> void:
	if button.has_meta(META_BOUND):
		return
	if _script_inherits_hover_scale(button.get_script()):
		return
	_install(button)


static func _script_inherits_hover_scale(script: Script) -> bool:
	var current: Script = script
	while current != null:
		if current.get_global_name() == "HoverScaleButton":
			return true
		current = current.get_base_script()
	return false


static func _install(button: BaseButton) -> void:
	button.set_meta(META_BOUND, true)
	button.set_meta(META_BASE_SCALE, button.scale)
	_update_pivot(button)
	button.resized.connect(_on_bound_resized.bind(button))
	button.mouse_entered.connect(_on_bound_entered.bind(button))
	button.mouse_exited.connect(_on_bound_exited.bind(button))


static func _on_bound_resized(button: BaseButton) -> void:
	_update_pivot(button)


static func _on_bound_entered(button: BaseButton) -> void:
	var base_scale: Vector2 = button.get_meta(META_BASE_SCALE)
	_animate_button(button, base_scale * HOVER_SCALE_FACTOR)


static func _on_bound_exited(button: BaseButton) -> void:
	var base_scale: Vector2 = button.get_meta(META_BASE_SCALE)
	_animate_button(button, base_scale)


static func _animate_button(button: BaseButton, target_scale: Vector2) -> void:
	var tween: Tween = button.get_meta(META_TWEEN) if button.has_meta(META_TWEEN) else null
	if tween:
		tween.kill()
	tween = button.create_tween()
	button.set_meta(META_TWEEN, tween)
	tween.tween_property(button, "scale", target_scale, HOVER_TWEEN_DURATION).set_ease(Tween.EASE_OUT)


static func _update_pivot(button: BaseButton) -> void:
	button.pivot_offset = button.size * 0.5


func _on_hover_entered() -> void:
	_animate_hover_scale(_base_scale * HOVER_SCALE_FACTOR)


func _on_hover_exited() -> void:
	_animate_hover_scale(_base_scale)


func _animate_hover_scale(target_scale: Vector2) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TWEEN_DURATION).set_ease(Tween.EASE_OUT)


func _update_hover_pivot() -> void:
	pivot_offset = size * 0.5
