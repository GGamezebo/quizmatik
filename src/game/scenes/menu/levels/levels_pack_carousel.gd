class_name LevelsPackCarousel
extends Control

signal ev_pack_activated(index: int)
signal ev_selection_changed(index: int)

@export var dots_container: HBoxContainer
@export var page_dot_scene: PackedScene
@export var blocked_by: Control
@export var neighbor_peek: float = 130.0
@export var side_scale: float = 0.78
@export var side_dim: Color = Color(0.74, 0.74, 0.74, 1)
@export var swipe_threshold: float = 72.0
@export var tween_duration: float = 0.28

var selected_index: int = 0

var _cards: Array[LevelContainer] = []
var _dots: Array[Control] = []
var _scroll: float = 0.0
var _drag_origin_x: float = 0.0
var _drag_offset: float = 0.0
var _dragging: bool = false
var _layout_tween: Tween


func _ready() -> void:
	resized.connect(_on_resized)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func clear_packs() -> void:
	_kill_layout_tween()
	for card in _cards:
		if is_instance_valid(card):
			if card.get_parent() == self:
				remove_child(card)
			card.free()
	_cards.clear()
	for dot in _dots:
		if is_instance_valid(dot):
			if dots_container != null and dot.get_parent() == dots_container:
				dots_container.remove_child(dot)
			dot.free()
	_dots.clear()
	_scroll = 0.0
	_drag_offset = 0.0
	_dragging = false
	selected_index = 0


func add_pack(card: LevelContainer) -> void:
	_cards.append(card)
	add_child(card)
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.size = card.custom_minimum_size
	card.pivot_offset = card.size * 0.5
	card.ignore_pointer_input()


func finalize(start_index: int = 0) -> void:
	_rebuild_dots()
	var count := _cards.size()
	if count == 0:
		return
	selected_index = posmod(start_index, count)
	_scroll = float(selected_index)
	_apply_layout()
	_refresh_dots()
	ev_selection_changed.emit(selected_index)
	call_deferred("_apply_layout")


func select_index(index: int, animate: bool = true) -> void:
	var count := _cards.size()
	if count == 0:
		return
	index = posmod(index, count)
	var target_scroll := _nearest_scroll_for(index)
	selected_index = index
	_drag_offset = 0.0
	_dragging = false
	if animate:
		_tween_scroll_to(target_scroll)
	else:
		_kill_layout_tween()
		_scroll = target_scroll
		_apply_layout()
	_refresh_dots()
	ev_selection_changed.emit(selected_index)


func _gui_input(event: InputEvent) -> void:
	if not _can_handle_input():
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			select_index(selected_index - 1)
			accept_event()
			return
		if mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			select_index(selected_index + 1)
			accept_event()
			return
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_kill_layout_tween()
			_dragging = true
			_drag_origin_x = mouse.position.x
			_drag_offset = 0.0
			accept_event()
		elif _dragging:
			_finish_drag()
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_drag_offset = motion.position.x - _drag_origin_x
		_apply_layout()
		accept_event()


