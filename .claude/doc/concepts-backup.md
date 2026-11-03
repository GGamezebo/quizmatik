# Бэкапы вне репозитория

Папка `D:\Godot\ProjectsData\quizmatik\` — место для вынесенных из проекта файлов. Относительно проекта: `../../ProjectsData/quizmatik/`.

- `store/` — медиа для страницы в сторе (перенесено целиком, 285 файлов, ~822 МБ). Вложенный репо видео `store/videos/` (GGamezebo/quizmatik-store) перенесён вместе с папкой; его `.git` работает на новом месте.
- `concepts/` — старые концепты (см. ниже).

# Бэкап старых концептов (`concepts/`)

Старые концепты (до коммита `078b131` «Concepts: old art direction out…») вынесены из репозитория и лежат вне проекта:

- Путь относительно проекта: `../../ProjectsData/quizmatik/concepts/`
- Абсолютный путь: `D:\Godot\ProjectsData\quizmatik\concepts\`
- Содержимое: 180 файлов (~129 МБ) — `ART_DIRECTION.md`, варианты концептов `*_concept_v*.png`, `redesign_v1/`, `notebook_pencil/` (атласы и скрипты), `gameplay_preview/`, `ChatGPT Image …png` и прочее.
- Не скопирован только `.gdignore` — он остаётся в `concepts/` проекта.

В самом проекте `concepts/` теперь содержит только 4 скриншота реальной игры (`01_menu.png`, `02_battle.png`, `03_levels.png`, `04_post_battle.png`), `README.md` и `.gdignore`. Это соответствует `.claude/rules/concepts.md`.

Файлы из бэкапа остаются также в истории git (коммиты до `078b131`), так что их можно вернуть и из репозитория, даже если папка бэкапа пропадёт.
