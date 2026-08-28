#!/usr/bin/env python3
"""Generate stat icons and reference-style valley trophies (transparent PNG)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

UI_DIR = Path(__file__).resolve().parents[1] / "src/game/scenes/menu/trophy_room_window/ui"
TROPHY_DIR = UI_DIR / "trophies"
ICON_DIR = UI_DIR / "stat_icons"
SIZE = 256
INK = (42, 51, 64, 255)


def _canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def icon_star_gold() -> Image.Image:
    img, draw = _canvas()
    cx, cy = 128, 128
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + i * math.pi / 5
        r = 72 if i % 2 == 0 else 30
        pts.append((cx + math.cos(angle) * r, cy + math.sin(angle) * r))
    draw.polygon(pts, fill=(240, 201, 74, 240), outline=INK, width=3)
    return img


def icon_swords() -> Image.Image:
    img, draw = _canvas()
    draw.line([(78, 178), (118, 78)], fill=(120, 130, 145, 255), width=10)
    draw.line([(178, 178), (138, 78)], fill=(120, 130, 145, 255), width=10)
    draw.polygon([(68, 182), (88, 170), (98, 188)], fill=(90, 100, 115, 255), outline=INK)
    draw.polygon([(188, 182), (168, 170), (158, 188)], fill=(90, 100, 115, 255), outline=INK)
    draw.ellipse((108, 68, 148, 108), fill=(180, 190, 200, 255), outline=INK, width=3)
    return img


def icon_check() -> Image.Image:
    img, draw = _canvas()
    draw.rounded_rectangle((56, 56, 200, 200), radius=28, fill=(120, 190, 130, 230), outline=INK, width=4)
    draw.line([(88, 132), (118, 162), (168, 98)], fill=(255, 255, 255, 255), width=12, joint="curve")
    return img


def icon_star_blue() -> Image.Image:
    img, draw = _canvas()
    cx, cy = 128, 128
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + i * math.pi / 5
        r = 72 if i % 2 == 0 else 30
        pts.append((cx + math.cos(angle) * r, cy + math.sin(angle) * r))
    draw.polygon(pts, fill=(110, 170, 220, 240), outline=INK, width=3)
    return img


def icon_shot() -> Image.Image:
    img, draw = _canvas()
    draw.ellipse((88, 88, 168, 168), fill=(70, 75, 85, 240), outline=INK, width=4)
    draw.line([(128, 56), (128, 88)], fill=INK, width=4)
    draw.polygon([(118, 56), (128, 36), (138, 56)], fill=(200, 80, 70, 255), outline=INK)
    return img


def icon_clock() -> Image.Image:
    img, draw = _canvas()
    draw.ellipse((58, 58, 198, 198), fill=(245, 230, 190, 240), outline=INK, width=4)
    draw.line([(128, 128), (128, 88)], fill=INK, width=5)
    draw.line([(128, 128), (158, 138)], fill=INK, width=5)
    return img


def icon_map() -> Image.Image:
    img, draw = _canvas()
    draw.polygon([(52, 78), (204, 62), (204, 194), (52, 178)], fill=(220, 195, 150, 240), outline=INK, width=4)
    draw.line([(128, 78), (128, 178)], fill=INK, width=3)
    draw.line([(52, 128), (204, 128)], fill=INK, width=3)
    return img


def icon_winged_clock() -> Image.Image:
    img, draw = _canvas()
    draw.polygon([(40, 120), (68, 100), (68, 140)], fill=(240, 201, 74, 220), outline=INK)
    draw.polygon([(216, 120), (188, 100), (188, 140)], fill=(240, 201, 74, 220), outline=INK)
    draw.ellipse((68, 68, 188, 188), fill=(245, 230, 190, 240), outline=INK, width=4)
    draw.text((108, 112), "12", fill=INK)
    return img


def icon_winged_plane_cup() -> Image.Image:
    img, draw = _canvas()
    draw.polygon([(40, 120), (68, 100), (68, 140)], fill=(180, 190, 205, 220), outline=INK)
    draw.polygon([(216, 120), (188, 100), (188, 140)], fill=(180, 190, 205, 220), outline=INK)
    draw.polygon([(98, 148), (158, 148), (148, 188), (108, 188)], fill=(200, 210, 220, 240), outline=INK, width=3)
    draw.polygon([(88, 148), (108, 118), (128, 108), (148, 118), (168, 148)], fill=(230, 235, 245, 240), outline=INK, width=3)
    return img


def trophy_addition() -> Image.Image:
    img, draw = _canvas()
    green = (95, 170, 110, 240)
    draw.polygon([(98, 78), (158, 78), (168, 132), (88, 132)], fill=green, outline=INK, width=3)
    draw.ellipse((88, 62, 168, 98), fill=green, outline=INK, width=3)
    draw.rectangle((112, 132, 144, 168), fill=green, outline=INK, width=3)
    draw.rectangle((96, 168, 160, 186), fill=(70, 140, 90, 255), outline=INK, width=3)
    draw.arc((72, 84, 98, 150), 90, 270, fill=INK, width=4)
    draw.arc((158, 84, 184, 150), 270, 90, fill=INK, width=4)
    draw.text((118, 92), "+", fill=(255, 255, 255, 255))
    draw.arc((84, 150, 172, 196), 10, 170, fill=(200, 170, 60, 255), width=6)
    return img


def trophy_subtraction() -> Image.Image:
    img, draw = _canvas()
    silver = (170, 185, 205, 240)
    draw.polygon([(98, 78), (158, 78), (168, 132), (88, 132)], fill=silver, outline=INK, width=3)
    draw.ellipse((88, 62, 168, 98), fill=silver, outline=INK, width=3)
    draw.polygon([(40, 110), (72, 92), (72, 128)], fill=silver, outline=INK)
    draw.polygon([(216, 110), (184, 92), (184, 128)], fill=silver, outline=INK)
    draw.text((118, 92), "-", fill=INK)
    draw.rectangle((112, 132, 144, 176), fill=silver, outline=INK, width=3)
    draw.rectangle((96, 176, 160, 192), fill=(130, 145, 165, 255), outline=INK, width=3)
    return img


def trophy_multiplication() -> Image.Image:
    img, draw = _canvas()
    gold = (230, 190, 70, 240)
    draw.polygon([(98, 78), (158, 78), (168, 132), (88, 132)], fill=gold, outline=INK, width=3)
    draw.ellipse((88, 62, 168, 98), fill=gold, outline=INK, width=3)
    draw.text((118, 88), "x", fill=INK)
    draw.rectangle((112, 132, 144, 176), fill=gold, outline=INK, width=3)
    draw.rectangle((96, 176, 160, 192), fill=(190, 150, 50, 255), outline=INK, width=3)
    return img


def trophy_division() -> Image.Image:
    img, draw = _canvas()
    purple = (155, 120, 190, 240)
    draw.polygon([(108, 54), (148, 54), (158, 92), (148, 132), (108, 132), (98, 92)], fill=purple, outline=INK, width=3)
    draw.ellipse((118, 98, 138, 118), fill=INK)
    draw.line([(118, 136), (138, 136)], fill=INK, width=4)
    draw.ellipse((118, 154, 138, 174), fill=INK)
    draw.rectangle((112, 176, 144, 192), fill=purple, outline=INK, width=3)
    return img


def trophy_mix() -> Image.Image:
    img, draw = _canvas()
    draw.rectangle((98, 160, 158, 192), fill=(200, 160, 70, 255), outline=INK, width=3)
    pts = [(128, 52), (158, 92), (148, 132), (108, 132), (98, 92)]
    draw.polygon(pts, fill=(210, 70, 80, 240), outline=INK, width=3)
    draw.polygon([(118, 92), (128, 72), (138, 92)], fill=(240, 110, 90, 240), outline=INK)
    draw.polygon([(108, 108), (118, 88), (128, 108)], fill=(190, 60, 80, 240), outline=INK)
    draw.polygon([(138, 108), (128, 88), (148, 108)], fill=(190, 60, 80, 240), outline=INK)
    return img


def trophy_locked() -> Image.Image:
    img, draw = _canvas()
    ghost = (170, 170, 175, 120)
    draw.ellipse((88, 72, 168, 108), fill=ghost, outline=(130, 130, 135, 160), width=3)
    draw.rectangle((108, 108, 148, 156), fill=ghost, outline=(130, 130, 135, 160), width=3)
    draw.rectangle((92, 156, 164, 176), fill=ghost, outline=(130, 130, 135, 160), width=3)
    draw.rounded_rectangle((116, 118, 140, 142), radius=6, fill=(150, 150, 155, 180), outline=INK, width=2)
    draw.arc((118, 104, 138, 124), 0, 180, fill=INK, width=3)
    return img


ICONS = {
    "icon_wins.png": icon_star_gold,
    "icon_battles.png": icon_swords,
    "icon_answers.png": icon_check,
    "icon_stars.png": icon_star_blue,
    "icon_shots.png": icon_shot,
    "icon_time.png": icon_clock,
    "icon_sessions.png": icon_map,
    "icon_speed.png": icon_winged_clock,
    "icon_flights.png": icon_winged_plane_cup,
}

TROPHIES = {
    "trophy_addition.png": trophy_addition,
    "trophy_subtraction.png": trophy_subtraction,
    "trophy_multiplication.png": trophy_multiplication,
    "trophy_division.png": trophy_division,
    "trophy_mix.png": trophy_mix,
    "trophy_locked.png": trophy_locked,
}


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    TROPHY_DIR.mkdir(parents=True, exist_ok=True)
    for name, builder in ICONS.items():
        builder().save(ICON_DIR / name, "PNG")
    for name, builder in TROPHIES.items():
        builder().save(TROPHY_DIR / name, "PNG")
    print("Generated icons and trophies")


if __name__ == "__main__":
    main()
