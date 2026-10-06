"""English variants of the trophy-room art with baked Russian titles.

Erases the painted text («ДОСТИЖЕНИЯ» cloud, «СТАТИСТИКА» clipboard) by diffusing the surrounding
paper into the text pixels, then draws the English title in a matching font.
Output sits next to the source (`*_en.png`); `LocaleTextureSwap` picks it when the UI language is English.

Run from the project root: python tools/generate_achievements_en_titles.py
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

UI = Path("src/game/scenes/menu/trophy_room_window/ui")
FONTS = Path("assets/fonts")


def erase_text(img: Image.Image, box: tuple[int, int, int, int], dark: int, grow: int) -> Image.Image:
    rgba = np.asarray(img.convert("RGBA")).astype(np.float32)
    x0, y0, x1, y1 = box
    region = rgba[y0:y1, x0:x1]
    lum = region[..., 0] * 0.299 + region[..., 1] * 0.587 + region[..., 2] * 0.114
    mask_img = Image.fromarray(((lum < dark) & (region[..., 3] > 200)).astype(np.uint8) * 255)
    mask = np.asarray(mask_img.filter(ImageFilter.MaxFilter(grow))) > 0
    known = ~mask
    rgb = region[..., :3].copy()
    rgb[mask] = 0.0
    # Diffusion fill: masked pixels take the mean of known neighbours until everything is filled.
    for _ in range(400):
        if known.all():
            break
        acc = np.zeros_like(rgb)
        cnt = np.zeros(known.shape, np.float32)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
            shifted = np.roll(np.roll(rgb * known[..., None], dy, 0), dx, 1)
            k = np.roll(np.roll(known, dy, 0), dx, 1).astype(np.float32)
            acc += shifted
            cnt += k
        fill = (~known) & (cnt > 0)
        rgb[fill] = acc[fill] / cnt[fill][:, None]
        known = known | fill
    # Grain so the patch doesn't look airbrushed.
    noise = np.random.default_rng(7).normal(0.0, 3.0, rgb.shape)
    rgb[mask] = np.clip(rgb[mask] + noise[mask], 0, 255)
    region[..., :3] = rgb
    rgba[y0:y1, x0:x1] = region
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def fit_font(path: Path, text: str, max_w: int, max_h: int) -> ImageFont.FreeTypeFont:
    size = max_h
    while size > 8:
        font = ImageFont.truetype(str(path), size)
        l, t, r, b = font.getbbox(text)
        if r - l <= max_w and b - t <= max_h:
            return font
        size -= 1
    return ImageFont.truetype(str(path), size)


def draw_centered(img: Image.Image, box: tuple[int, int, int, int], text: str, font: ImageFont.FreeTypeFont,
                  fill: tuple[int, int, int, int]) -> None:
    draw = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    l, t, r, b = font.getbbox(text)
    x = x0 + (x1 - x0 - (r - l)) / 2 - l
    y = y0 + (y1 - y0 - (b - t)) / 2 - t
    draw.text((x, y), text, font=font, fill=fill)


def cloud() -> None:
    img = Image.open(UI / "title_cloud.png")
    text_box = (36, 32, 330, 98)
    img = erase_text(img, text_box, dark=150, grow=7)
    font = fit_font(FONTS / "RubikDoodleShadow-Regular.ttf", "ACHIEVEMENTS", 262, 46)
    draw_centered(img, (40, 36, 320, 92), "ACHIEVEMENTS", font, (58, 62, 70, 255))
    img.save(UI / "title_cloud_en.png")


def clipboard() -> None:
    img = Image.open(UI / "panel_clipboard.png")
    text_box = (318, 300, 656, 372)
    img = erase_text(img, text_box, dark=150, grow=9)
    font = fit_font(FONTS / "Nunito-Bold.ttf", "STATISTICS", 330, 52)
    draw_centered(img, (318, 306, 656, 366), "STATISTICS", font, (92, 62, 38, 255))
    img.save(UI / "panel_clipboard_en.png")


if __name__ == "__main__":
    cloud()
    clipboard()
    print("ok")
