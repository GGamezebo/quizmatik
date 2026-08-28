#!/usr/bin/env python3
"""Remove cream/white sticker borders from achievement stat icons and crop to content."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "src/game/scenes/menu/trophy_room_window/ui/stat_icons"

WHITE_MIN = 220
CHROMA_MAX = 42
PADDING = 2


def _is_border_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a < 16:
        return True
    mn = min(r, g, b)
    mx = max(r, g, b)
    return mn >= WHITE_MIN and (mx - mn) <= CHROMA_MAX


def _flood_clear_edges(img: Image.Image) -> None:
    pixels = img.load()
    width, height = img.size
    stack: list[tuple[int, int]] = []

    for x in range(width):
        stack.append((x, 0))
        stack.append((x, height - 1))
    for y in range(height):
        stack.append((0, y))
        stack.append((width - 1, y))

    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= width or y >= height:
            continue
        r, g, b, a = pixels[x, y]
        if a < 16 or not _is_border_pixel(r, g, b, a):
            continue
        pixels[x, y] = (r, g, b, 0)
        stack.extend([(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)])


def _clear_cream_sticker(img: Image.Image) -> None:
    pixels = img.load()
    width, height = img.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if _is_border_pixel(r, g, b, a):
                pixels[x, y] = (r, g, b, 0)


def trim_icon(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    _flood_clear_edges(img)
    _clear_cream_sticker(img)

    bbox = img.getbbox()
    if bbox is None:
        print(f"skip (empty): {path}")
        return

    left, top, right, bottom = bbox
    left = max(0, left - PADDING)
    top = max(0, top - PADDING)
    right = min(width, right + PADDING)
    bottom = min(height, bottom + PADDING)
    cropped = img.crop((left, top, right, bottom))
    cropped.save(path, "PNG")
    print(f"{path.name}: {width}x{height} -> {cropped.size[0]}x{cropped.size[1]}")


def main() -> None:
    for icon_path in sorted(ICON_DIR.glob("icon_*.png")):
        trim_icon(icon_path)


if __name__ == "__main__":
    main()
