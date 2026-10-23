class_name PaywallDialog
extends CanvasLayer

## The store's single offer, written for the parent: big scrolling card with the active pilot's progress
## (time, solved, levels, first-try %, weak examples — hidden for a fresh pilot) and, for `unlock_kinds`,
## what the purchase opens (paid valleys, record battle, magister trial, perks); price + «Купить» stay
## pinned under the scroll. Buy → owner runs the parental gate + purchase and reports back via
## `set_waiting` / `show_result`; success → thank-you page («Оценить игру» → `ev_rate_pressed`).
## Opened from a valley → that valley on top (art, name, what is inside) for the kid.

signal ev_buy_pressed
signal ev_rate_pressed

@export var progress: ProgressController
@export var levels_config: LevelsConfig
@export var offer_board: OfferBoard
## Offers that open content → «Что откроет полная версия» section.
@export var unlock_kinds: Array[StringName] = [&"full_version"]
@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var status_label: Label
@export var buy_button: Button
@export var close_button: BaseButton
@export var scroll: ScrollContainer
## Cream fade over the scroll's bottom edge: «there is more below», hidden at the end.
@export var scroll_fade: Control
@export_group("Valley")
@export var valley_box: Control
@export var valley_art: TextureRect
@export var valley_name_label: Label
@export var valley_info_label: Label
@export_group("Progress")
@export var progress_box: Control
@export var progress_header: Label
@export var time_tile: PaywallStatTile
@export var solved_tile: PaywallStatTile
@export var levels_tile: PaywallStatTile
@export var accuracy_tile: PaywallStatTile
@export var facts_box: Control
@export var fact_chips: Container
@export var fact_chip_scene: PackedScene
@export_group("Unlocks")
@export var unlocks_box: Control
@export var valley_cards: Container
@export var valley_card_scene: PackedScene
@export_group("Thanks")
@export var offer_page: Control
@export var thanks_page: Control
@export var thanks_label: Label
@export var rate_button: Button
@export var rate_hint: Label
@export var play_button: Button

const FADE_DURATION: float = 0.2
const FACTS_SHOWN: int = 4
## offer kind → [title, message, thank-you line] (Russian source, auto-translated by Label).
const TEXTS: Dictionary = {
	&"full_version": [
		"Полная версия",
		"Ребёнок учится считать, играя. Полная версия открывает всю игру — от сложения до смешанных примеров.",
		"Полная версия открыта навсегда: все долины, бой на рекорд времени и испытание магистра.",
	],
	&"no_ads": [
		"Без рекламы",
		"Реклама между полётами больше не появится. Одна покупка — навсегда.",
		"Реклама больше не появится — навсегда.",
	],
}
const PROGRESS_HEADER := "Успехи пилота «%s»"
## What a valley holds: its exam gives a plane, the last one a trophy.
const VALLEY_INFO_PLANE := "20 уровней, экзамен и новый самолёт!"
const VALLEY_INFO_TROPHY := "20 уровней, экзамен и кубок!"

var _kind: StringName = &""


func _ready() -> void:
	hide()
	buy_button.pressed.connect(ev_buy_pressed.emit)
	close_button.pressed.connect(close)
	rate_button.pressed.connect(ev_rate_pressed.emit)
	play_button.pressed.connect(close)
	var bar := scroll.get_v_scroll_bar()
	bar.value_changed.connect(_update_fade.unbind(1))
	bar.changed.connect(_update_fade)


## `container_id` = valley the player tapped ("" = none: settings / parents button).
func open(kind: StringName, price: String, container_id: String = "") -> void:
	if not TEXTS.has(kind):
		push_warning("PaywallDialog: no texts for offer %s" % kind)
		return
	_kind = kind
	var texts: Array = TEXTS[kind]
	title_label.text = texts[0]
	message_label.text = texts[1]
	_show_valley(container_id)
	_rebuild_progress()
	_rebuild_unlocks(kind)
	buy_button.text = tr("Купить за %s") % price if not price.is_empty() else "Купить"
	status_label.text = ""
	set_waiting(false)
	offer_page.show()
	thanks_page.hide()
	scroll.scroll_vertical = 0
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION)


