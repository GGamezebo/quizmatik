class_name EventEntry
extends Control

## Main-menu seasonal event banner (between the CTA row and the daily scroll; `EventMenuLayout` tightens the column
## while it shows). Visible while `events` has a run open now (UTC, `EventCalendar`) and the first flight is done.
## Look: the run's `EventBanner` (art, size, title color via `EventCalendar.run_banner`), the event's title and box art. Days / hours left, re-read every `refresh_sec`
## (the run ending while the menu is open hides the banner). Gift pile on the right: one box per box not opened yet;
## boxes opened by wins fly off when the banner shows again (held while hidden or mounting, like the daily stamps),
## then `EventsController.mark_boxes_shown`. Every box open → open box + «+N» (gold per win).
## The whole banner pulses (`pulse` on the wrapper box, the button keeps its hover scale) and glows. Press → event battle.

@export var root_events: RootEvents
@export var events: EventsController
@export var progress: ProgressController
@export var button: BaseButton
@export var banner: TextureRect
@export var title_label: Label
@export var timer_label: Label
## Pile slots in fly-off order (top of the pile first).
@export var boxes: Array[TextureRect] = []
## Every box open: open box + gold per win.
@export var done_box: Control
@export var done_open_box: TextureRect
@export var done_label: Label
@export var glow: CanvasItem
@export var pulse: UiPulse
@export var refresh_sec: float = 20.0
@export_group("Motion")
@export var fly_sec: float = 0.8
@export var fly_gap_sec: float = 0.35
@export var bob_px: float = 2.5
@export var glow_period: float = 1.6

var _listener: EventListener = EventListener.new()
var _window: EventWindow = null
var _event: SeasonalEvent = null
var _box_homes: Array[Vector2] = []
var _flying: bool = false
## Inside `refresh` (its own `visible` change re-enters through `visibility_changed`).
var _refreshing: bool = false
## First frame after mount: the menu may still open another window over this one (deferred).
var _mounting: bool = true
var _time: float = 0.0
var _glow_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for box in boxes:
		_box_homes.append(box.position)
	button.pressed.connect(_on_pressed)
	visibility_changed.connect(_on_visibility_changed)
	if root_events:
		_listener.add(root_events.ev_profiles_changed, refresh)
	var timer := Timer.new()
	timer.wait_time = refresh_sec
	timer.autostart = true
	timer.timeout.connect(refresh)
	add_child(timer)
	refresh()
	get_tree().process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _exit_tree() -> void:
	_listener.deinit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


func _on_first_frame() -> void:
	call_deferred("_on_mounted")


func _on_mounted() -> void:
	_mounting = false
	refresh()


func _on_visibility_changed() -> void:
	if is_visible_in_tree() and not _mounting:
		refresh()
	_sync_motion()


func refresh() -> void:
	if _flying or _refreshing:
		return
	_refreshing = true
	_refresh()
	_refreshing = false


func _refresh() -> void:
	_window = events.active_window() if events != null else null
	_event = events.event_of(_window) if events != null else null
	var preview: bool = events != null and events.calendar != null and events.calendar.debug_window() != null
	var shown: bool = _event != null and (preview or (progress != null and progress.is_first_flight_done()))
	visible = shown
	if not shown:
		_sync_motion()
		return
	_apply_look()
	_update_timer()
	var opened: int = events.opened_boxes(_window)
	var gone: int = events.shown_boxes(_window)
	_place_boxes(gone)
	if opened > gone and is_visible_in_tree() and not _mounting:
		_fly_boxes(gone, opened)
	else:
		_show_done(gone >= _event.box_count())
	_sync_motion()


