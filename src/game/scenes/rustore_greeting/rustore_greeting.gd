extends IScene

## `Platform/Android/RuStore/RuStoreGreeting` (RuStore build only, mounted by `RuStoreContext`): «Привет от
## разработчиков» card — thanks for playing, the studio's channels, rate / share. No menu button: pops up by itself
## on the post-battle screen of the first **won** battle once `battles_per_greeting` battles (any mode, any
## result) were started since the last greeting — every `ev.start_game` counts (menu, post-battle «replay»,
## in-battle restart); lost 20 and 21, won 22 → shown after 22, count starts over (per device, `STATE_PATH`).
## Dev: editor `Desktop/DevGreeting` mounts the same scene with payload `auto_popup` false — shown only by the lab button (`PlatformServices.ev_request_dev_greeting`); lab «19 БОЁВ»
## (`ev_dev_add_greeting_battles`) adds battles and turns counting on for that copy too. Links are opened here
## (platform scene); rate / share go through `PlatformServices` like the parents report. F6 alone = card opens.

const STATE_PATH: String = "user://rustore_greeting.json"
const SHARE_PLACEMENT := &"greeting"
## Same keys as the parents report share (`ParentsWindow.SHARE_TEXT`, `GAME_TITLE`).
const SHARE_TEXT := "Мой ребёнок тренирует счёт в игре «%s» — летает на самолётике и решает примеры. Попробуйте и вы!"
const GAME_TITLE := "Улётная математика"

@export var platform_services: PlatformServices
@export var card: GreetingCard
@export var battles_per_greeting: int = 20
## After `ev.open_post_battle`: the loading screen fades and the result settles first.
@export var show_delay_sec: float = 1.2

var _listener: EventListener = EventListener.new()
var _auto_popup: bool = true
## Battles started since the last greeting.
var _battles: int = 0
## Editor copy: counting switched on by the lab «19 БОЁВ» button.
var _is_dev_armed: bool = false
## This battle earned the greeting; shown once its post-battle screen is up.
var _is_due: bool = false


func _ready() -> void:
	card.ev_link_pressed.connect(_open_link)
	card.ev_rate_pressed.connect(_on_rate_pressed)
	card.ev_share_pressed.connect(_on_share_pressed)
	super._ready()


func initialize(data: Dictionary) -> void:
	_auto_popup = bool(data.get("auto_popup", true))
	_battles = int(ResourceUtils.load_json_dict(STATE_PATH).get("battles", 0))
	if platform_services != null:
		_listener.add(platform_services.ev_caps_changed, _refresh_caps)
		_listener.add(platform_services.ev_request_dev_greeting, card.open)
		_listener.add(platform_services.ev_dev_add_greeting_battles, _on_dev_add_battles)
	_refresh_caps()
	if _is_isolated_run():
		card.open()


func deinit() -> void:
	_listener.deinit()
	card.close()
	super.deinit()


func on_event(event_name: String, data: Dictionary) -> void:
	if not _auto_popup and not _is_dev_armed:
		return
	match event_name:
		"ev.start_game":
			_battles += 1
			_save_state()
		"ev.exit_game":
			_check_due(bool(data.get("is_win", false)))
		"ev.open_post_battle":
			_pop_up_if_due()


func _check_due(is_win: bool) -> void:
	if is_win and _battles >= battles_per_greeting:
		_battles = 0
		_is_due = true
		_save_state()


func _on_dev_add_battles(count: int) -> void:
	_is_dev_armed = true
	_battles += count
	_save_state()


func _pop_up_if_due() -> void:
	if not _is_due:
		return
	_is_due = false
	await get_tree().create_timer(show_delay_sec).timeout
	if is_inside_tree():
		card.open()


func _save_state() -> void:
	ResourceUtils.save_json(STATE_PATH, {"battles": _battles}, false)


func _refresh_caps() -> void:
	card.set_caps(
		platform_services != null and platform_services.can_rate,
		platform_services != null and platform_services.can_share,
	)


func _open_link(url: String) -> void:
	OS.shell_open(url)


func _on_rate_pressed() -> void:
	if platform_services != null:
		platform_services.ev_request_rate_page.emit()


func _on_share_pressed() -> void:
	if platform_services != null:
		platform_services.ev_request_share.emit(SHARE_PLACEMENT, tr(SHARE_TEXT) % tr(GAME_TITLE), "")
