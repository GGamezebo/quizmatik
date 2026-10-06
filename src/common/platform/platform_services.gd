class_name PlatformServices
extends Resource

## Game ↔ platform contract. Game reads caps + emits requests; the active HFSM platform context
## (`src/game/contexts/`) answers. Default `.tres` = no platform: caps off → game hides ad entry points.

@warning_ignore("unused_signal") signal ev_caps_changed
## Game → platform. `placement` = where in the game the ad is shown (e.g. &"post_battle").
## Interstitial only between battles, never during gameplay (Yandex / Play policy).
@warning_ignore("unused_signal") signal ev_request_interstitial(placement: StringName)
@warning_ignore("unused_signal") signal ev_request_rewarded(placement: StringName)
## Platform → game. Always answered after `ev_request_rewarded` (`is_granted` false on error / skip).
@warning_ignore("unused_signal") signal ev_rewarded_result(placement: StringName, is_granted: bool)

var can_interstitial: bool = false
var can_rewarded: bool = false


## Called only by platform contexts (on SDK ready / on deinit).
func set_ads(interstitial: bool, rewarded: bool) -> void:
	if can_interstitial == interstitial and can_rewarded == rewarded:
		return
	can_interstitial = interstitial
	can_rewarded = rewarded
	ev_caps_changed.emit()
