class_name ExamVictoryDialog
extends CanvasLayer

signal ev_confirmed

@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var trophy_rect: TextureRect
@export var confirm_button: BaseButton
@export var levels_config: LevelsConfig
@export_group("New modes")
## «НОВЫЕ РЕЖИМЫ!» card: icon + name per mode the exam opened — the valley record battle
## (`LevelsConfig.get_record_operation`) and the expert trial (every first exam pass, `ProgressController.is_expert_unlocked`).
@export var modes_card: Control
@export var modes_heading: Label
@export var heading_one: String = "НОВЫЙ РЕЖИМ!"
@export var heading_many: String = "НОВЫЕ РЕЖИМЫ!"
## Hidden for a valley without a record battle (mix); the expert trial always shows.
@export var record_mode: Control
## Wobble while the card is shown (hidden modes skipped).
@export var mode_icons: Array[Control] = []
## One burst each when the card pops in.
@export var mode_confetti: Array[CPUParticles2D] = []
@export var modes_pop_delay: float = 0.45

const FADE_DURATION: float = 0.22

var _mode_tweens: Array[Tween] = []


func _ready() -> void:
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)


func open(celebration: Dictionary) -> void:
	var container_id: String = celebration.get("container_id", "")
	var next_container_id: String = celebration.get("next_container_id", "")
	var valley_name := tr(_container_name(container_id))
	var trophy := ValleyTrophyArt.get_trophy(container_id)
	var has_record: bool = levels_config != null and levels_config.get_record_operation(container_id) != 0

	title_label.text = "ПОЗДРАВЛЯЕМ!"
	if trophy_rect:
		trophy_rect.texture = trophy
		trophy_rect.visible = trophy != null

	# HARD opens valleys in any order: «all conquered» only once every exam is passed.
	# The modes card is always below → lines go without blank rows (the dialog must fit the screen).
	var all_passed: bool = bool(celebration.get("all_exams_passed", next_container_id.is_empty()))
	if all_passed:
		message_label.text = tr("Ты сдал экзамен в «%s»!\nВсе долины покорены! Кубок сохранён в профиле.") % valley_name
	else:
		message_label.text = tr("Ты сдал экзамен в «%s»!\nКубок сохранён в профиле.") % valley_name

	_show_modes_card(has_record)

	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	_stop_mode_tweens()
	hide()


func _show_modes_card(has_record: bool) -> void:
	_stop_mode_tweens()
	if modes_card == null:
		return
	modes_card.visible = true
	if record_mode:
		record_mode.visible = has_record
	if modes_heading:
		modes_heading.text = heading_many if has_record else heading_one
	# Keeps its place in the layout while hidden, then pops in after the dialog fades.
	modes_card.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(modes_pop_delay)
	tween.tween_callback(_pop_modes_card)
	_mode_tweens.append(tween)


func _pop_modes_card() -> void:
	modes_card.pivot_offset = modes_card.size * 0.5
	modes_card.scale = Vector2(0.4, 0.4)
	var pop := create_tween().set_parallel()
	pop.tween_property(modes_card, "modulate:a", 1.0, 0.15)
	pop.tween_property(modes_card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_mode_tweens.append(pop)
	for confetti in mode_confetti:
		if confetti and confetti.is_visible_in_tree():
			confetti.restart()
	var rest_first := false
	for icon in mode_icons:
		if icon and icon.is_visible_in_tree():
			_wobble(icon, rest_first)
			rest_first = not rest_first


## Neighbours swing in turn: the second one rests first.
func _wobble(icon: Control, rest_first: bool) -> void:
	icon.pivot_offset = icon.size * Vector2(0.5, 0.6)
	var wobble := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if rest_first:
		wobble.tween_interval(0.9)
	wobble.tween_property(icon, "rotation", 0.14, 0.45)
	wobble.tween_property(icon, "rotation", -0.14, 0.9)
	wobble.tween_property(icon, "rotation", 0.0, 0.45)
	if not rest_first:
		wobble.tween_interval(0.9)
	_mode_tweens.append(wobble)


func _stop_mode_tweens() -> void:
	for tween in _mode_tweens:
		if tween.is_valid():
			tween.kill()
	_mode_tweens.clear()
	for icon in mode_icons:
		if icon:
			icon.rotation = 0.0
	if modes_card:
		modes_card.scale = Vector2.ONE


func _container_name(container_id: String) -> String:
	if levels_config == null or container_id.is_empty():
		return container_id
	var container: Dictionary = levels_config.find_container_in_config(container_id)
	return container.get("name", container_id)


func _on_confirm_pressed() -> void:
	close()
	ev_confirmed.emit()
