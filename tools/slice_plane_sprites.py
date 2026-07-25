"""Slice Gemini plane sheet into PlaneDown / Plane / PlaneUp (288x108, transparent)."""
from __future__ import annotations

import math
import os
from PIL import Image, ImageFilter

SRC = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "refs", "plane_sprites_source.png")
)
OUT_DIR = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "src", "features", "plane")
)
TARGET = (288, 108)


def is_green_bg(r: int, g: int, b: int) -> bool:
    """Solid sheet green / near-green chroma."""
    if g < 100:
        return False
    # dominant green channel
    if g <= r + 35 or g <= b + 35:
        return False
    # bright key green family
    return g >= 140 or (g > r * 1.8 and g > b * 1.8)


def is_black_divider(r: int, g: int, b: int) -> bool:
    return r < 45 and g < 45 and b < 45


def green_amount(r: int, g: int, b: int) -> float:
    """How much green spill relative to red/blue (0 = none)."""
    return max(0.0, g - max(r, b))


def key_and_despill(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, _a = px[x, y]
            if is_black_divider(r, g, b) or is_green_bg(r, g, b):
                px[x, y] = (0, 0, 0, 0)
                continue
            # Soft key for green-tinted fringe near white outline
            spill = green_amount(r, g, b)
            # near-pure green fringe
            if spill > 40 and g > 120 and r < 140 and b < 140:
                # fade alpha by spill strength
                alpha = int(max(0, 255 - spill * 3.2))
                # despill remaining color toward white/magenta-neutral
                ng = min(g, max(r, b) + 8)
                px[x, y] = (r, ng, b, alpha)
                continue
            if spill > 12:
                # despill only: pull G down toward max(R,B)
                ng = int(max(r, b) + spill * 0.15)
                ng = min(g, ng)
                px[x, y] = (r, ng, b, 255)
            else:
                px[x, y] = (r, g, b, 255)
    return im


def erode_alpha_edge(im: Image.Image, shrink: int = 1) -> Image.Image:
    """Slightly shrink opaque mask to eat residual green fringe."""
    if shrink <= 0:
        return im
    alpha = im.getchannel("A")
    # MinFilter shrinks bright (opaque) regions
    for _ in range(shrink):
        alpha = alpha.filter(ImageFilter.MinFilter(3))
    out = im.copy()
    out.putalpha(alpha)
    return out


def content_bbox(im: Image.Image, alpha_min: int = 24):
    px = im.load()
    w, h = im.size
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= alpha_min:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x < 0:
        return None
    return (min_x, min_y, max_x + 1, max_y + 1)


def remove_small_blobs(im: Image.Image, min_pixels: int = 80) -> Image.Image:
    """Drop tiny leftover sparkles/noise (connected components by 4-neigh)."""
    w, h = im.size
    px = im.load()
    visited = [[False] * w for _ in range(h)]
    for y0 in range(h):
        for x0 in range(w):
            if visited[y0][x0] or px[x0, y0][3] < 24:
                visited[y0][x0] = True
                continue
            stack = [(x0, y0)]
            visited[y0][x0] = True
            comp = []
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                        visited[ny][nx] = True
                        if px[nx, ny][3] >= 24:
                            stack.append((nx, ny))
            if len(comp) < min_pixels:
                for x, y in comp:
                    px[x, y] = (0, 0, 0, 0)
    return im


def fit_to_canvas(im: Image.Image, size=TARGET, pad_ratio: float = 0.05) -> Image.Image:
    bbox = content_bbox(im)
    if bbox is None:
        return Image.new("RGBA", size, (0, 0, 0, 0))
    cropped = im.crop(bbox)
    tw, th = size
    margin_x = int(tw * pad_ratio)
    margin_y = int(th * pad_ratio)
    avail_w = max(1, tw - 2 * margin_x)
    avail_h = max(1, th - 2 * margin_y)
    cw, ch = cropped.size
    scale = min(avail_w / cw, avail_h / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
    return canvas


def find_dividers(im: Image.Image):
    rgb = im.convert("RGB")
    px = rgb.load()
    w, h = rgb.size

    row_black = [sum(1 for x in range(w) if is_black_divider(*px[x, y])) / w for y in range(h)]
    # vertical divider only spans top panel ~1/3 height
    top_h = max(1, int(h * 0.4))
    col_black_top = [
        sum(1 for y in range(top_h) if is_black_divider(*px[x, y])) / top_h for x in range(w)
    ]

    h_cands = [y for y, r in enumerate(row_black) if r > 0.55 and 0.2 * h < y < 0.55 * h]
    v_cands = [x for x, r in enumerate(col_black_top) if r > 0.7 and 0.35 * w < x < 0.65 * w]

    def mid_run(xs):
        if not xs:
            return None
        xs = sorted(xs)
        best = cur = [xs[0]]
        for a, b in zip(xs, xs[1:]):
            if b - a <= 3:
                cur.append(b)
            else:
                if len(cur) > len(best):
                    best = cur
                cur = [b]
        if len(cur) > len(best):
            best = cur
        return best[len(best) // 2]

    h_div = mid_run(h_cands)
    v_div = mid_run(v_cands)
    print("h_div=", h_div, "v_div=", v_div)
    return h_div or h // 3, v_div or w // 2


def process_cell(cell: Image.Image) -> Image.Image:
    keyed = key_and_despill(cell)
    keyed = erode_alpha_edge(keyed, shrink=1)
    keyed = remove_small_blobs(keyed, min_pixels=120)
    return fit_to_canvas(keyed)


def count_greenish(im: Image.Image) -> int:
    px = im.load()
    w, h = im.size
    n = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 40 and green_amount(r, g, b) > 25:
                n += 1
    return n


def main():
    src = Image.open(SRC)
    print("source", src.size)
    h_div, v_div = find_dividers(src)
    w, h = src.size
    inset = 14
    cells = {
        # top-left = wing down
        "PlaneDown.png": (0, 0, v_div - inset, h_div - inset),
        # top-right = wing up
        "PlaneUp.png": (v_div + inset, 0, w, h_div - inset),
        # bottom = idle / level
        "Plane.png": (0, h_div + inset, w, h),
    }
    for name, box in cells.items():
        out = process_cell(src.crop(box))
        path = os.path.join(OUT_DIR, name)
        out.save(path)
        print(
            "wrote",
            name,
            "bbox=",
            content_bbox(out),
            "greenish_px=",
            count_greenish(out),
        )


if __name__ == "__main__":
    main()
