#!/usr/bin/env python3
"""Generate transparent valley trophy PNGs (pencil-sticker style, distinct shapes)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).resolve().parents[1] / "src/game/scenes/menu/trophy_room_window/ui/trophies"
SIZE = 256
INK = (42, 51, 64, 255)
SHADOW = (42, 51, 64, 70)


def _new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _stroke(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], width: int = 4) -> None:
    if len(pts) > 1:
        draw.line(pts, fill=INK, width=width, joint="curve")


def _fill_poly(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon(pts, fill=fill, outline=INK, width=3)


def _symbol(draw: ImageDraw.ImageDraw, text: str, xy: tuple[float, float], size: int = 34) -> None:
    try:
        from PIL import ImageFont

        font = ImageFont.truetype("arial.ttf", size)
    except OSError:
        font = ImageFont.load_default()
    bbox = draw.textbbox(xy, text, font=font)
    cx = xy[0] - (bbox[0] + bbox[2]) / 2
    cy = xy[1] - (bbox[1] + bbox[3]) / 2
    draw.text((cx, cy), text, fill=INK, font=font)


def trophy_addition() -> Image.Image:
    img, draw = _new_canvas()
    gold = (240, 201, 74, 235)
    highlight = (255, 232, 160, 180)
    # Classic two-handle cup
    _fill_poly(draw, [(98, 78), (158, 78), (168, 132), (88, 132)], gold)
    draw.ellipse((88, 62, 168, 98), fill=gold, outline=INK, width=3)
    draw.rectangle((112, 132, 144, 168), fill=gold, outline=INK, width=3)
    draw.rectangle((96, 168, 160, 186), fill=(210, 170, 60, 255), outline=INK, width=3)
    draw.arc((72, 84, 98, 150), 90, 270, fill=INK, width=4)
    draw.arc((158, 84, 184, 150), 270, 90, fill=INK, width=4)
    draw.ellipse((104, 88, 132, 110), fill=highlight)
    _symbol(draw, "+", (128, 108), 40)
    return img


def trophy_subtraction() -> Image.Image:
    img, draw = _new_canvas()
    silver = (145, 176, 205, 235)
    blue = (110, 145, 180, 220)
    # Tall goblet
    draw.polygon([(128, 54), (154, 92), (146, 132), (110, 132), (102, 92)], fill=silver, outline=INK, width=3)
    draw.rectangle((118, 132, 138, 176), fill=blue, outline=INK, width=3)
    draw.ellipse((96, 176, 160, 196), fill=silver, outline=INK, width=3)
    draw.line([(128, 92), (128, 118)], fill=INK, width=4)
    _symbol(draw, "−", (128, 108), 44)
    return img


def trophy_multiplication() -> Image.Image:
    img, draw = _new_canvas()
    green = (90, 158, 111, 235)
    ribbon = (180, 70, 70, 230)
    # Star medal + ribbon
    cx, cy = 128, 112
    outer = []
    for i in range(10):
        angle = math.pi / 2 + i * math.pi / 5
        r = 56 if i % 2 == 0 else 24
        outer.append((cx + math.cos(angle) * r, cy + math.sin(angle) * r))
    _fill_poly(draw, outer, green)
    draw.ellipse((108, 92, 148, 132), fill=(120, 190, 140, 220), outline=INK, width=3)
    _fill_poly(draw, [(108, 146), (148, 146), (142, 182), (114, 182)], ribbon)
    _symbol(draw, "×", (128, 112), 36)
    return img


def trophy_division() -> Image.Image:
    img, draw = _new_canvas()
    purple = (155, 123, 184, 235)
    # Shield plaque
    _fill_poly(
        draw,
        [(128, 52), (178, 84), (168, 156), (128, 188), (88, 156), (78, 84)],
        purple,
    )
    draw.ellipse((118, 98, 138, 118), fill=INK)
    draw.line([(118, 136), (138, 136)], fill=INK, width=4)
    draw.ellipse((118, 154, 138, 174), fill=INK)
    return img


def trophy_mix() -> Image.Image:
    img, draw = _new_canvas()
    bronze = (196, 132, 72, 235)
    ruby = (210, 90, 90, 220)
    sapphire = (90, 130, 210, 220)
    emerald = (90, 170, 110, 220)
    # Ornate crown cup
    draw.rectangle((98, 148, 158, 186), fill=bronze, outline=INK, width=3)
    draw.polygon([(98, 148), (110, 118), (122, 148)], fill=ruby, outline=INK, width=2)
    draw.polygon([(122, 148), (128, 108), (134, 148)], fill=emerald, outline=INK, width=2)
    draw.polygon([(134, 148), (146, 118), (158, 148)], fill=sapphire, outline=INK, width=2)
    draw.ellipse((96, 132, 160, 158), fill=bronze, outline=INK, width=3)
    draw.ellipse((108, 138, 148, 152), fill=(230, 190, 120, 180))
    return img


def trophy_locked_silhouette() -> Image.Image:
    img, draw = _new_canvas()
    ghost = (170, 170, 175, 120)
    draw.ellipse((88, 72, 168, 108), fill=ghost, outline=(130, 130, 135, 160), width=3)
    draw.rectangle((108, 108, 148, 156), fill=ghost, outline=(130, 130, 135, 160), width=3)
    draw.rectangle((92, 156, 164, 176), fill=ghost, outline=(130, 130, 135, 160), width=3)
    # lock
    draw.rounded_rectangle((116, 118, 140, 142), radius=6, fill=(150, 150, 155, 180), outline=INK, width=2)
    draw.arc((118, 104, 138, 124), 0, 180, fill=INK, width=3)
    return img


TROPHIES = {
    "trophy_addition.png": trophy_addition,
    "trophy_subtraction.png": trophy_subtraction,
    "trophy_multiplication.png": trophy_multiplication,
    "trophy_division.png": trophy_division,
    "trophy_mix.png": trophy_mix,
    "trophy_locked.png": trophy_locked_silhouette,
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, builder in TROPHIES.items():
        path = OUT_DIR / name
        builder().save(path, "PNG")
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
