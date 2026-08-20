class_name ConfirmDialog
extends CanvasLayer

signal ev_confirmed
signal ev_canceled

@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var confirm_button: BaseButton
@export var cancel_button: BaseButton

const FADE_DURATION: float = 0.22


func _ready() -> void:
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func open(
	title: String,
	message: String,
	_confirm_text: String = "ОК",
	_cancel_text: String = "Отмена",
) -> void:
	title_label.text = title
	message_label.text = message
	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	hide()


func _on_confirm_pressed() -> void:
	close()
	ev_confirmed.emit()


func _on_cancel_pressed() -> void:
	close()
	ev_canceled.emit()
