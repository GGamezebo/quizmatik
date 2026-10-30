# Ивент «1 апреля»

Первоапрельский ивент подключён к общей системе сезонных событий. Ближайший сезон — **1–16 апреля 2027 года включительно (UTC)**; ещё десять повторов идут ежегодно до **2037 года**. Итого 11 сезонов. У каждого свой ключ прогресса `april_fools:YYYY-04-01`, оформление и подарки одинаковые.

## Оформление

Акварельная «Долина вверх дном»: домик на трубе, дом-чашка, мельница с карандашами вместо лопастей, бумажные рыбки, парящие зонтики, весенние цветы и солнце с усами. Фон нарисован в технике акварели на фактурной бумаге по стилевому образцу хэллоуинского «Лунного замка».

Ответы — акварельные шары в шутовских колпачках с маленькими глазками и усами по краям. Центр остаётся свободным для числа. Атлас сохраняет стандартные 5×3 ячейки, 1280×720, порядок 15 цветов совпадает с обычными шарами и эффектом лопания.

Дирижабль с красным носом, очками, усами и шутовской короной; два сопровождающих — мятного и персикового цветов. Бронеплиты с рожицами. Музыка — оригинальный зацикленный шуточный марш с щипковыми струнами, музыкальной шкатулкой и духовыми ответами.

Баннер 672×160 использует акварельного шарика и небо фона; рамка взята из той же текстуры, что у «Практики», с теми же отступами углов. Под надписью таймера декора нет.

## Бой и подарки

Существующая механика: погоня на 1–6 минут, затем бой с боссом. Примеры и скорость учитывают прогресс и сложность профиля.

| Победа | Подарок | Цена |
|---|---|---|
| 1 | Раскраска «Конфетти» | 10 |
| 2 | Шлейф «Бумажные рыбки» | 8 |
| 3 | Выстрел «Кремовый залп» | 8 |
| 4 | Раскраска «Шутовской ромб» | 12 |
| 5 | Шлейф «Смешные рожицы» | 10 |
| 6 | Выстрел «Уточки» + фон «Долина вверх дном» | 10 + 50 |

Повторно полученные предметы компенсируются их ценой. После шести коробок победа даёт 10 монет. Подарки не надеваются автоматически. В магазине доступны с 01.04.2027 и остаются после праздника. Купленный фон приносит свою музыку и шары также в обычные бои по правилам общей системы.

В dev-окне выбери «1 апреля» с нужным годом, закрой окно и нажми баннер в главном меню. «По календарю» возвращает реальные даты; выбор сбрасывается при перезапуске.

## Файлы и инструменты

- Контент: `src/common/events/april_fools/april_fools_event.tres`, 6 подарков и обложка рядом.
- Фон: `src/ui/backgrounds/april_fools/bg_upside_down.png` (1080×720).
- Шары: `src/features/answer/jester_balloons_atlas.png` (1280×720 с альфа-каналом), `jester_answer.tscn`.
- Фон, музыка и ответы связаны в `april_fools_background.tscn`.
- Босс: `src/features/boss/boss_april_fools_airship.tscn`, `boss_april_fools_wing.tscn`.
- Босс/подарки/баннер: `python tools/generate_april_fools_art.py`; только баннер — добавить `banner`.
- Музыка: `python tools/generate_music.py april_fools_music.ogg`.
- Подготовка новых ImageGen-исходников: `godot_console --headless --path . --script tools/pack_april_watercolor.gd --log-file bin/april_pack.log -- background.png atlas.png`. Сохраняет пропорции каждого шарика, пакует 15 ячеек и альфа-канал.
- PNG фона и шаров — выбранные иллюстрации встроенного ImageGen; генератор SVG их не перезаписывает.

Проверки: `tools/check_april_fools.gd` (все 11 сезонов, даты, магазин, подарки/компенсации, независимый прогресс, сцены и атлас), `tools/check_event_preview.gd` (выбор → баннер → запуск боя), `tools/check_new_year.gd` (регрессия предыдущего ивента). Запуск: `godot_console --headless --path . --script <путь> --log-file bin/check.log`. Профили игрока не записываются.

## Промпты иллюстраций (встроенный ImageGen)

Фон, референс стиля `src/ui/backgrounds/halloween/bg_moon_castle.png`:

> Create one finished game background illustration for Quizmatik April Fools event, landscape full bleed exactly 1080x720 if possible (3:2). The attached image is a STYLE REFERENCE ONLY: match its beautiful traditional watercolor on textured cold-press paper, transparent pigment washes, soft layered depth, hand-painted silhouettes, warm cream highlights. Replace Halloween with a delightful whimsical April Fools valley. A small fantastical upside-down village on a central hill: one crooked lavender house standing on its chimney, an oversized teacup-shaped little house, a tiny windmill with colorful pencil blades, little paper fish hanging from a string, two umbrellas floating as balloons. A winding peach-colored path, spring meadow with small humorous flowers, a few soft pink blossom trees. A cheerful pale sun with a very subtle tiny curled moustache in the upper central sky. Refined muted lavender, sage, dusty pink, butter yellow, soft turquoise palette, storybook watercolor richer and more detailed than flat vector art. Landscape composition for a side-scrolling arcade math game: upper 55% mostly calm open softly washed sky for gameplay, all important detailed buildings mostly in lower center, generic meadow and bushes only at left/right boundaries so image can be horizontally mirrored in-game. Level horizon, no large object cropped at side edges, full-bleed illustration with no white border. Magical and funny, child-friendly. NO text, NO numbers, NO UI, NO airplanes, NO combat actors, NO balloons with answers. Painted watercolor, not vector or 3D. Save this as the final background asset.

Шары, референс стиля/раскладки `src/features/answer/pumpkins_atlas.png`:

> Create a production game sprite atlas on a TRUE TRANSPARENT BACKGROUND, exactly 5 columns x 3 rows = 15 isolated sprites, 1280x720 canvas if possible, equal rectangular cells. The attached pumpkin atlas is ONLY a style, scale, layout and color-order reference; replace ALL pumpkins with April Fools watercolor round jester balloons. Match its lovely hand-painted watercolor texture, pigment blooms, cream paper sticker rim and delicate graphite edges. Each sprite: nearly round inflated balloon, a very small two-tone jester cap with tiny soft gold bells at its TOP, and a small curled silly moustache near the BOTTOM rim. Maybe tiny googly eyes just below cap at very top of circle, but the ENTIRE CENTRAL 65% OF EVERY BALLOON MUST BE EMPTY clean watercolor wash, no eyes/nose/mouth or patterns there because a large math number will be rendered separately. NO letters, NO numbers. Keep tops and strings short, contained fully within each cell, no overlap, no shadows outside sticker border. Round circles centered consistently in every cell, balloon body diameter about 78% of cell width, tops at 8% of cell height; leave transparent gaps between cells. Same cap/body shape, same size, all fifteen colors varied according to exactly this row-major order: row1 dusty red, warm golden yellow, mint green, powder sky blue, rose pink; row2 lavender, orange peach, turquoise, sage forest green, ochre gold; row3 deep teal, lime yellow-green, periwinkle cobalt blue, dusty lilac, dark berry red. Soft warm ivory sticker outline. Subtle watercolor three-dimensional shading like the pumpkin sheet; hand-painted, richly textured not flat vector. A polished cohesive asset sheet with 15 separate silhouettes on alpha. All balloon centers MUST remain beautifully blank, readable for white game numbers.
