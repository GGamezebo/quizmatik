extends Control

signal ev_buy(plane_id: String)
signal ev_equip(plane_id: String)

@export var preview: TextureRect
@export var name_label: Label
@export var badge_label: Label
@export var status_label: Label
@export var action_button: Button
@export var abilities_label: Label

var plane_id: String = PlaneCatalog.STARTER_ID


func _ready() -> void:
	if action_button:
		action_button.pressed.connect(_on_action)


func setup(id: String, unlocked: bool, equipped: bool, gold: int, exam_passed: bool) -> void:
	plane_id = id
	var def: Dictionary = PlaneCatalog.get_def(id)
	if preview:
		PlaneCatalog.apply_preview(preview, id)
	if name_label:
		name_label.text = String(def.get("name", id))
	var badge := String(def.get("badge", ""))
	if badge_label:
		badge_label.text = badge
		badge_label.visible = not badge.is_empty()
	if abilities_label:
		abilities_label.text = _abilities_text(def)
	var cost: int = int(def.get("gold_cost", 0))
	if equipped:
		status_label.text = "Выбран"
		action_button.text = "В полёте"
		action_button.disabled = true
	elif unlocked:
		status_label.text = "Открыт"
		action_button.text = "Выбрать"
		action_button.disabled = false
	else:
		var bits: PackedStringArray = []
		if cost > 0:
			bits.append("%d зол." % cost)
		if exam_passed:
			bits.append("экзамен сдан")
		elif not String(def.get("exam_container_id", "")).is_empty():
			bits.append("или экзамен")
		status_label.text = " · ".join(bits)
		var can_buy := cost > 0 and gold >= cost
		action_button.text = "Купить" if can_buy else "Закрыт"
		action_button.disabled = not can_buy


func _abilities_text(def: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append("скорость ×%s" % str(def.get("speed_mult", 1.0)))
	var blast: int = int(def.get("blast_lanes", 0))
	if blast > 0:
		parts.append("бласт %d" % blast)
	if bool(def.get("hint_on_miss", false)):
		parts.append("подсказка")
	return " · ".join(parts)


func _on_action() -> void:
	var profiles := ProfileController.find_in_tree(get_tree())
	if profiles == null:
		return
	if profiles.is_plane_unlocked(plane_id):
		ev_equip.emit(plane_id)
	else:
		ev_buy.emit(plane_id)
