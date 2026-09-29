# Quizmatik

Math-quiz arcade shooter on **Godot 4.7** (typed GDScript, Mobile renderer, 1280×720 landscape).
Targets: Mobile (Android/iOS), Steam, HTML5 (incl. Yandex Games).

Rules live in `.claude/rules/` (AI-only, terse). Human docs: `.claude/doc/`.
- always loaded: `godot-paradigm.md` (core approach), `architecture.md`, `concepts.md`, `maintain-architecture-rules.md`
- path-scoped (`paths:` frontmatter): battle, GDScript conventions, HFSM, levels/progress, menu, visuals

Feature plan (source of truth for profiles/planes/gold): `.cursor/plans/profiles-planes.md`.

## Not covered by the rules (verified 2026-09-26)

- **Localization:** none. UI text is Russian, hardcoded in `.tscn` `text = "..."` and some scripts; no `tr()`, no `TranslationServer`, no `.csv`/`.po`. Keep new UI text in Russian in the scene; do not add a translation system unless asked.
- **Tutorial:** not implemented. Only `PData.StateData.tutorial_completed` (saved, never read). Do not assume a tutorial flow exists.

## Working here

- Smallest change that fits existing patterns; no parallel systems.
- Follow `rules/godot-paradigm.md`: isolated context scenes, `.tres` defaults overridden via HFSM `initialize`, events in Resources, platform code only in HFSM platform contexts, editor UI, components signal up / parent calls down, SOLID.
- Don't edit `addons/`, binary assets, or anything in `concepts/` (look reference only).
- When structure/contracts change, update `.claude/rules/` in the same task. Edit only `.claude/` — never `.cursor/` (user syncs it).
- `rules/` = AI format: only facts that change edits; paths + must/never, no prose/rationale. Explanations, plans, reviews for the user → `.claude/doc/*.md` (Russian, readable).
