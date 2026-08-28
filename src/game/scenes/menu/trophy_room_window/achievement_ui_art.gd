class_name AchievementUiArt
extends RefCounted

const BG_HANGAR: Texture2D = preload("res://src/game/scenes/menu/trophy_room_window/ui/bg_hangar_achievements.png")
const TITLE_CLOUD: Texture2D = preload("res://src/game/scenes/menu/trophy_room_window/ui/title_cloud.png")
const PANEL_CLIPBOARD: Texture2D = preload("res://src/game/scenes/menu/trophy_room_window/ui/panel_clipboard.png")
const BANNER_SECTION: Texture2D = preload("res://src/game/scenes/menu/trophy_room_window/ui/banner_section.png")
const PANEL_SCROLL: Texture2D = preload("res://src/game/scenes/menu/daily/ui/daily_scroll.png")
const SHELF_PLATFORM: Texture2D = preload("res://src/game/scenes/menu/trophy_room_window/ui/shelf_platform.png")
const PEDESTAL: Texture2D = preload("res://src/game/scenes/menu/trophy_room_window/ui/pedestal.png")

const STAT_ICONS: Dictionary = {
	"total_wins": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_wins.png"),
	"total_battles": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_battles.png"),
	"total_answers": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_answers.png"),
	"total_stars": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_stars.png"),
	"total_shoot_count": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_shots.png"),
	"total_time": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_time.png"),
	"game_sessions": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_sessions.png"),
	"avg_battle_time": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_speed.png"),
	"total_flights": preload("res://src/game/scenes/menu/trophy_room_window/ui/stat_icons/icon_flights.png"),
}


static func get_stat_icon(key: String) -> Texture2D:
	return STAT_ICONS.get(key) as Texture2D