func _input(event: InputEvent) -> void:
	if not _can_handle_input():
		return
	if event.is_action_pressed("ui_left"):
		select_index(selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		select_index(selected_index + 1)
		get_viewport().set_input_as_handled()


func _can_handle_input() -> bool:
	if not is_visible_in_tree():
		return false
	if blocked_by != null and blocked_by.visible:
		return false
	return true


func _finish_drag() -> void:
	_dragging = false
	var pixel_drag := _drag_offset
	var step := maxf(_spacing(), 1.0)
	_scroll -= _drag_offset / step
	_drag_offset = 0.0
	if absf(pixel_drag) < 14.0:
		var jumped := _handle_tap()
		if not jumped:
			select_index(selected_index)
		return
	var steps := roundi(-pixel_drag / step)
	if steps == 0 and absf(pixel_drag) >= swipe_threshold:
		steps = -int(signf(pixel_drag))
	select_index(selected_index + steps)


func _handle_tap() -> bool:
	var mouse_pos := get_global_mouse_position()
	var nearest_index := -1
	var nearest_dist := INF
	for i in _cards.size():
		var card := _cards[i]
		if not card.visible:
			continue
		if not card.get_global_rect().has_point(mouse_pos):
			continue
		var dist := absf(_circular_offset(i))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_index = i
	if nearest_index < 0:
		return false
	if nearest_index == selected_index:
		ev_pack_activated.emit(selected_index)
		return false
	select_index(nearest_index)
	return true


func _rebuild_dots() -> void:
	for dot in _dots:
		if is_instance_valid(dot):
			if dots_container != null and dot.get_parent() == dots_container:
				dots_container.remove_child(dot)
			dot.free()
	_dots.clear()
	if dots_container == null or page_dot_scene == null:
		return
	for i in _cards.size():
		var dot := page_dot_scene.instantiate() as Control
		dots_container.add_child(dot)
		_dots.append(dot)
		if dot.has_signal("ev_pressed"):
			dot.connect("ev_pressed", select_index.bind(i))
		elif dot is BaseButton:
			(dot as BaseButton).pressed.connect(select_index.bind(i))


func _refresh_dots() -> void:
	for i in _dots.size():
		var dot := _dots[i]
		if dot.has_method("set_current"):
			dot.call("set_current", i == selected_index)


func _tween_scroll_to(target: float) -> void:
	if is_equal_approx(target, _scroll):
		_apply_layout()
		return
	_kill_layout_tween()
	_layout_tween = create_tween()
	_layout_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_layout_tween.tween_method(_set_scroll, _scroll, target, tween_duration)


func _set_scroll(value: float) -> void:
	_scroll = value
	_apply_layout()


func _apply_layout() -> void:
	var count := _cards.size()
	if count == 0:
		return
	var step := _spacing()
	var scroll := _scroll - _drag_offset / maxf(step, 1.0)
	var center := size * 0.5
	for i in count:
		var card := _cards[i]
		var offset := _circular_offset_at(i, scroll, count)
		var weight := clampf(1.0 - absf(offset), 0.0, 1.0)
		var card_scale := lerpf(side_scale, 1.0, weight)
		card.pivot_offset = card.size * 0.5
		card.position = Vector2(
			center.x + offset * step - card.size.x * 0.5,
			center.y - card.size.y * 0.5,
		)
		card.scale = Vector2(card_scale, card_scale)
		card.modulate = side_dim.lerp(Color.WHITE, weight)
		card.z_index = int(round(10.0 - absf(offset) * 5.0))
		card.visible = absf(offset) < 1.85


func _spacing() -> float:
	var card_w := 300.0
	if not _cards.is_empty():
		var measured := _cards[0].size.x
		if measured <= 1.0:
			measured = _cards[0].custom_minimum_size.x
		if measured > 1.0:
			card_w = measured
	var adjacent := card_w * (1.0 + side_scale) * 0.66
	var visual_half := card_w * side_scale * 0.5
	var edge_spacing := size.x * 0.5 - neighbor_peek + visual_half
	if size.x > 1.0:
		return clampf(adjacent, card_w * 0.7, maxf(edge_spacing, card_w * 0.7))
	return maxf(adjacent, card_w * 0.7)


func _circular_offset(index: int) -> float:
	return _circular_offset_at(index, _scroll - _drag_offset / maxf(_spacing(), 1.0), _cards.size())


func _circular_offset_at(index: int, scroll: float, count: int) -> float:
	if count <= 0:
		return 0.0
	var raw := float(index) - scroll
	var half := float(count) * 0.5
	while raw > half:
		raw -= float(count)
	while raw <= -half:
		raw += float(count)
	return raw


func _nearest_scroll_for(index: int) -> float:
	var count := _cards.size()
	if count <= 0:
		return 0.0
	var cycle_len := float(count)
	var cycle_origin := floorf(_scroll / cycle_len) * cycle_len
	var best: float = cycle_origin + float(index)
	var left: float = best - cycle_len
	var right: float = best + cycle_len
	if absf(left - _scroll) < absf(best - _scroll):
		best = left
	if absf(right - _scroll) < absf(best - _scroll):
		best = right
	return best


func _kill_layout_tween() -> void:
	if _layout_tween != null:
		_layout_tween.kill()
		_layout_tween = null


func _on_resized() -> void:
	if _cards.is_empty():
		return
	_apply_layout()
