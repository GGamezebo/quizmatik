# Profiles, planes, gold, splashes

Source of truth for this feature set. Keep in sync with `.cursor/rules/` when implementing.

## Save (v3)

Envelope:

- `active_profile_id: String`
- `profiles: Dictionary[id → profile payload]`

Payload = current `PData.to_dict()` plus `name`, `gender` (`boy`/`girl`), `age`, `gold`, `equipped_plane_id`, `unlocked_planes`.

Live `persistent_data.tres` is **the active profile**. Switch = stash active → `apply_dict` other slot.

Migrate v2→v3: if save has `levels` and no `profiles`, wrap as one profile (name «Пилот», gender `boy`, age 8, plane `starter`, gold 0). Empty new save → no profiles.

Max **4** profiles. Cannot delete the last one (delete = wipe that slot’s progress).

Settings «Сбросить прогресс» is removed. Editor lab **СБРОСИТЬ ПРОГРЕСС** wipes every profile (empty envelope) and reopens the first-run overlay.

## First launch

If `profiles` empty after load: blocking overlay (not window stack). Gender + age required; name optional. Cannot dismiss without creating.

## Age → valley difficulty

Campaign only (`game.gd` after level duplicate / early exam):

- 4–7 → `BattleDifficulty.EASY`
- 8–10 → `BattleDifficulty.NORMAL`
- 11+ → `BattleDifficulty.HARD`

Training keeps its own presets.

## Gold

5/5 daily slots **first time that UTC day** → `gold += 1` (`daily.reward_claimed`). Splash «Молодец! +1 золотая».

## Planes

| id | Color | Speed vs 600 | Extra | Unlock |
|---|---|---|---|---|
| starter | purple-tint | 0.65× | — | always |
| fast | current | 1.0× | «быстрый» | 1 gold or addition exam |
| green | green | 1.15× | blast 1 lane | 5 gold or subtraction exam |
| red | red | 1.15× | blast 1 + hint on miss | 10 gold or multiplication exam |
| gold | gold | 1.3× | blast 2 lanes + hint | 20 gold or division exam |

Each tier includes previous abilities. Mix exam does not grant a plane. Buy early allowed. Equipped plane applies in campaign **and** training.

Blast: if the correct balloon is in hit lane ± radius, count as correct (forgiving aim).

## UI

- Main menu: circle icon → `profile_window/`
- Profile: avatar, name, age, gold, plane → hangar, cup → trophy room, CRUD list
- Hangar: `plane_hangar_window/`
- Splashes: `src/ui/celebration_splash/` queue on AppRoot (`valley` / `plane` / `daily_gold`)

## Placement

- `ProfileController` → `src/game/account/`
- Catalog → `src/features/plane/plane_catalog.gd`
- Windows → `src/game/scenes/menu/profile_window/`, `plane_hangar_window/`
- Overlay create + splash → not on `WindowStackManager`