func close() -> void:
	hide()


func set_waiting(is_waiting: bool) -> void:
	buy_button.disabled = is_waiting
	close_button.disabled = is_waiting
	if is_waiting:
		status_label.text = "Подождите…"


## `can_rate` = the store can show its rating page → «Оценить игру» on the thank-you page.
func show_result(is_success: bool, can_rate: bool = false) -> void:
	set_waiting(false)
	if not is_success:
		status_label.text = "Покупка не завершена. Попробуйте ещё раз."
		return
	thanks_label.text = TEXTS[_kind][2]
	rate_button.visible = can_rate
	rate_hint.visible = can_rate
	offer_page.hide()
	thanks_page.modulate.a = 0.0
	thanks_page.show()
	create_tween().tween_property(thanks_page, "modulate:a", 1.0, FADE_DURATION * 2.0)


## Store accepted the payment but has not settled it (cash / slow card): no second «Купить».
func show_pending() -> void:
	set_waiting(false)
	buy_button.disabled = true
	status_label.text = "Оплата ещё обрабатывается. Покупка откроется сама, как только магазин её подтвердит."


func _pdata() -> PData:
	return progress.pdata


func _show_valley(container_id: String) -> void:
	var container: Dictionary = {}
	if not container_id.is_empty():
		container = levels_config.find_container_in_config(container_id)
	valley_box.visible = not container.is_empty()
	if container.is_empty():
		return
	valley_art.texture = LevelPackArt.get_art(container_id)
	valley_name_label.text = String(container.get("name", ""))
	valley_info_label.text = _valley_info(container_id)


func _valley_info(container_id: String) -> String:
	return VALLEY_INFO_TROPHY if PlaneCatalog.plane_id_for_exam(container_id).is_empty() else VALLEY_INFO_PLANE


func _rebuild_progress() -> void:
	var live := _pdata()
	var stats := live.statistics
	progress_box.visible = stats.total_answers > 0
	if not progress_box.visible:
		return
	progress_header.text = tr(PROGRESS_HEADER) % ProfileController.display_name_or_default(live.display_name)
	time_tile.set_value(ProgressStatistics.format_hours_minutes(stats.battle_total_time))
	solved_tile.set_value(str(stats.total_answers))
	var levels_done := 0
	for container_data in levels_config.levels.get("containers", []):
		levels_done += progress.completed_levels_count(String(container_data.get("container_id", "")))
	levels_tile.set_value(str(levels_done))
	var percent := stats.first_try_percent()
	accuracy_tile.visible = percent >= 0
	accuracy_tile.set_value("%d%%" % percent)
	_clear(fact_chips)
	for key in live.mistakes.top_keys(FACTS_SHOWN):
		var chip: Label = fact_chip_scene.instantiate()
		chip.text = MathFact.display_with_answer(key)
		fact_chips.add_child(chip)
	facts_box.visible = fact_chips.get_child_count() > 0


func _rebuild_unlocks(kind: StringName) -> void:
	_clear(valley_cards)
	unlocks_box.visible = unlock_kinds.has(kind)
	if not unlocks_box.visible:
		return
	var difficulty := StringName(_pdata().difficulty)
	for container_data in levels_config.levels.get("containers", []):
		var container_id := String(container_data.get("container_id", ""))
		if offer_board == null or not offer_board.is_container_paywalled(container_id, difficulty):
			continue
		var card: PaywallValleyCard = valley_card_scene.instantiate()
		valley_cards.add_child(card)
		card.setup(container_id, String(container_data.get("name", container_id)), _valley_info(container_id))
	valley_cards.visible = valley_cards.get_child_count() > 0


func _update_fade() -> void:
	var bar := scroll.get_v_scroll_bar()
	scroll_fade.visible = bar.value + bar.page < bar.max_value - 4.0


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()
