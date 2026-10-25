class_name ExamVictoryDialog
extends CanvasLayer

signal ev_confirmed

@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var trophy_rect: TextureRect
@export var confirm_button: BaseButton
@export var levels_config: LevelsConfig
@export_group("New record mode")
## «НОВЫЙ РЕЖИМ!» card: the valley opened its record battle (`LevelsConfig.get_record_operation`).
@export var record_card: Control
@export var record_name_label: Label
@export var record_name_format: String = "Бой на рекорд времени: %s"
## Wobbles while the card is shown.
@export var record_icon: Control
## One burst when the card pops in.
@export var record_confetti: CPUParticles2D
@export var record_pop_delay: float = 0.45

const FADE_DURATION: float = 0.22

var _record_tweens: Array[Tween] = []


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
	# With the record card below, the lines go without blank rows (the dialog must fit the screen).
	var all_passed: bool = bool(celebration.get("all_exams_passed", next_container_id.is_empty()))
	if all_passed and has_record:
		message_label.text = tr("Ты сдал экзамен в «%s»!\nВсе долины покорены! Кубок сохранён в профиле.") % valley_name
	elif all_passed:
		message_label.text = tr(
			"Ты сдал экзамен в «%s»!\n\nПоздравляем — все долины покорены!\n\nКубок сохранён в профиле."
		) % valley_name
	elif has_record:
		message_label.text = tr("Ты сдал экзамен в «%s»!\nКубок сохранён в профиле.") % valley_name
	else:
		message_label.text = tr("Ты сдал экзамен в «%s»!\n\nКубок сохранён в профиле.") % valley_name

	_show_record_card(has_record, container_id)

	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	_stop_record_tweens()
	hide()


func _show_record_card(has_record: bool, container_id: String) -> void:
	_stop_record_tweens()
	if record_card == null:
		return
	record_card.visible = has_record
	if not has_record:
		return
	if record_name_label:
		record_name_label.text = tr(record_name_format) % tr(ValleyTrophyArt.get_short_name(container_id))
	# Keeps its place in the layout while hidden, then pops in after the dialog fades.
	record_card.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(record_pop_delay)
	tween.tween_callback(_pop_record_card)
	_record_tweens.append(tween)


func _pop_record_card() -> void:
	record_card.pivot_offset = record_card.size * 0.5
	record_card.scale = Vector2(0.4, 0.4)
	var pop := create_tween().set_parallel()
	pop.tween_property(record_card, "modulate:a", 1.0, 0.15)
	pop.tween_property(record_card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_record_tweens.append(pop)
	if record_confetti:
		record_confetti.restart()
	if record_icon:
		record_icon.pivot_offset = record_icon.size * Vector2(0.5, 0.6)
		var wobble := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		wobble.tween_property(record_icon, "rotation", 0.14, 0.45)
		wobble.tween_property(record_icon, "rotation", -0.14, 0.9)
		wobble.tween_property(record_icon, "rotation", 0.0, 0.45)
		wobble.tween_interval(0.6)
		_record_tweens.append(wobble)


func _stop_record_tweens() -> void:
	for tween in _record_tweens:
		if tween.is_valid():
			tween.kill()
	_record_tweens.clear()
	if record_icon:
		record_icon.rotation = 0.0
	if record_card:
		record_card.scale = Vector2.ONE


func _container_name(container_id: String) -> String:
	if levels_config == null or container_id.is_empty():
		return container_id
	var container: Dictionary = levels_config.find_container_in_config(container_id)
	return container.get("name", container_id)


func _on_confirm_pressed() -> void:
	close()
	ev_confirmed.emit()
