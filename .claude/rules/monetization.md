---
description: Monetization — store shop contexts, App/Monetization, OfferBoard hooks, tester kill switch
paths:
  - "src/game/contexts/**/*"
  - "src/game/scenes/monetization/**/*"
  - "src/common/monetization/**/*"
  - "src/common/platform/**/*"
  - "src/ui/rewarded_gold_button/**/*"
  - "src/ui/purchase_offer_button/**/*"
  - "src/ui/parental_gate/**/*"
  - "src/ui/celebration_splash/**/*"
  - "src/game/scenes/post_battle/**/*"
  - "src/game/scenes/menu/levels/**/*"
  - "src/game/scenes/menu/plane_hangar_window/**/*"
  - "src/game/scenes/menu/settings_window/**/*"
  - "export_presets.cfg"
---

# Monetization

Plan / prices (human): `.claude/doc/monetization.md`.

## Layers (each only talks to the next)

1. Store shop context (platform code, `src/game/contexts/*_shop_context.gd`): `Yandex/YandexShop` (ads + `no_ads` purchase, valleys free), `GooglePlay/GooglePlayShop` + `RuStore/RuStoreShop` (no ads; `full_version` purchase locks paid valleys), `CrazyGames/CrazyGamesShop` + `Poki/PokiShop` (base `AdsOnlyShopContext`: ads only, no offer, valleys free), editor `Desktop/DevShop` (`-- --dev-shop=yandex|play`). Writes `PlatformServices` (`set_ads` / `set_offer` / `set_content_locked`), answers `ev_rewarded_result` / `ev_purchase_result` always (or `ev_purchase_pending` = paid, not settled → paywall «обрабатывается», no rebuy; unlock arrives later via caps); on enter `open_monetization()`
2. `App/Monetization` scene (`src/game/scenes/monetization/`, platform-agnostic): interstitial pacing (only on `ev.open_menu`, ≥ `interstitial_min_battles` session battles, cooldown), rewarded gold (per-device daily limit in `user://monetization.json`, gold via own `ProfileController` instance), paywall (`PaywallDialog.TEXTS` per offer kind, parent-facing copy; unknown kind → not opened) → `ParentalGate` (wrong answer → `retry_cooldown_sec` lockout, gate stays open) → `ev_request_purchase`; `gated_placements` (`parents`) skip the gate — their host is already behind one (only `ParentsWindow` may emit `parents`). Publishes `OfferBoard`
3. Host UI hooks read only `OfferBoard` (`src/common/monetization/offer_board.tres`), never `PlatformServices`: `RewardedGoldButton` (post-battle `setup(earned)` ×2, hangar `once_per_screen=false`), `PurchaseOfferButton` (settings, parents window), valley carousel `is_container_paywalled(id, PData.difficulty)` (free = `free_container_ids` + `extra_free_by_difficulty`: HARD also `multiplication`) → `LevelContainer.set_paywalled` (key ribbon only, art stays in color; grey + lock only for progress-locked) + tap → `ev_paywall_requested(placement, container_id)` → `PaywallDialog.open(kind, price, container_id)` shows that valley (art, name, kid line) above the parent text ("" = settings, no valley row); post-battle never auto-opens a paywalled valley; `CelebrationSplash` valley unlock of a paywalled valley → «Новая долина ждёт!» (art in color) + `Buy` → `ev_paywall_requested(&"valley_splash", id)`; HARD (valley already open) → `pass_exam` `open_next_container_id` → AppRoot `KIND_VALLEY_OFFER` = same splash only while paywalled, else skipped

## Kill switch (testers)

- `PlatformContext.open_shop()` is the only way to a shop; skipped with export feature `no_monetization` → no shop, no `App/Monetization`, default board = no offers, all valleys open
- Tester presets: `Web`, `Android-Test` (no store feature), `Web-Yandex-Test` (`yandex_games,no_monetization`: SDK yes, money no). Release Android presets: `Android` (`google_play`), `Android-RuStore` (`rustore`, APK). Release portal presets: `Web-CrazyGames` (`crazygames`), `Web-Poki` (`poki`); for a portal's Basic Launch / no-ads phase add `no_monetization`

## Must

- Content locked only after the store confirms «not owned» (offline / no plugin → open) AND the item is sellable: Play `queryProductDetails` BILLING/ITEM_UNAVAILABLE or `full_version` not listed → open, no offer (RU has no Play billing); Play catalog network errors keep the lock; Play re-queries purchases on root window `focus_entered` (promo codes / pending done outside)
- Store owns entitlements (re-queried each launch: Yandex `getPurchases`, Play `queryPurchases` + acknowledge, RuStore `get_purchase_availability` → `get_purchases` status `CONFIRMED`; lock also needs `get_products` to list the item); never cache purchases in PData
- Purchase only behind `ParentalGate`; interstitial never during battle / tutorial first battles
- Play Billing: plugin `GodotGooglePlayBilling` called by singleton name (no `BillingClient` type) so builds without it compile
- RuStore Pay: plugin wrapper `RuStoreGodotPayClient` (+ `RuStorePay*` / `ERuStorePay*` types) resolved by name via `ProjectSettings.get_global_class_list()` — never typed refs, so builds without the plugin compile; one-step purchase; RuStore unavailable (no app / not signed in) = open, no offer
- New store = new `*Shop` child state + context; never `if platform` in Monetization or hosts
- Rewarded / paid UI never shows unless `OfferBoard` says so
