# Промпты для перерисовки долин (ChatGPT)

Стиль — как у `classic_sky/bg_gameplay_sky1.png` и новых обложек (`space`, `school_dreams`, `balloon_world`, `candy_kingdom`): мягкая детская акварель, пастель, светло и воздушно. Концепции долин прежние.

## Как генерировать

1. В новый чат ChatGPT приложи 2–3 референса стиля: `src/ui/backgrounds/classic_sky/bg_gameplay_sky1.png`, `src/ui/backgrounds/school_dreams/bg_school_dreams.png`, `src/ui/backgrounds/balloon_world/bg_balloon_world.png`.
2. Для композиции можно приложить и старую долину (`assets/ui/backgrounds/valleys/valley_*.png`), но с пометкой «только композиция, стиль — с референсов».
3. Отправь общий блок + блок нужной долины. Формат — горизонтальный 3:2.
4. Готовые картинки кидай мне: подгоню под 1080×720 и положу в `assets/ui/backgrounds/valleys/` под теми же именами.

## Общий блок (вставлять в каждый промпт)

```
Soft children's-book watercolor illustration on textured white watercolor paper,
in exactly the same style as the attached reference images: pastel palette, gentle
transparent washes with soft edges, light paper showing through, delicate thin pencil
outlines on the main objects, calm, airy, low contrast, lots of light sky.
Landscape 3:2, wide panoramic view, level horizon.
The main landmark stays in the center; near the left and right edges only generic
grass, trees and sky (the picture is mirrored at its side edges when it scrolls).
No text, letters or numbers, no people or animals, no frame, no vignette.
Not photorealistic, no grain or noise, no oversaturated colors, no tiny busy detail.
```

## Сложение

```
Green spring valley. In the center a gentle rounded green mountain; on its slope a big
"+" sign made of a flowering meadow outlined with light stones, clearly readable.
A blue river winds from the foot of the mountain toward the viewer. Soft snowy peaks far
behind. A big leafy tree on the left, a few pines on the right, a dirt path and
small wildflowers in the foreground.
```

## Вычитание

```
Warm sunny desert canyon valley. In the center a large flat-topped sandstone mesa with
a long horizontal "−" shaped slot carved through it, clearly readable. Saguaro cacti and
rounded rocks on sandy ground, a turquoise stream with a few palm trees at the sides,
pale distant mesas. Soft peach, sand and terracotta tones.
```

## Умножение

```
Lush tropical jungle valley. In the center a moss-covered cliff with a big "×" sign made
of light mossy stone framed by vines, clearly readable. Several waterfalls pour into a
turquoise lagoon below. Palm trees and ferns, a few orange tropical flowers, misty
mountains in the distance.
```

## Деление

```
Quiet winter valley. A calm blue lake in the center between snowy mountains. On the water
three ice floes form a "÷" sign: a round floe, a long flat floe below it, another round
floe below that — clearly readable. Snowy pines on both shores, soft lavender-blue and
white tones.
```

## Смешанная

```
One panoramic valley with four small zones from left to right, joined by one winding
river: a green hill with a "+" meadow, a sandstone mesa with a "−" slot, a jungle cliff
with a "×" sign and a waterfall, a snowy peak with a "÷" sign. A meadow with a path in the
foreground. Green meadow at the far left edge, snowy pines at the far right edge.
```
