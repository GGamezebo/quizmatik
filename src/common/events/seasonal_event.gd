class_name SeasonalEvent
extends Resource

## Content of one seasonal event (Halloween, New Year, …); its dates are `EventCalendar` windows with the same `id`.
## Each won event battle opens the next gift box (`gifts` in order); a gift the pilot already owns pays its price
## instead. The last box also gives `cover` (owned → its price). With every box open, a win pays `completion_gold()`.
## The battle (`EventScenario`): the boss chases the plane for `chase_minutes(wins)`, then the boss fight.

@export var id: String = ""
## Banner title (Russian source text, translated).
@export var title: String = ""
## Box gifts in opening order (cosmetic `.tres` by uid; the shop catalog lists the same files).
@export var gifts: Array[CosmeticItem] = []
## Event background in the shop (`CoverItem.scene` = battle background with its own music); free with the last box.
@export var cover: CoverItem

@export_group("Battle")
## Event battle rules: hearts, chase pace, boss armor / rage, heart balloons. Examples and timer come from `EventScenario`.
@export var battle_template: GameConfig
## Event boss: leads the chase while the timer runs, then flies in for the fight.
@export var boss_scene: PackedScene
## The two smaller chasers beside it (other hull colors); empty → `boss_scene`.
@export var wing_scene: PackedScene
## Chase minutes of the first battle, +1 per win up to `max_chase_minutes`.
@export var chase_minutes_start: int = 1
@export var max_chase_minutes: int = 6

@export_group("Look")
## Menu event button (art, size, title color); a run may bring its own (`EventWindow.banner`).
@export var banner: EventBanner
@export var box_closed: Texture2D
## Post-battle: the box this win opened.
@export var box_open: Texture2D


func box_count() -> int:
	return gifts.size()


func gift(index: int) -> CosmeticItem:
	return gifts[index] if index >= 0 and index < gifts.size() else null


## Gold for each win once every box is open: the mean gift price.
func completion_gold() -> int:
	if gifts.is_empty():
		return 0
	var total: int = 0
	for item in gifts:
		total += item.gold_cost if item != null else 0
	return roundi(float(total) / float(gifts.size()))


## Chase timer of the next battle after `wins` won ones.
func chase_minutes(wins: int) -> int:
	return clampi(chase_minutes_start + maxi(wins, 0), chase_minutes_start, max_chase_minutes)


## Gift or cover of this event.
func has_item(item_id: String) -> bool:
	if cover != null and cover.id == item_id:
		return true
	for item in gifts:
		if item != null and item.id == item_id:
			return true
	return false
