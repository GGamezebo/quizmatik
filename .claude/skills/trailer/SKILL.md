---
name: trailer
description: Make gameplay / store / ad videos of Quizmatik (Jet Math) — bot-played battle and trophy-room takes recorded by Godot Movie Maker, assembled with captions, end card and music by ffmpeg from a JSON scenario, any UI language, saved to store/videos/ and pushed to the quizmatik-store repo. Use when the user asks for a trailer, gameplay video, promo/ad clip, Shorts/Reels, store video, or a new language/version of an existing one.
---

# Trailer videos (Quizmatik / Jet Math)

Real game footage only — stores reject fake gameplay. Everything below runs from the project root.

## Pipeline

1. **Record takes** (Godot Movie Maker, 60 fps, 1080p, with game music + SFX) → `bin/trailer/*.avi` (gitignored, `.gdignore`):
   - `python tools/trailer/record.py battle bin/trailer/battle_en.avi --seed 7 --locale en`
     bot flies to the correct balloon and shoots (InputMap actions), grabs the bonus coin, kills the angry boss. Options: `--valley addition|subtraction|multiplication|division|mix`, `--plane starter|fast|green|red|gold`, `--paint/--trail/--shot <cosmetic id>`, `--battle '{"questions_count":5,"boss_armor":3}'` (any `GameConfig` field; defaults in `battle_autopilot.gd` `BATTLE_DEFAULTS` = 3 questions + royal boss ≈ 28 s), `--size 1080x1920` for vertical.
   - `python tools/trailer/record.py trophy bin/trailer/trophy_en.avi --locale en`
     trophy room with a sample pupil (4 exams, stats, 8 «tricky problems»), finger taps the list at `--tap-at` 3.2 s, take `--end-at` 9.5 s. Sample data lives only in memory — real saves untouched.
2. **Look at the take**: `python tools/trailer/sheet.py bin/trailer/battle_en.avi` (1 frame/s with source timecodes; `--every 0.5 --start 16 --length 8` to zoom in). Read the PNG, pick segment `from`/`to` and caption times. **Always redo this after recording** — any game code change shifts the battle (other examples, boss timing); old scenario times then cut wrong moments. Try other `--seed`s if the battle looks dull.
3. **Write / edit a scenario** `tools/trailer/scenarios/<name>.json` (copy the closest one).
4. **Compose**: `python tools/trailer/compose.py tools/trailer/scenarios/<name>.json` → MP4 (H.264 CRF 20, AAC, faststart, limiter).
5. **Check the result**: `python tools/trailer/sheet.py <out.mp4> --every 1.5 --cols 5` + read it (captions not covering the question banner / plane lane, cuts on action). Then `SendUserFile` it to the user.
6. **Publish** only when the user asks: `store/videos/` is a separate repo (`GGamezebo/quizmatik-store`, Git LFS for `*.mp4`) — `cd store/videos && git add <file> && git commit && git push`. Never commit videos to the game repo.

## Scenario JSON

```json
{
  "out": "store/videos/en/<name>.mp4",
  "size": [1920, 1080], "fps": 60, "xfade": 0.35,
  "music": "assets/audio/music/background_music.mp3",
  "segments": [
    {"src": "bin/trailer/battle_en.avi", "from": 0.0, "to": 9.8, "audio": "source",
     "captions": [{"text": "…", "pos": "bottom", "at": [3.7, 9.6]}]},
    {"dur": 5.35, "audio": "music", "card": {"bg": "assets/ui/backgrounds/valleys/valley_multiplication.png",
     "title": "Jet Math", "lines": [{"text": "…", "y": 560, "px": 64, "color": "ink|orange|grey"}]}}
  ]
}
```
- Segments crossfade by `xfade`; total = Σ durations − xfade × (n − 1). `audio`: `source` = take sound, `music` = running slice of `music` (fades in).
- `at` is relative to the segment start. Caption kinds: `pill` (default; `text` string or list of lines, `pos` bottom 985 / bottom_low 1022 / top 105 / center or `y`, `px`), `title` (big Rubik Doodle `title` + `sub` pill — hook), `panel` (cream card with `title` + `lines` over video — outro). Coordinates are for 1080 height, scaled to `size`.
- Placement: battle captions at `bottom` (top = HUD + question banner); trophy-room captions at `bottom_low` (top = title, the list fills the middle).
- Examples: `parents_en.json` (30 s for parents: hook → answers → boss → trophy room + tricky problems → end card), `gameplay_ru.json` / `gameplay_en.json` (one 28 s battle, title in, panel out).

## Content rules

- Names: ru «Улётная математика», en «Jet Math» (other languages: CSV `src/common/localization/translations.csv`, row «Улётная математика»). UI language of the take = `--locale`; caption text = same language.
- Claims only about real features: grades 1–4 (EASY = grade 1, HARD = 3–4), + − × ÷, tricky problems repeat until solved right (`MistakesController` / `review_facts`), trophies, endless record, boss. No prices / «free» / platform lists unless the user confirms them.
- Store limits (`store/README.md`): landscape 16:9 MP4, height ≥ 400, ≤ 100 MB, ≤ 28 s for store pages; parents/ads clips may be 30 s. Kids audience: no pressure / «buy now» lines.
- Hook in the first 2–3 s, something new every 3–5 s, end on the title card.

## Gotchas

- `record.py` writes a temporary `override.cfg` (window size = movie size) and always deletes it; refuses to run if one already exists. Never edit `project.godot` for recording.
- Take scripts are SceneTrees outside the game (`tools/` has `.gdignore`): they never ship and the game never references them. A loaded `.tres` must stay referenced by a variable while scenes load it again (else it drops from the cache and the scene reads a fresh copy — the trophy room went empty this way).
- The battle autopilot re-applies plane look on every game state change (`GameState` re-applies the equipped plane).
- ffmpeg = `imageio_ffmpeg.get_ffmpeg_exe()` (no system ffmpeg). Godot = env `GODOT` or `D:/Godot/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.
- Takes are ~0.5 GB each (MJPEG); delete `bin/trailer/` contents when done if space matters.
