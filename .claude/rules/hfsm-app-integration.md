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
- Tree: `App/Platform` (`PlatformRouterContext`: `web` → `ev.open_web`, `android` → `ev.open_android`, `pc` → `ev.open_desktop`) → `WEB` (`WEBContext`) → `Yandex` (`yandex_games`) → `YandexShop` + `YandexCloudSave` | `CrazyGames` (`crazygames`) → `CrazyGamesShop` + `CrazyGamesCloudSave` | `Poki` (`poki`) → `PokiShop`; `Android` (`AndroidContext`) → `GooglePlay` (`google_play`) → `GooglePlayShop` + `GooglePlayCloudSave` | `RuStore` (`rustore`, `RuStoreContext`) → `RuStoreShop` (no cloud save) | `AndroidDevShop` (`dev_shop`, `ev.open_dev_shop`, fake Play shop = `DevShopContext` model play; state names are global → never a second `DevShop`); `Desktop` (`DesktopContext`, also editor) → `Steam` (`steam`) / editor `DevShop`. Store branch = export preset `custom_features`; `*Shop` (enter `ev.open_shop`) only via `PlatformContext.open_shop()`; shops mount `App/Monetization` (`ev.open_monetization`) — `monetization.md`
- All platform contexts extend `PlatformContext` (`src/game/contexts/`): payload → `root_events` / `services`; setup in `_enter()` (called from `sync_hfsm`); open child via `open_child(ev, extra = {})` (same payload + extra). Never `add_event` from `_init` (HFSM not bound yet → dropped)
- New platform/store = new nested state + `PlatformContext` subclass + register in `main.gd` `context` slot; never branch existing contexts or game code
- Game ↔ platform only via `PlatformServices` (`src/common/platform/platform_services.tres`): caps `can_interstitial` / `can_rewarded` (set only by contexts via `set_ads`, reset in `deinit`), requests `ev_request_interstitial` / `ev_request_rewarded(placement)`, answer `ev_rewarded_result(placement, is_granted)` (always sent); purchase `offer_kind` / `offer_price` / `is_content_locked` + `ev_request_purchase` / `ev_purchase_result` (or `ev_purchase_pending`); `language` via `set_language` + offered UI languages `languages` via `set_languages` (both → `ev_language_changed`, reset in `deinit`; Yandex = ru+en, RuStore = ru, others = all) → `LocaleController` / `LanguagePicker` (`localization.md`). Default `.tres` = caps off → game hides ad entry points
- Store rating: `can_rate` via `set_rate` (reset in `deinit`) + `ev_request_review` (store's in-app sheet, store decides via quota, no answer, never from a button) / `ev_request_rate_page` (button → store page). Play: `GooglePlayContext` and fake `DevShopContext` (model play) → `PlayRating` (`src/game/contexts/play_rating.gd`: Play Core `ReviewManager` via `JavaClassWrapper` + `AndroidRuntime.getActivity()`, `Task` polled on the game thread; `market://` page). Library `com.google.android.play:review` only via first-party export plugin `addons/play_review_deps/` (presets with `google_play` / `dev_shop`) — the one own folder in `addons/`
- Share: `can_share` via `set_share` (reset in `deinit`) + `ev_request_share(placement, text, image_path)` (no answer; `image_path` = `user://` PNG or ""). Contexts append their store link tagged `AndroidShare.tagged_url` (`utm_source=share&utm_campaign=<placement>`) and open `AndroidShare` (`src/game/contexts/android_share.gd`, `JavaClassWrapper` from the game thread — never `runOnUiThread` with a GDScript callable (freezes); no plugin: image → Godot lib's own `FileProvider` `<package>.fileprovider` (files dir only) + `ShareCompat$IntentBuilder` stream + text; no image / failure → `ACTION_SEND` text chooser; off Android → clipboard). On: `GooglePlayContext` (Play page), `RuStoreContext` (RuStore page), `DevShopContext` model play. Off on portals (Yandex / CrazyGames / Poki forbid outside links), Steam, testers. Emit only from behind a `ParentalGate` (parents report, purchase thank-you); never reward sharing
- Cloud save: `*CloudSave` child states (enter `ev.open_cloud_save`, only via `PlatformContext.open_cloud_save()`, independent of `no_monetization`) extend `CloudSaveContext`; backend usable → `services.set_cloud_save(true)` (reset in `deinit`); `ev_request_cloud_pull` → `ev_cloud_pulled(json)` **only on success** (error/unreachable = no answer → game never pushes); `ev_request_cloud_push(json)` fire-and-forget. Yandex = `player.getData/setData` key `save` (200 KB); Play = Saved Games snapshot `jet_math_progress` via plugin `GodotPlayGameServices` singleton (by name, ready only after sign-in). Game side only `SaveManager` — `levels-and-progress.md`. Human setup: `.claude/doc/cloud_save.md`
- No shop context = no monetization (no store feature or `no_monetization`); details `monetization.md`
- Platform pause (tab hidden, SDK pause, ad open) → `root_events.ev_app_visibility_changed`
- `WEBContext`: `document.visibilitychange` (JS callback kept in member, removed in `deinit`)
- `YandexContext`: `YaGames.init()` (`/sdk.js` via Web-Yandex preset `head_include`) → `LoadingAPI.ready()` once after SDK up **and** `ev.open_menu`; SDK up → `services.set_language(environment.i18n.lang)`; `ev_battle_started/finished` → `GameplayAPI.start/stop`; `game_api_pause/resume` → visibility; then `open_shop({ysdk})`; ads/payments only in `YandexShopContext`; JS callbacks kept in arrays; JS arrays read via `JSON.stringify` round-trip
- `CrazyGamesContext`: `CrazyGames.SDK.init()` (script via Web-CrazyGames `head_include`) → `game.loadingStart/Stop` (stop after SDK up **and** `ev.open_menu`), battle → `gameplayStart/Stop`; children get payload `cg_sdk`. `CrazyGamesShop` = `AdsOnlyShopContext` (`ad.requestAd("midgame"|"rewarded")`, mute on `adStarted`, reward only `adFinished`); `CrazyGamesCloudSave` = `SDK.data.getItem/setItem` key `save`. `PokiContext`: `PokiSDK.init()` (any outcome) → `gameLoadingFinished()` once after `ev.open_menu`, battle → `gameplayStart/Stop`; `PokiShop` = `AdsOnlyShopContext` (`commercialBreak` / `rewardedBreak` promises, pause+mute until resolve); no cloud save. Portals have no IAP: `offer_kind` stays empty, only ads
- Contexts receive every HFSM event via `on_event` while active
- Heavy UI stays in scenes; BoundEntity contexts must not mount scenes

## Tutorial (parallel state)

- `App/Tutorial` scene `tutorial` (`scenes/tutorial/tutorial.tscn`, sync load), parallel to Menu/Battle
- AppRoot `_sync_tutorial()` on initialize + `ev_profiles_changed` + `ev_return_to_menu`: profile exists and (`!ProgressController.is_tutorial_completed()` or `is_endless_intro_pending()` or `is_shop_tour_pending()` or `is_mistakes_intro_pending()` or `is_expert_intro_pending()` or `is_flight_mode_intro_pending()`) → `ev.open_tutorial`, else `ev.close_tutorial`
- Tutorial scene reacts to `ev.start_game` / `ev.exit_game` / `ev.open_menu` via `on_event` (re-evaluates chapter); all chapters + `BattleTips.TIPS` done → `complete_tutorial()` + `ev.close_tutorial` (guarded: its own close event must not re-enter `_refresh`)

## Controls intro (parallel state)

- `App/ControlsIntro` scene `controls_intro` (`scenes/controls_intro/controls_intro.tscn`, sync load); AppRoot `initialize` emits `ev.open_controls_intro` once per app session, again on `ev_profiles_changed` when the active pilot id changed and `!is_first_flight_done()` (already open → HFSM ignores)
- Next battle `ev_countdown_entered` → used up: hold countdown + overlay (tutorial first flight too); tap/key → release + `ev.close_controls_intro`

## Menu UI

- Full-screen menu windows: `WindowStackManager` inside MenuScene — not HFSM bindings

## Must

- Keep `GameManager` battle FSM separate
- New app phase → JSON `scene` + `HfsmScenePaths.PATHS` entry
