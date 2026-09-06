#!/usr/bin/env python3
"""Generate opaque achievement UI panels + trophy shelf (no checkerboard alpha)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

UI = Path(__file__).resolve().parents[1] / "src/game/scenes/menu/trophy_room_window/ui"
INK = (42, 51, 64, 255)
CREAM = (243, 230, 200, 255)
PAPER = (250, 240, 219, 255)
WOOD = (115, 82, 55, 255)
WOOD_DARK = (88, 62, 40, 255)
STONE = (158, 162, 168, 255)
STONE_DARK = (120, 124, 130, 255)
SHADOW = (30, 28, 24, 50)


def _save(name: str, img: Image.Image) -> None:
    UI.mkdir(parents=True, exist_ok=True)
    path = UI / name
    img.save(path, "PNG")
    print(path)


def title_cloud() -> None:
    w, h = 360, 100
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    blobs = [(70, 58, 55), (150, 48, 62), (230, 52, 58), (310, 56, 52), (370, 62, 44)]
    for cx, cy, r in blobs:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(252, 248, 240, 255), outline=INK, width=3)
    draw.rounded_rectangle((36, 36, w - 36, h - 28), radius=28, fill=(252, 248, 240, 255), outline=INK, width=3)
    _save("title_cloud.png", img)


def panel_clipboard() -> None:
    w, h = 360, 520
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((18, 52, w - 12, h - 10), radius=16, fill=PAPER, outline=INK, width=3)
    draw.rectangle((0, 0, w, 46), fill=WOOD, outline=INK, width=3)
    draw.rectangle((w // 2 - 34, 6, w // 2 + 34, 34), fill=(170, 170, 175, 255), outline=INK, width=2)
    draw.line([(24, 52), (w - 16, 52)], fill=WOOD_DARK, width=2)
    _save("panel_clipboard.png", img)


def banner_section() -> None:
    w, h = 420, 56
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((24, 10, w - 24, h - 10), radius=18, fill=CREAM, outline=INK, width=3)
    for cx in (34, w - 34):
        draw.polygon([(cx, h // 2), (cx - 16, h // 2 - 14), (cx - 16, h // 2 + 14)], fill=(230, 200, 120, 255), outline=INK)
        draw.polygon([(cx, h // 2), (cx + 16, h // 2 - 14), (cx + 16, h // 2 + 14)], fill=(230, 200, 120, 255), outline=INK)
    _save("banner_section.png", img)


def panel_scroll() -> None:
    w, h = 680, 200
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((48, 28, w - 48, h - 28), radius=14, fill=PAPER, outline=INK, width=3)
    for cx, flip in ((34, 1), (w - 34, -1)):
        draw.pieslice((cx - 28, 18, cx + 28, h - 18), 90 if flip > 0 else 270, 270 if flip > 0 else 90, fill=CREAM, outline=INK, width=3)
    _save("panel_scroll.png", img)


def shelf_platform() -> None:
    w, h = 720, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(12, 18), (w - 12, 18), (w - 4, h - 8), (4, h - 8)], fill=STONE, outline=INK, width=3)
    draw.line([(8, 24), (w - 8, 24)], fill=(190, 194, 200, 255), width=2)
    for i in range(5):
        cx = 72 + i * 132
        draw.rectangle((cx - 34, 8, cx + 34, 22), fill=STONE_DARK, outline=INK, width=2)
    _save("shelf_platform.png", img)


def pedestal() -> None:
    w, h = 88, 48
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(8, 8), (w - 8, 8), (w - 2, h - 6), (2, h - 6)], fill=STONE, outline=INK, width=2)
    draw.line([(10, 14), (w - 10, 14)], fill=(200, 204, 210, 255), width=2)
    _save("pedestal.png", img)


def main() -> None:
    title_cloud()
    panel_clipboard()
    banner_section()
    panel_scroll()
    shelf_platform()
    pedestal()
    print("Done.")


if __name__ == "__main__":
    main()
