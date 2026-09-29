---
description: Core Godot paradigm — context scenes, resource defaults + HFSM override, resource events, platform contexts, editor UI, components, SOLID
---

# Core paradigm (every change; new code must follow, old code: don't spread violations)

## Context scene
- Scene = context. Must F6-run alone: no required parent / autoload / sibling scene; empty payload → no crash.
- Defaults = `@export` `.tres` on the scene (data **and** events). Isolated run uses them as-is.
- In app: HFSM mounts context → `initialize(data)` → `ResourceUtils.update_resource(live_res, data)`. Payload overrides defaults; never required. Ref: `game.gd` + `game_config.tres`.
- Context events = signals `ev_*` declared on a Resource `.tres` (`RootEvents`, `GameEvents`), `@export`ed to emitters/listeners. No autoload buses, no direct refs across contexts.
- `deinit()` / `_exit_tree`: tear down `EventListener` subscriptions.

## Platform code
- Platform-dependent code (SDK, store, ads, cloud save, web/Yandex/Android/iOS/Steam hooks) lives only in its own HFSM context (BoundEntity in `src/game/contexts/`) or its own scene mounted by that HFSM state. Never inside game scenes/features.
- HFSM brings up only what the running platform needs: parent context checks `OS.has_feature(...)` once → emits `ev.open_<platform>` → nested state mounts platform context. Other platforms never load it.
- Game code stays platform-agnostic: talks to platform contexts only via Resource events (e.g. `RootEvents`); no `OS.has_feature` for platforms in gameplay/UI.
- Allowed in features: device-capability input (touch vs KBM, `DisplayServer.is_touchscreen_available()`), editor-only dev hooks (`OS.has_feature("editor")`).
- Ref: `App` → `WEB` (`WEBContext`) → `WEB/Yandex` (`YandexContext`) — `hfsm-app-integration.md`.

## Components
- Entity = parent + components (child Nodes or `RefCounted`).
- Parent → component: direct method calls (`initialize`, `setup`, `apply_*`) on owned/`@export` refs.
- Component → parent: emit own signals only. Never keep/fetch parent (`get_parent()`, `owner`, injected parent) to call back.
- Siblings don't call each other; parent connects their signals.
- Pure logic → `RefCounted`; Nodes thin.

## UI
- Static UI = nodes in `.tscn` built in editor. Script only: `@export` node refs, set text/visibility/state, connect signals.
- Repeated items: editor-made template `.tscn` + `instantiate()`. Never `Control.new()` trees. Exceptions: data-filled lists (still via template), tiny debug overlays.

## SOLID
- S: one reason to change per script; growing class → extract component/helper.
- O: extend via new component / Resource / state, not `if kind ==` branches in existing code.
- L: subclasses keep base contract (`enter/leave`, `initialize/deinit`).
- I: small public surface — signals + few methods.
- D: depend on exported Resources / signals / `class_name` types, not scene paths or globals.
