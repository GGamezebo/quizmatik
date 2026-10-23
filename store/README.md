# store/

All images and videos made for platform store pages (Google Play, Steam, Yandex Games, CrazyGames, itch).
Never used by the game; Godot ignores it (`.gdignore`) and every export preset excludes `store/*`.

- `screenshots/{ru,en}/` — gameplay / menu screenshots, one folder per language (landscape 16:9, long side 1280–2560, 24-bit PNG, no alpha)
- `banners/` — feature graphics, covers, capsules, promo banners, icons for listings (`crazygames_cover_*` = output of `tools/generate_crazygames_covers.py`)
- `videos/{ru,en}/` — trailers, one folder per language (landscape 16:9 MP4, height ≥ 400, ≤ 100 MB, ≤ 28 s)
  `videos/` is a separate nested git repo `GGamezebo/quizmatik-store` (private, Git LFS for `*.mp4`), ignored by the game repo — commit/push videos from inside `store/videos/`. Fresh checkout: `git clone https://github.com/GGamezebo/quizmatik-store.git store/videos`
- `ads/homework_shorts/` — vertical ad frames plus `kling_scenario.md` (Kling AI shot list)
