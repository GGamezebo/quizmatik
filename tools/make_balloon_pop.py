"""Generate balloon-pop atlas: many equal cells, no clipping, smooth equal steps."""
from __future__ import annotations

import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "src", "features", "answer", "balloon_pop_atlas.png")
)
PREVIEW = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "refs", "balloon_pop_preview.png")
)

FRAMES = 24
CELL = 384
SHIP_CELL = 64
MARGIN = 48
# Hard cap so burst never approaches cell border.
MAX_RADIUS = (CELL // 2) - MARGIN - 8  # ~136


def clamp(v: float, a: int = 0, b: int = 255) -> int:
    return max(a, min(b, int(round(v))))


def rgba(lum: float, a: float) -> tuple[int, int, int, int]:
    L = clamp(lum)
    return (L, L, L, clamp(a))


def ease_out_cubic(t: float) -> float:
    u = 1.0 - t
    return 1.0 - u * u * u


def soft_ellipse(
    size: tuple[int, int],
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    color: tuple[int, int, int, int],
    softness: float = 0.35,
) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    if rx <= 1 or ry <= 1 or color[3] <= 0:
        return img
    px = img.load()
    w, h = size
    r, g, b, a = color
    soft = max(0.08, softness)
    x0 = max(0, int(cx - rx * (1 + soft) - 1))
    x1 = min(w, int(cx + rx * (1 + soft) + 2))
    y0 = max(0, int(cy - ry * (1 + soft) - 1))
    y1 = min(h, int(cy + ry * (1 + soft) + 2))
    for y in range(y0, y1):
        dy = (y - cy) / ry
        for x in range(x0, x1):
            dx = (x - cx) / rx
            d = math.sqrt(dx * dx + dy * dy)
            if d > 1.0 + soft:
                continue
            if d <= 1.0 - soft:
                t = 1.0
            else:
                t = 1.0 - (d - (1.0 - soft)) / (2.0 * soft)
                t = max(0.0, min(1.0, t))
            grain = 0.88 + 0.12 * math.sin(x * 0.31 + y * 0.19) * math.cos(x * 0.13 - y * 0.27)
            aa = clamp(a * t * grain)
            if aa > 0:
                px[x, y] = (r, g, b, aa)
    return img


def irregular_blotch(
    size: tuple[int, int],
    cx: float,
    cy: float,
    radius: float,
    color: tuple[int, int, int, int],
    lobes: int = 8,
    wobble: float = 0.28,
    seed: int = 0,
) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    if radius < 2 or color[3] <= 0:
        return img
    # Clamp radius so blur can't paint into margin.
    radius = min(radius, MAX_RADIUS * 0.42)
    draw = ImageDraw.Draw(img)
    pts = []
    n = max(6, lobes * 2)
    for i in range(n):
        ang = i * math.tau / n
        r = radius * (1.0 + rng.uniform(-wobble, wobble) * (0.55 if i % 2 else 1.0))
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    draw.polygon(pts, fill=color)
    feather = max(1, int(radius * 0.16))
    return img.filter(ImageFilter.GaussianBlur(radius=feather))


def cream_rim(
    size: tuple[int, int],
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    alpha: float,
    width: float = 4.0,
    seed: int = 0,
) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    outer, inner = [], []
    n = 40
    for i in range(n):
        ang = i * math.tau / n
        wob = 1.0 + 0.03 * math.sin(i * 2.1 + seed) + 0.015 * rng.uniform(-1, 1)
        outer.append((cx + math.cos(ang) * rx * wob, cy + math.sin(ang) * ry * wob))
        inner.append(
            (
                cx + math.cos(ang) * max(1.0, rx - width) * wob,
                cy + math.sin(ang) * max(1.0, ry - width) * wob,
            )
        )
    draw.polygon(outer, fill=rgba(245, alpha))
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(inner, fill=255)
    clear = Image.new("RGBA", size, (0, 0, 0, 0))
    return Image.composite(clear, img, mask)


def paper_shard(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    ang: float,
    dist: float,
    length: float,
    width: float,
    alpha: float,
    rng: random.Random,
) -> None:
    dist = min(dist, MAX_RADIUS - max(length, width) - 2)
    if dist < 4:
        return
    px = cx + math.cos(ang) * dist
    py = cy + math.sin(ang) * dist
    dx, dy = math.cos(ang), math.sin(ang)
    sx, sy = math.cos(ang + math.pi / 2), math.sin(ang + math.pi / 2)
    shape = [(-0.55, -0.4), (0.5, -0.35), (0.6, 0.2), (0.3, 0.55), (-0.45, 0.45), (-0.6, 0.05)]
    pts = []
    for t, s in shape:
        jx = rng.uniform(-0.6, 0.6)
        jy = rng.uniform(-0.6, 0.6)
        pts.append((px + dx * t * length + sx * s * width + jx, py + dy * t * length + sy * s * width + jy))
    draw.polygon(pts, fill=rgba(248, alpha))
    draw.line(pts + [pts[0]], fill=rgba(210, alpha * 0.5), width=1)


def balloon_body(size: tuple[int, int], cx: float, cy: float, rx: float, ry: float, alpha: float, seed: int) -> Image.Image:
    layers: list[Image.Image] = []
    layers.append(irregular_blotch(size, cx, cy, max(rx, ry) * 0.98, rgba(200, alpha), lobes=10, wobble=0.08, seed=seed))
    layers.append(cream_rim(size, cx, cy, rx, ry, alpha * 0.95, width=4.0, seed=seed + 1))
    layers.append(
        soft_ellipse(size, cx + rx * 0.28, cy - ry * 0.34, rx * 0.24, ry * 0.18, rgba(255, alpha * 0.55), softness=0.5)
    )
    dust = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(dust)
    rng = random.Random(seed + 9)
    for _ in range(7):
        x = cx + rng.uniform(-rx * 0.4, rx * 0.4)
        y = cy + rng.uniform(-ry * 0.4, ry * 0.2)
        rr = rng.uniform(0.7, 1.5)
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=rgba(255, alpha * rng.uniform(0.35, 0.65)))
    layers.append(dust)
    layers.append(irregular_blotch(size, cx, cy + ry * 0.92, 7.0, rgba(235, alpha), lobes=5, wobble=0.18, seed=seed + 3))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    for layer in layers:
        out = Image.alpha_composite(out, layer)
    return out


