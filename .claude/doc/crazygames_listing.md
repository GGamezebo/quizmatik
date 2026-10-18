# CrazyGames: карточка игры «Jet Math»

Обновлено: 2026-10-11. Всё ниже готово к копированию в форму на [developer.crazygames.com](https://developer.crazygames.com). Поля и размеры в форме могут отличаться: я не видел саму форму (она за логином), поэтому сверяйте с ней.

## 1. Основное

| Поле | Значение |
|---|---|
| Название | **Jet Math** |
| Язык карточки | английский (основная аудитория портала); русский в самой игре есть |
| Категории | Educational / Kids, Arcade, Shooting |
| Устройства | Desktop + Mobile (landscape) |
| Ориентация | Landscape |
| Управление | клавиатура / мышь / тач (есть подсказки «Как играть» в игре) |
| Мультиплеер | нет |
| Возраст | детская игра, 6+ |
| Сборка | пресет `Web-CrazyGames`, zip с `index.html` в корне |

**Теги:** math, kids, educational, balloons, shooter, arcade, plane, multiplication, addition, quiz, school, brain, numbers.

## 2. Описание (copy-paste)

**Короткое (tagline, до ~100 символов):**
> Fly your plane and pop the balloon with the right answer!

**Полное:**
> Jet Math turns math practice into an arcade flight. A question appears on the banner, balloons with numbers float toward you, and you steer your paper plane to shoot the one with the right answer. Pick the wrong balloon and you lose a heart!
>
> Five painted valleys teach addition, subtraction, multiplication, division and a mix of all four. Each valley has 20 levels that get tricky step by step, finishing with an exam and a trophy. Watch out for the grumpy boss airship, golden bonus balloons and levels where the missing number is hidden: ? + 3 = 7.
>
> Practice exactly what you need in Training mode, finish the daily challenge to earn a stamp, and spend the gold you collect on new planes, paint, trails and stickers. Cosmetics never change how the game plays.
>
> Made for kids aged 7–10 and fun for the whole family. No chat, no accounts, no personal data. Everything is drawn like a pencil sketch on notebook paper.

**Как играть (поле Instructions):**
> Desktop: move the plane up and down with the Up / Down arrow keys, press Space or click the mouse to shoot. Mobile: touch the left side of the screen to steer the plane, tap to shoot. Hit the balloon with the correct answer to the question on the banner.

Сверено с `plane.gd`: движение по `ui_up` / `ui_down`, выстрел `shoot` (Пробел) или клик мыши, на тачскрине движение по касанию слева. Как именно стреляют пальцем, смотрите на подсказках «Как играть» в игре и поправьте фразу.

## 3. Медиа

Все файлы в `store/`, в игру не попадают.

| Что | Файл | Статус |
|---|---|---|
| Обложка 16:9 (1920×1080) | `store/banners/crazygames_cover_1920x1080.png` | готова |
| Обложка 2:3 (800×1200) | `store/banners/crazygames_cover_800x1200.png` | готова |
| Обложка 1:1 (800×800) | `store/banners/crazygames_cover_800x800.png` | готова |
| Иконка | `store/banners/play_icon_512.png` | есть |
| Скриншоты (EN) | `store/screenshots/en/01_menu.png` … `09_levels.png` (1280×720) | есть, 9 шт. |
| Видео | `store/videos/en/` | **пусто**, нужен геймплей 16:9 до 28 с |

Обложки сделаны скриптом `tools/generate_crazygames_covers.py` из обложки itch: по бокам размытое продолжение того же арта. Если форма просит другие размеры, поменяйте список `SIZES` в скрипте и запустите его заново. Для лучшего вида 2:3 стоит позже нарисовать отдельную вертикальную композицию.

Лучшие скриншоты для первых слотов: `08_battle`, `02_boss`, `07_valleys`, `05_hangar`, `06_tricky`.

## 4. Предподачный чеклист

Проверено мной в проекте:
- Внешних ссылок и `OS.shell_open` в коде игры нет.
- Платежей в игре на этой платформе нет: `CrazyGamesShop` только реклама.
- Пути в экспорте относительные (стандартный веб-экспорт Godot).
- Данных игроков не собираем; прогресс хранится через `SDK.data` (облако CrazyGames, у гостей локально).

**Проверьте сами (я не мог запустить экспорт и открыть портал):**
1. **Размер.** В `bin/` сейчас лежит старый веб-билд: `index.pck` ≈ 52,7 МБ и `index.wasm` ≈ 39,5 МБ. Лимит первой загрузки Basic Launch — 50 МБ (по описанию в доках, считается ли он по сжатой передаче, неясно). Экспортируйте `Web-CrazyGames` заново и посмотрите размер каждого файла и архива. Если превышает: сожмите крупные текстуры и музыку, проверьте, что в экспорте нет лишнего, или рассмотрите упрощённый шаблон Godot без неиспользуемых модулей.
2. **Время до геймплея ≤ 20 с** на среднем телефоне и при медленном интернете.
3. **Тест в превью CrazyGames:** запуск, бой, возврат в меню, сохранение и загрузка прогресса, закрытие и повторное открытие.
4. **Реклама** в Basic Launch выключена, все `adError` обрабатываются. Для первой подачи можно добавить `no_monetization` в Custom Features, тогда кнопок рекламы в игре не будет вообще.
5. **Звук:** на мобильном iOS Safari аудио стартует только после касания; в игре есть экран «Как играть» до первого боя, это покрывает жест.
6. **Политика конфиденциальности:** [docs/privacy/index.html](docs/privacy/index.html) упоминает только Google Play и Яндекс Игры. Если CrazyGames потребует ссылку, добавьте в неё абзац про CrazyGames (SDK портала хранит данные по своим правилам).

## 5. Подача

1. Зарегистрируйтесь на портале разработчика и создайте игру.
2. Заполните поля из раздела 1–2, загрузите медиа из раздела 3.
3. Загрузите zip сборки `Web-CrazyGames`.
4. Отправьте на проверку (Basic Launch). После публикации следите за трафиком; при хороших метриках портал предложит Full Launch.
5. Для Full Launch соберите билд без `no_monetization`: реклама через SDK, работающая с AdBlock.