func _apply_look() -> void:
	title_label.text = _event.title
	var look: EventBanner = events.calendar.run_banner(_window) if events.calendar != null else _event.banner
	if look != null:
		var settings: LabelSettings = title_label.label_settings
		if settings != null and settings.font_color != look.title_color:
			settings = settings.duplicate()
			settings.font_color = look.title_color
			title_label.label_settings = settings
		if look.art != null:
			banner.texture = look.art
		custom_minimum_size = look.size
		size = look.size
	for box in boxes:
		if _event.box_closed != null:
			box.texture = _event.box_closed
	if done_open_box != null and _event.box_open != null:
		done_open_box.texture = _event.box_open
	if done_label != null:
		done_label.text = "+%d" % _event.completion_gold()


## Days / hours (last day: hours / minutes) until the run ends.
func _update_timer() -> void:
	var left: int = maxi(_window.end_unix() - events.calendar.current_unix(), 0)
	@warning_ignore("integer_division")
	var days: int = left / 86400
	@warning_ignore("integer_division")
	var hours: int = (left % 86400) / 3600
	@warning_ignore("integer_division")
	var minutes: int = (left % 3600) / 60
	if days > 0:
		timer_label.text = tr("Осталось %d д %d ч") % [days, hours]
	elif hours > 0:
		timer_label.text = tr("Осталось %d ч %d мин") % [hours, minutes]
	else:
		timer_label.text = tr("Осталось %d мин") % maxi(minutes, 1)


## Boxes `gone` and later fly-off slots stay home; the first `gone` slots are already off the pile.
func _place_boxes(gone: int) -> void:
	var count: int = _event.box_count()
	for index in boxes.size():
		var box := boxes[index]
		box.visible = index >= gone and index < count
		box.position = _box_homes[index]
		box.rotation = 0.0
		box.scale = Vector2.ONE
		box.modulate.a = 1.0
		box.pivot_offset = box.size * 0.5


## Boxes `from`..`to - 1` (opened by wins) pop up and fly off one after another.
func _fly_boxes(from: int, to: int) -> void:
	_flying = true
	_show_done(false)
	var tween := create_tween().set_parallel(true)
	for index in range(from, mini(to, boxes.size())):
		var box := boxes[index]
		var delay: float = float(index - from) * fly_gap_sec
		var drift := Vector2(randf_range(10.0, 40.0), -90.0)
		tween.tween_property(box, "scale", Vector2(1.35, 1.35), fly_sec * 0.3).set_delay(delay)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(box, "position", box.position + drift, fly_sec).set_delay(delay)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(box, "rotation", randf_range(0.5, 0.9), fly_sec).set_delay(delay)
		tween.tween_property(box, "modulate:a", 0.0, fly_sec * 0.45).set_delay(delay + fly_sec * 0.55)
	tween.chain().tween_callback(_on_boxes_flown)


func _on_boxes_flown() -> void:
	_flying = false
	events.mark_boxes_shown(_window)
	refresh()


func _show_done(on: bool) -> void:
	if done_box != null:
		done_box.visible = on


## Glow + pulse while on screen; boxes bob gently.
func _sync_motion() -> void:
	var on: bool = visible and is_visible_in_tree()
	if pulse != null:
		pulse.set_active(on)
	set_process(on)
	if glow == null:
		return
	if on and (_glow_tween == null or not _glow_tween.is_valid()):
		var half: float = glow_period * 0.5
		_glow_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_glow_tween.tween_property(glow, "modulate:a", 1.0, half)
		_glow_tween.tween_property(glow, "modulate:a", 0.35, half)
	elif not on and _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null


func _process(delta: float) -> void:
	if _flying:
		return
	_time += delta
	for index in boxes.size():
		var box := boxes[index]
		if box.visible:
			box.position = _box_homes[index] + Vector2(0.0, sin(_time * 2.2 + float(index) * 1.3) * bob_px)


func _on_pressed() -> void:
	if _event == null or _window == null or root_events == null:
		return
	var config: GameConfig = EventScenario.build(_event, _window, events.wins(_window.key()), progress)
	root_events.ev_start_game.emit({"custom_battle": config})
