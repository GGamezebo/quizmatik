---
description: App-level HFSM integration (main.gd bootstrap)
paths:
  - "src/game/main.gd"
  - "src/game/hfsm/**/*"
  - "src/game/contexts/**/*"
  - "src/game/scenes/app_root/**/*"
---

# App HFSM integration

## Wiring

- Entry: `main.tscn` → `src/game/main.gd` boots HFSM (host for `HfsmSceneRegistry`)
- Config: `@export_file hfsm_config_path` → `src/game/hfsm/app_hfsm.json`
- Paths: `HfsmScenePaths` (`class_name`); entity bindings registered in `main.gd`
- Start HFSM after 2 idle frames

## Scenes (owned by HFSM)

- Root `App` mounts `app_root` → `app_root/root.tscn` (account/progress/music + RootEvents bridge)
- `scene.on_event`: `ev.open_menu` (Menu)
- Phase scenes: `menu` / `game` / `post_battle`
- Bridge: `RootEvents.ev_*` → `hfsm.add_event(...)` lives on **app_root** scene — not on `main.gd`
- No `AppRootEntity.host` — app root is a normal `IScene`

## Platform BoundEntity contexts

- `AppRoot.initialize()` always emits `ev.open_platform` with payload `{ root_events, platform_services, music_player }`; AppRoot never checks platform features
- Tree: `App/Platform` (`PlatformRouterContext`: `web` → `ev.open_web`, `android` → `ev.open_android`, `pc` → `ev.open_desktop`) → `WEB` (`WEBContext`) → `Yandex` (`yandex_games`); `Android` (`AndroidContext`) → `GooglePlay` (`google_play`); `Desktop` (`DesktopContext`, also editor) → `Steam` (`steam`). Store branch = export preset `custom_features`
- All platform contexts extend `PlatformContext` (`src/game/contexts/`): payload → `root_events` / `services`; setup in `_enter()` (called from `sync_hfsm`); open child via `open_child(ev)` (same payload). Never `add_event` from `_init` (HFSM not bound yet → dropped)
- New platform/store = new nested state + `PlatformContext` subclass + register in `main.gd` `context` slot; never branch existing contexts or game code
- Game ↔ platform only via `PlatformServices` (`src/common/platform/platform_services.tres`): caps `can_interstitial` / `can_rewarded` (set only by contexts via `set_ads`, reset in `deinit`), requests `ev_request_interstitial` / `ev_request_rewarded(placement)`, answer `ev_rewarded_result(placement, is_granted)` (always sent). Default `.tres` = caps off → game hides ad entry points
- Platform pause (tab hidden, SDK pause, ad open) → `root_events.ev_app_visibility_changed`
- `WEBContext`: `document.visibilitychange` (JS callback kept in member, removed in `deinit`)
- `YandexContext`: `YaGames.init()` (`/sdk.js` via Web-Yandex preset `head_include`) → `LoadingAPI.ready()` once after SDK up **and** `ev.open_menu`; `ev_battle_started/finished` → `GameplayAPI.start/stop`; `game_api_pause/resume` + ad open/close → visibility; JS callbacks kept in arrays
- Contexts receive every HFSM event via `on_event` while active
- Heavy UI stays in scenes; BoundEntity contexts must not mount scenes

## Tutorial (parallel state)

- `App/Tutorial` scene `tutorial` (`scenes/tutorial/tutorial.tscn`, sync load), parallel to Menu/Battle
- AppRoot `_sync_tutorial()` on initialize + `ev_profiles_changed`: profile exists and `!ProgressController.is_tutorial_completed()` → `ev.open_tutorial`, else `ev.close_tutorial`
- Tutorial scene reacts to `ev.start_game` / `ev.exit_game` / `ev.open_menu` via `on_event` (re-evaluates chapter); all chapters done → `complete_tutorial()` + `ev.close_tutorial` (guarded: its own close event must not re-enter `_refresh`)

## Menu UI

- Full-screen menu windows: `WindowStackManager` inside MenuScene — not HFSM bindings

## Must

- Keep `GameManager` battle FSM separate
- New app phase → JSON `scene` + `HfsmScenePaths.PATHS` entry
