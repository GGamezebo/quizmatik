---
paths:
  - "src/game/scenes/menu/parents_window/**"
  - "src/game/scenes/monetization/ui/**"
  - "src/ui/buttons/support_actions.tres"
  - "src/game/scenes/menu/settings_window/**"
  - "src/game/contexts/play_rating.gd"
  - "src/ui/buttons/hover_scale_button.gd"
  - "src/ui/buttons/support_button_glow.*"
---

# Parent support UI
- `src/ui/buttons/support_actions.tres`: Button variations `SupportRate` (gold), `SupportShare` (blue), `SupportPurchase` (green); bottom content margin reserves a scene-authored subtitle; subtitle `mouse_filter = 2`.
- `ParentsWindow.support_hint`: scene-wired Label; rate/share press acknowledges intent; visibility follows platform rate/share capabilities.
- `PaywallDialog.rate_hint`: visible when either rate or share is available; resets for each successful purchase.
- Review/share have no completion callback: never claim completion, grant rewards, or change entitlements from these buttons.
- Purchase success remains gated by `show_result(true)`; halo/stamp animation and existing CPU confetti only on the thank-you page; stop celebration tweens on close.

- Settings entry buttons: local scene styles; parents blue + progress caption, purchase offer gold + offer-kind caption (`PurchaseOfferButton.subtitle`, optional exported Label).
- `src/ui/buttons/pencil_button_rim.svg`: shared scene-authored NinePatchRect outline; mouse_filter = 2; settings and paywall buttons.
- Paywall: purchase CTA gold, play CTA sage green, dark ink labels; support action fills muted gold/blue/green.
- `PlayRating.open_store_page`: Android VIEW intent targets `com.android.vending`; fallback only to HTTPS Google Play URL, never generic `market://`.

- `HoverScaleButton.bind`: scene `metadata/hover_scale_factor` overrides binder default on first bind; parent report action buttons use 1.02 (outer menu binder may bind before local binder).

- `support_button_glow.tscn`: adult rate/share emphasis; Timer 3 s, per-button duplicate normal StyleBoxFlat bg_color → hover fill (0.8 s in / 1.2 s out); never scale/position/text tint or mutate shared theme. Hidden/disabled/hovered/pressed skip; keyboard focus does not block future pulses. Hide restarts interval, input stops own pulse. Wired only to parent report and paywall thanks actions.