def make_particles(n: int, seed: int) -> list[dict]:
    rng = random.Random(seed)
    parts = []
    for i in range(n):
        ang = i * math.tau / n + rng.uniform(-0.05, 0.05)
        parts.append(
            {
                "ang": ang,
                "speed": rng.uniform(0.78, 1.08),
                "size": rng.uniform(0.75, 1.25),
                "kind": i % 3,
                "delay": (i % 5) * 0.015,
                "spin": rng.uniform(-0.35, 0.35),
            }
        )
    return parts


BLOTS = make_particles(20, 11)
SHARDS = make_particles(14, 22)
DROPS = make_particles(32, 33)


def clamp_xy(cx: float, cy: float, x: float, y: float, pad: float = 6.0) -> tuple[float, float]:
    dx, dy = x - cx, y - cy
    d = math.hypot(dx, dy)
    lim = MAX_RADIUS - pad
    if d > lim and d > 1e-6:
        s = lim / d
        return cx + dx * s, cy + dy * s
    return x, y


def frame_at(fi: int) -> Image.Image:
    """Equal temporal step t = fi/(FRAMES-1). Continuous particle motion."""
    t = fi / (FRAMES - 1)
    size = (CELL, CELL)
    cx = CELL * 0.5
    cy = CELL * 0.5 - 6
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    rng = random.Random(100 + fi)

    # Equal visual phases across ALL frames (no long idle):
    # 0.00-0.08 intact / inflate      (~2 frames)
    # 0.08-0.32 cracks grow            (~6 frames)
    # 0.32-1.00 rupture expand fade    (~16 frames)

    if t <= 0.08:
        u = t / 0.08
        inflate = 1.0 + 0.12 * u
        rx, ry = 52 * inflate, 58 * inflate
        out = Image.alpha_composite(out, balloon_body(size, cx, cy, rx, ry, 255, seed=7))
        flash = 40 + 50 * u
        out = Image.alpha_composite(
            out, soft_ellipse(size, cx, cy - 2, 18 + 10 * u, 16 + 9 * u, rgba(255, flash), softness=0.65)
        )
    elif t <= 0.32:
        u = (t - 0.08) / 0.24
        rx, ry = 56 + 4 * u, 58 - 3 * u
        body_a = 255 * (1.0 - 0.45 * u)
        out = Image.alpha_composite(out, balloon_body(size, cx, cy, rx, ry, body_a, seed=7))
        crack = Image.new("RGBA", size, (0, 0, 0, 0))
        cd = ImageDraw.Draw(crack)
        for i in range(7):
            ang = -0.55 + i * 0.4
            length = (18 + 42 * ease_out_cubic(u)) * (0.85 + 0.15 * (i % 2))
            x2 = cx + math.cos(ang) * length
            y2 = cy + math.sin(ang) * length * 0.95
            x2, y2 = clamp_xy(cx, cy, x2, y2, 24)
            cd.line([(cx, cy), (x2, y2)], fill=rgba(255, 160 + 60 * u), width=3)
            cd.line([(cx, cy), (x2, y2)], fill=rgba(35, 100 + 40 * u), width=1)
        out = Image.alpha_composite(out, crack)
        out = Image.alpha_composite(
            out, soft_ellipse(size, cx, cy, 12 + 16 * u, 11 + 15 * u, rgba(255, 70 + 110 * u), softness=0.7)
        )
        # rim flakes grow with crack progress
        flakes = Image.new("RGBA", size, (0, 0, 0, 0))
        fd = ImageDraw.Draw(flakes)
        n_flakes = 2 + int(u * 8)
        for i, p in enumerate(SHARDS[:n_flakes]):
            dist = 28 + 22 * u * p["speed"]
            paper_shard(
                fd,
                cx,
                cy,
                p["ang"],
                dist,
                7 + 5 * p["size"] * u,
                3 + 3 * p["size"],
                40 + 160 * u,
                rng,
            )
        out = Image.alpha_composite(out, flakes)
    else:
        u = (t - 0.32) / 0.68  # 0..1
        # Nearly linear outward travel = equal visual steps between frames.
        expand = u
        fade = max(0.0, 1.0 - max(0.0, (u - 0.45) / 0.55) ** 1.25)
        travel = MAX_RADIUS * 0.62  # keep clear padding from cell edge

        # Large fragments early
        if u < 0.35:
            g = 1.0 - u / 0.35
            for i in range(7):
                ang = i * math.tau / 7 + 0.15
                dist = (12 + 50 * ease_out_cubic(u / 0.35)) * (0.85 + 0.15 * (i % 2))
                bx = cx + math.cos(ang) * dist
                by = cy + math.sin(ang) * dist * 0.92
                bx, by = clamp_xy(cx, cy, bx, by, 30)
                rad = (15 - 6 * (u / 0.35)) * (0.9 + 0.15 * ((i * 2) % 3) / 2)
                out = Image.alpha_composite(
                    out,
                    irregular_blotch(size, bx, by, rad, rgba(195, 200 * g), lobes=7, wobble=0.32, seed=40 + i),
                )

        blotch_layer = Image.new("RGBA", size, (0, 0, 0, 0))
        for i, p in enumerate(BLOTS):
            local = max(0.0, min(1.0, expand - p["delay"]))
            dist = (18 + travel * local) * p["speed"]
            bx = cx + math.cos(p["ang"]) * dist
            by = cy + math.sin(p["ang"]) * dist * 0.9
            bx, by = clamp_xy(cx, cy, bx, by, 20 + 6 * p["size"])
            rad = (9 + 11 * p["size"]) * (1.0 - 0.35 * local)
            a = 200 * fade * (1.0 - 0.3 * local)
            if a < 8:
                continue
            blotch_layer = Image.alpha_composite(
                blotch_layer,
                irregular_blotch(
                    size, bx, by, rad, rgba(170 + 45 * ((i % 4) / 3), a), lobes=6 + (i % 3), wobble=0.38, seed=200 + i
                ),
            )
        out = Image.alpha_composite(out, blotch_layer)

        mist_r = min(travel * 0.95, 28 + expand * travel * 0.85)
        mist_a = 48 * fade * max(0.0, 1.0 - abs(u - 0.28) * 1.5)
        if mist_a > 6:
            out = Image.alpha_composite(
                out, soft_ellipse(size, cx, cy, mist_r, mist_r * 0.92, rgba(200, mist_a), softness=0.85)
            )

        if u < 0.88:
            shards = Image.new("RGBA", size, (0, 0, 0, 0))
            sd = ImageDraw.Draw(shards)
            for i, p in enumerate(SHARDS):
                local = max(0.0, min(1.0, expand - p["delay"] * 0.5))
                dist = (22 + travel * 0.95 * local) * p["speed"]
                ang = p["ang"] + p["spin"] * local
                a = 220 * fade * (1.0 - local * 0.5)
                if a < 10:
                    continue
                paper_shard(
                    sd,
                    cx,
                    cy,
                    ang,
                    dist,
                    length=9 + 8 * p["size"],
                    width=3.5 + 4 * p["size"],
                    alpha=a,
                    rng=rng,
                )
            out = Image.alpha_composite(out, shards)

        drops = Image.new("RGBA", size, (0, 0, 0, 0))
        dd = ImageDraw.Draw(drops)
        for i, p in enumerate(DROPS):
            local = max(0.0, min(1.0, expand - p["delay"]))
            dist = (14 + travel * 1.05 * local) * p["speed"]
            x = cx + math.cos(p["ang"]) * dist
            y = cy + math.sin(p["ang"]) * dist * 0.92
            x, y = clamp_xy(cx, cy, x, y, 12)
            rr = (1.0 + (i % 4) * 0.55) * (1.0 - 0.35 * local)
            a = 190 * fade * (1.0 - 0.45 * local)
            if a < 8 or rr < 0.35:
                continue
            dd.ellipse([x - rr, y - rr * 1.1, x + rr, y + rr * 0.9], fill=rgba(155 + (i % 3) * 28, a))
        for i in range(12):
            ang = i * math.tau / 12 + 0.2
            local = max(0.0, min(1.0, expand))
            dist = 16 + travel * 0.9 * local
            x = cx + math.cos(ang) * dist
            y = cy + math.sin(ang) * dist
            x, y = clamp_xy(cx, cy, x, y, 10)
            rr = 0.7 + (i % 2) * 0.4
            a = 150 * fade * (1.0 - local * 0.7)
            if a > 10:
                dd.ellipse([x - rr, y - rr, x + rr, y + rr], fill=rgba(255, a))
        out = Image.alpha_composite(out, drops)

        if u > 0.1:
            out = out.filter(ImageFilter.GaussianBlur(radius=0.4 + u * 0.65))

    # Absolute safety: clear margin band
    px = out.load()
    for y in range(CELL):
        for x in range(CELL):
            if x < MARGIN or y < MARGIN or x >= CELL - MARGIN or y >= CELL - MARGIN:
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = (r, g, b, 0)
    return out


