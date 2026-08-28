#!/usr/bin/env python3
"""Reference-style achievement UI assets (opaque panels, transparent trophy cutouts)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "src/game/scenes/menu/trophy_room_window/ui"
TROPHY_DIR = UI / "trophies"
ICON_DIR = UI / "stat_icons"

INK = (42, 51, 64, 255)
CREAM = (243, 230, 200, 255)
PAPER = (252, 244, 224, 255)
PAPER_SHADOW = (225, 210, 180, 255)
WOOD = (118, 84, 56, 255)
WOOD_DARK = (86, 60, 38, 255)
METAL = (176, 181, 188, 255)
STONE = (168, 172, 178, 255)
STONE_DARK = (128, 132, 138, 255)
GOLD = (232, 196, 84, 255)
GREEN = (98, 168, 112, 255)
SILVER = (186, 200, 218, 255)
PURPLE = (158, 126, 192, 255)
RUBY = (210, 84, 92, 255)


def _save(path: Path, img: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print(path)


def _shadow(base: Image.Image, offset: tuple[int, int] = (6, 10), blur: int = 8) -> Image.Image:
    alpha = base.split()[-1]
    shadow = Image.new("RGBA", base.size, (20, 18, 14, 0))
    shadow.putalpha(alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas = Image.new("RGBA", (base.size[0] + 20, base.size[1] + 20), (0, 0, 0, 0))
    canvas.alpha_composite(shadow, (10 + offset[0], 10 + offset[1]))
    canvas.alpha_composite(base, (10, 10))
    return canvas


def title_cloud() -> None:
    w, h = 480, 132
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for cx, cy, rx, ry in [(90, 62, 58, 44), (180, 52, 64, 48), (270, 56, 62, 46), (350, 62, 54, 42)]:
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(255, 252, 245, 255), outline=INK, width=3)
    draw.rounded_rectangle((42, 40, w - 42, h - 30), radius=34, fill=(255, 252, 245, 255), outline=INK, width=3)
    _save(UI / "title_cloud.png", _shadow(img))


def panel_clipboard() -> None:
    w, h = 380, 540
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((24, 64, w - 16, h - 14), radius=18, fill=PAPER, outline=INK, width=3)
    draw.rectangle((0, 0, w, 52), fill=WOOD, outline=INK, width=3)
    draw.rectangle((w // 2 - 38, 8, w // 2 + 38, 36), fill=METAL, outline=INK, width=2)
    for y in range(8, 48, 6):
        draw.line([(12, y), (w - 12, y)], fill=WOOD_DARK, width=1)
    draw.line([(28, 64), (w - 20, 64)], fill=WOOD_DARK, width=2)
    _save(UI / "panel_clipboard.png", _shadow(img))


def banner_section() -> None:
    w, h = 520, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((36, 12, w - 36, h - 12), radius=20, fill=CREAM, outline=INK, width=3)
    for cx in (42, w - 42):
        draw.polygon([(cx, h // 2), (cx - 18, h // 2 - 16), (cx - 18, h // 2 + 16)], fill=GOLD, outline=INK, width=2)
        draw.polygon([(cx, h // 2), (cx + 18, h // 2 - 16), (cx + 18, h // 2 + 16)], fill=GOLD, outline=INK, width=2)
    _save(UI / "banner_section.png", img)


def panel_scroll() -> None:
    w, h = 760, 220
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((58, 34, w - 58, h - 34), radius=16, fill=PAPER, outline=INK, width=3)
    for cx in (38, w - 38):
        draw.ellipse((cx - 30, 28, cx + 30, h - 28), fill=CREAM, outline=INK, width=3)
    _save(UI / "panel_scroll.png", _shadow(img))


def shelf_platform() -> None:
    w, h = 760, 88
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(16, 22), (w - 16, 22), (w - 6, h - 10), (6, h - 10)], fill=STONE, outline=INK, width=3)
    draw.line([(12, 30), (w - 12, 30)], fill=(210, 214, 220, 255), width=2)
    for i in range(5):
        cx = 76 + i * 136
        draw.rectangle((cx - 36, 10, cx + 36, 26), fill=STONE_DARK, outline=INK, width=2)
    _save(UI / "shelf_platform.png", img)


def pedestal() -> None:
    w, h = 96, 52
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(10, 10), (w - 10, 10), (w - 4, h - 8), (4, h - 8)], fill=STONE, outline=INK, width=2)
    draw.line([(12, 16), (w - 12, 16)], fill=(210, 214, 220, 255), width=2)
    _save(UI / "pedestal.png", img)


def _canvas(size: int = 256) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _cup(draw: ImageDraw.ImageDraw, body: tuple, rim: tuple, x0: int, y0: int, x1: int, y1: int) -> None:
    draw.rounded_rectangle((x0 + 18, y0 + 44, x1 - 18, y1 - 38), radius=10, fill=body, outline=INK, width=3)
    draw.ellipse((x0 + 12, y0 + 18, x1 - 12, y0 + 58), fill=body, outline=INK, width=3)
    draw.arc((x0 - 8, y0 + 30, x0 + 22, y0 + 92), 90, 270, fill=INK, width=4)
    draw.arc((x1 - 22, y0 + 30, x1 + 8, y0 + 92), 270, 90, fill=INK, width=4)
    draw.rounded_rectangle((x0 + 34, y1 - 38, x1 - 34, y1 - 12), radius=4, fill=rim, outline=INK, width=2)


def trophy_addition() -> Image.Image:
    img, draw = _canvas()
    _cup(draw, GREEN, (74, 140, 90, 255), 56, 40, 200, 190)
    draw.text((118, 88), "+", fill=(255, 255, 255, 255))
    draw.arc((72, 138, 184, 198), 10, 170, fill=GOLD, width=7)
    return _shadow(img)


def trophy_subtraction() -> Image.Image:
    img, draw = _canvas()
    _cup(draw, SILVER, (140, 154, 170, 255), 56, 40, 200, 190)
    draw.polygon([(24, 98), (56, 78), (56, 118)], fill=SILVER, outline=INK, width=2)
    draw.polygon([(232, 98), (200, 78), (200, 118)], fill=SILVER, outline=INK, width=2)
    draw.text((118, 88), "-", fill=INK)
    return _shadow(img)


def trophy_multiplication() -> Image.Image:
    img, draw = _canvas()
    _cup(draw, GOLD, (196, 158, 58, 255), 56, 40, 200, 190)
    draw.text((118, 84), "×", fill=INK)
    return _shadow(img)


def trophy_division() -> Image.Image:
    img, draw = _canvas()
    draw.polygon([(128, 36), (188, 72), (176, 148), (128, 184), (80, 148), (68, 72)], fill=PURPLE, outline=INK, width=3)
    draw.ellipse((116, 88, 140, 112), fill=INK)
    draw.line([(116, 132), (140, 132)], fill=INK, width=4)
    draw.ellipse((116, 152, 140, 176), fill=INK)
    draw.rounded_rectangle((104, 176, 152, 198), radius=4, fill=PURPLE, outline=INK, width=2)
    return _shadow(img)


def trophy_mix() -> Image.Image:
    img, draw = _canvas()
    draw.rounded_rectangle((92, 162, 164, 198), radius=6, fill=GOLD, outline=INK, width=3)
    draw.polygon([(128, 34), (168, 78), (156, 132), (100, 132), (88, 78)], fill=RUBY, outline=INK, width=3)
    for pts in [(108, 92), (128, 72), (148, 92)]:
        draw.polygon([(pts[0], pts[1] + 20), (pts[0] + 10, pts[1]), (pts[0] + 20, pts[1] + 20)], fill=(230, 110, 96, 255), outline=INK)
    return _shadow(img)


def trophy_locked() -> Image.Image:
    img, draw = _canvas()
    _cup(draw, (190, 192, 196, 180), (160, 162, 168, 180), 68, 52, 188, 190)
    draw.rounded_rectangle((112, 108, 144, 136), radius=6, fill=(170, 172, 176, 220), outline=INK, width=2)
    draw.arc((116, 92, 140, 116), 0, 180, fill=INK, width=3)
    return img


def icon_star(color: tuple[int, int, int, int]) -> Image.Image:
    img, draw = _canvas(128)
    cx, cy = 64, 64
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 46 if i % 2 == 0 else 18
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    draw.polygon(pts, fill=color, outline=INK, width=2)
    return img


def icon_swords() -> Image.Image:
    img, draw = _canvas(128)
    draw.line([(34, 98), (58, 34)], fill=(130, 138, 150, 255), width=7)
    draw.line([(94, 98), (70, 34)], fill=(130, 138, 150, 255), width=7)
    draw.ellipse((58, 28, 70, 40), fill=METAL, outline=INK, width=2)
    return img


def icon_check() -> Image.Image:
    img, draw = _canvas(128)
    draw.rounded_rectangle((24, 24, 104, 104), radius=18, fill=GREEN, outline=INK, width=3)
    draw.line([(42, 66), (58, 82), (88, 48)], fill=(255, 255, 255, 255), width=8, joint="curve")
    return img


def icon_shot() -> Image.Image:
    img, draw = _canvas(128)
    draw.ellipse((36, 36, 92, 92), fill=(72, 76, 86, 255), outline=INK, width=3)
    draw.polygon([(58, 22), (64, 10), (70, 22)], fill=RUBY, outline=INK)
    return img


def icon_clock() -> Image.Image:
    img, draw = _canvas(128)
    draw.ellipse((24, 24, 104, 104), fill=PAPER, outline=INK, width=3)
    draw.line([(64, 64), (64, 42)], fill=INK, width=4)
    draw.line([(64, 64), (82, 72)], fill=INK, width=4)
    return img


def icon_map() -> Image.Image:
    img, draw = _canvas(128)
    draw.polygon([(22, 30), (106, 22), (106, 106), (22, 98)], fill=CREAM, outline=INK, width=3)
    draw.line([(64, 30), (64, 106)], fill=INK, width=2)
    return img


def icon_winged_clock() -> Image.Image:
    img, draw = _canvas(128)
    draw.polygon([(8, 64), (28, 48), (28, 80)], fill=GOLD, outline=INK, width=2)
    draw.polygon([(120, 64), (100, 48), (100, 80)], fill=GOLD, outline=INK, width=2)
    draw.ellipse((32, 28, 96, 92), fill=PAPER, outline=INK, width=3)
    draw.text((52, 52), "12", fill=INK)
    return img


def icon_winged_plane_cup() -> Image.Image:
    img, draw = _canvas(128)
    draw.polygon([(8, 64), (28, 48), (28, 80)], fill=SILVER, outline=INK, width=2)
    draw.polygon([(120, 64), (100, 48), (100, 80)], fill=SILVER, outline=INK, width=2)
    draw.rounded_rectangle((44, 68, 84, 104), radius=8, fill=SILVER, outline=INK, width=2)
    draw.polygon([(54, 78), (64, 72), (74, 78), (64, 84)], fill=INK)
    return img


def main() -> None:
    title_cloud()
    panel_clipboard()
    banner_section()
    panel_scroll()
    shelf_platform()
    pedestal()
    trophies = {
        "trophy_addition.png": trophy_addition,
        "trophy_subtraction.png": trophy_subtraction,
        "trophy_multiplication.png": trophy_multiplication,
        "trophy_division.png": trophy_division,
        "trophy_mix.png": trophy_mix,
        "trophy_locked.png": trophy_locked,
    }
    for name, fn in trophies.items():
        _save(TROPHY_DIR / name, fn())
    icons = {
        "icon_wins.png": lambda: icon_star(GOLD),
        "icon_battles.png": icon_swords,
        "icon_answers.png": icon_check,
        "icon_stars.png": lambda: icon_star((110, 170, 220, 255)),
        "icon_shots.png": icon_shot,
        "icon_time.png": icon_clock,
        "icon_sessions.png": icon_map,
        "icon_speed.png": icon_winged_clock,
        "icon_flights.png": icon_winged_plane_cup,
    }
    for name, fn in icons.items():
        _save(ICON_DIR / name, fn())
    print("All assets generated.")


if __name__ == "__main__":
    main()
