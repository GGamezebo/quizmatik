# store/

All images and videos made for platform store pages (Google Play, Steam, Yandex Games, itch).
Never used by the game; Godot ignores it (`.gdignore`) and every export preset excludes `store/*`.

- `screenshots/{ru,en}/` — gameplay / menu screenshots, one folder per language (landscape 16:9, long side 1280–2560, 24-bit PNG, no alpha)
- `banners/` — feature graphics, covers, capsules, promo banners, icons for listings
- `videos/{ru,en}/` — trailers, one folder per language (landscape 16:9 MP4, height ≥ 400, ≤ 100 MB, ≤ 28 s)
