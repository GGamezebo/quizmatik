"""Slice AI balloon-pop reference into a clean transparent atlas (no cell borders)."""
from __future__ import annotations

import math
import os
from PIL import Image, ImageFilter, ImageDraw

SRC = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "refs", "balloon_pop_source.png")
)
OUT = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "src", "features", "answer", "balloon_pop_atlas.png")
)
PREVIEW = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "refs", "balloon_pop_preview.png")
)

FRAMES = 8
CELL = 256
WHITE_THR = 30


def dist_white(r: int, g: int, b: int) -> float:
    return math.sqrt((255 - r) ** 2 + (255 - g) ** 2 + (255 - b) ** 2)


def is_near_white(rgb: tuple[int, int, int], thr: float = WHITE_THR) -> bool:
    return dist_white(*rgb) <= thr


def is_beige_border(rgb: tuple[int, int, int]) -> bool:
    r, g, b = rgb
    # light cream/beige line used as frame border
    if r < 200 or g < 190 or b < 170:
        return False
    if dist_white(r, g, b) < 12:
        return False
    # low saturation warm light
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) < 45 and r >= g >= b - 5


def key_background(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, _a = px[x, y]
            d = dist_white(r, g, b)
            if d <= WHITE_THR:
                alpha = 0
            elif d >= WHITE_THR + 16:
                alpha = 255
            else:
                alpha = int(255 * (d - WHITE_THR) / 16)
            px[x, y] = (r, g, b, alpha)
    return im


def erase_rect_border(im: Image.Image, band: int = 10) -> Image.Image:
    """Remove thin rectangular cream/white frame near cell edges."""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            near_edge = x < band or y < band or x >= w - band or y >= h - band
            if not near_edge:
                continue
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_near_white((r, g, b), 40) or is_beige_border((r, g, b)):
                px[x, y] = (r, g, b, 0)
    return im


def content_bbox(im: Image.Image, alpha_min: int = 28) -> tuple[int, int, int, int]:
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > alpha_min:
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    if maxx < 0:
        return (0, 0, 0, 0)
    return (minx, miny, maxx + 1, maxy + 1)


def largest_blob_bbox(im: Image.Image, alpha_min: int = 40) -> tuple[int, int, int, int]:
    """Keep the main pop body; drop stray border pixels via connected components on a coarse grid."""
    w, h = im.size
    px = im.load()
    # downsample mask
    step = 2
    gw, gh = (w + step - 1) // step, (h + step - 1) // step
    mask = [[False] * gw for _ in range(gh)]
    for gy in range(gh):
        for gx in range(gw):
            x, y = gx * step, gy * step
            if x < w and y < h and px[x, y][3] > alpha_min:
                mask[gy][gx] = True

    visited = [[False] * gw for _ in range(gh)]
    best = None
    best_size = 0

    for gy in range(gh):
        for gx in range(gw):
            if not mask[gy][gx] or visited[gy][gx]:
                continue
            stack = [(gx, gy)]
            visited[gy][gx] = True
            cells = []
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < gw and 0 <= ny < gh and mask[ny][nx] and not visited[ny][nx]:
                        visited[ny][nx] = True
                        stack.append((nx, ny))
            if len(cells) > best_size:
                best_size = len(cells)
                xs = [c[0] for c in cells]
                ys = [c[1] for c in cells]
                best = (min(xs) * step, min(ys) * step, (max(xs) + 1) * step, (max(ys) + 1) * step)

    if not best:
        return content_bbox(im, alpha_min)
    x0, y0, x1, y1 = best
    # pad a bit for droplets around main body
    pad = 18
    return (max(0, x0 - pad), max(0, y0 - pad), min(w, x1 + pad), min(h, y1 + pad))


def clear_outside(im: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    cropped = im.crop(box)
    out.paste(cropped, (box[0], box[1]), cropped)
    return out


def main() -> None:
    raw = Image.open(SRC).convert("RGB")
    w, h = raw.size
    assert w % FRAMES == 0

    px = raw.load()
    row_hits = []
    for y in range(h):
        hits = 0
        for x in range(0, w, 2):
            if dist_white(*px[x, y]) > WHITE_THR:
                hits += 1
        row_hits.append(hits)
    thr = max(row_hits) * 0.1
    y0 = next(i for i, v in enumerate(row_hits) if v > thr)
    y1 = h - next(i for i, v in enumerate(reversed(row_hits)) if v > thr)
    y0 = max(0, y0 - 4)
    y1 = min(h, y1 + 4)
    strip = raw.crop((0, y0, w, y1))
    print(f"strip y=[{y0},{y1}) {strip.size}")

    fw = strip.width // FRAMES
    atlas = Image.new("RGBA", (FRAMES * CELL, CELL), (0, 0, 0, 0))

    for i in range(FRAMES):
        cell = strip.crop((i * fw, 0, (i + 1) * fw, strip.height))
        # generous inset to drop AI cell border
        inset = 10
        cell = cell.crop((inset, inset, cell.width - inset, cell.height - inset))
        cell = key_background(cell)
        cell = erase_rect_border(cell, band=14)
        # soften alpha speckles
        r, g, b, a = cell.split()
        a = a.filter(ImageFilter.MedianFilter(size=3))
        cell = Image.merge("RGBA", (r, g, b, a))

        box = largest_blob_bbox(cell)
        if box[2] <= box[0]:
            print(f"frame {i}: empty")
            continue
        cell = clear_outside(cell, box)
        cropped = cell.crop(box)

        margin = 12
        max_side = CELL - margin * 2
        scale = min(max_side / cropped.width, max_side / cropped.height)
        # don't upscale tiny late frames too aggressively
        if i >= 6:
            scale = min(scale, 1.0)
        nw = max(1, int(cropped.width * scale))
        nh = max(1, int(cropped.height * scale))
        cropped = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        ox = i * CELL + (CELL - nw) // 2
        oy = (CELL - nh) // 2
        atlas.paste(cropped, (ox, oy), cropped)
        print(f"frame {i}: box={box} -> {nw}x{nh}")

    atlas.save(OUT, "PNG")
    print(f"saved raw {OUT} {atlas.size} {os.path.getsize(OUT)} bytes")

    # Convert pigment to luminance so in-game Color modulate matches balloon hue.
    px = atlas.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            mx, mn = max(r, g, b), min(r, g, b)
            sat = (mx - mn) / mx if mx else 0.0
            if sat < 0.18 and mx > 200:
                lum = int(0.6 * r + 0.3 * g + 0.1 * b)
                lum = min(255, int(lum * 1.05))
                px[x, y] = (lum, lum, int(lum * 0.96), a)
            else:
                lum = int(0.3 * r + 0.5 * g + 0.2 * b)
                lum = min(255, int(40 + lum * 0.95))
                px[x, y] = (lum, lum, lum, a)

    atlas.save(OUT, "PNG")
    print(f"saved tintable {OUT} {os.path.getsize(OUT)} bytes")

    preview = Image.new("RGBA", (atlas.width, atlas.height * 2 + 8), (0, 0, 0, 0))
    dark = Image.new("RGBA", atlas.size, (28, 32, 40, 255))
    sky = Image.new("RGBA", atlas.size, (168, 212, 240, 255))
    preview.paste(Image.alpha_composite(dark, atlas), (0, 0))
    preview.paste(Image.alpha_composite(sky, atlas), (0, atlas.height + 8))
    preview.save(PREVIEW)
    print(f"preview {PREVIEW}")


if __name__ == "__main__":
    main()