def content_radius(im: Image.Image, alpha_min: int = 20) -> float:
    px = im.load()
    cx = cy = CELL * 0.5
    max_d = 0.0
    for y in range(CELL):
        for x in range(CELL):
            if px[x, y][3] > alpha_min:
                max_d = max(max_d, math.hypot(x - cx, y - cy))
    return max_d


def main() -> None:
    atlas = Image.new("RGBA", (FRAMES * CELL, CELL), (0, 0, 0, 0))
    for fi in range(FRAMES):
        fr = frame_at(fi)
        r = content_radius(fr)
        atlas.paste(fr, (fi * CELL, 0), fr)
        print(f"frame {fi:02d}/{FRAMES - 1}: content_r={r:.1f} limit={MAX_RADIUS} ok={r <= MAX_RADIUS + 4}")

    ship = Image.new("RGBA", (FRAMES * SHIP_CELL, SHIP_CELL), (0, 0, 0, 0))
    for fi in range(FRAMES):
        cell = atlas.crop((fi * CELL, 0, (fi + 1) * CELL, CELL))
        ship.paste(cell.resize((SHIP_CELL, SHIP_CELL), Image.Resampling.LANCZOS), (fi * SHIP_CELL, 0))
    atlas = ship

    atlas.save(OUT, "PNG")
    print(f"saved {OUT} {atlas.size} {os.path.getsize(OUT)} bytes")

    # Preview with cell guides to verify equal step + no crop
    preview = Image.new("RGBA", atlas.size, (28, 32, 40, 255))
    preview = Image.alpha_composite(preview, atlas)
    guide = ImageDraw.Draw(preview)
    for i in range(FRAMES + 1):
        x = i * CELL
        guide.line([(x, 0), (x, CELL - 1)], fill=(60, 70, 90, 255), width=1)
    # margin box on first cell
    guide.rectangle([MARGIN, MARGIN, CELL - MARGIN, CELL - MARGIN], outline=(80, 120, 160, 255))
    preview.save(PREVIEW)
    print(f"preview {PREVIEW}")


if __name__ == "__main__":
    main()
