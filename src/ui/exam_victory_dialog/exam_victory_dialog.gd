class_name ExamVictoryDialog
extends CanvasLayer

signal ev_confirmed

@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var trophy_rect: TextureRect
@export var confirm_button: BaseButton
@export var levels_config: LevelsConfig

const FADE_DURATION: float = 0.22


func _ready() -> void:
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)


func open(celebration: Dictionary) -> void:
	var container_id: String = celebration.get("container_id", "")
	var next_container_id: String = celebration.get("next_container_id", "")
	var valley_name := _container_name(container_id)
	var trophy := ValleyTrophyArt.get_trophy(container_id)

	title_label.text = "ПОЗДРАВЛЯЕМ!"
	if trophy_rect:
		trophy_rect.texture = trophy
		trophy_rect.visible = trophy != null

	if next_container_id.is_empty():
		message_label.text = (
			"Ты сдал экзамен в «%s»!\n\n"
			% valley_name
			+ "Поздравляем — все долины покорены!\n\n"
			+ "Кубок сохранён в «Достижения» на главном экране."
		)
	else:
		var next_name := _container_name(next_container_id)
		message_label.text = (
			"Ты сдал экзамен в «%s»!\n\n"
			% valley_name
			+ "Открыта новая долина: «%s».\n\n" % next_name
			+ "Кубок сохранён в «Достижения» на главном экране."
		)

	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	hide()


func _container_name(container_id: String) -> String:
	if levels_config == null or container_id.is_empty():
		return container_id
	var container: Dictionary = levels_config.find_container_in_config(container_id)
	return container.get("name", container_id)


func _on_confirm_pressed() -> void:
	close()
	ev_confirmed.emit()
