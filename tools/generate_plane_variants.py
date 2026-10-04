"""Build per-plane art from the base pencil plane (column 0 of planes_atlas_spaced.png).

Atlas layout: 288x108 cells, rows = idle / down / up (same as plane_frames.tres),
columns = PlaneCatalog `atlas_column` (0 = base art «Быстрый» = pencil, left untouched).

Each other plane is a different piece of stationery in the same low-poly colored-pencil look:
1 ballpoint pen (violet), 2 marker (green), 3 ruler + set square (red), 4 fountain pen (gold).
Bodies are drawn here as flat faceted polygons with ink outline + diagonal pencil hatching;
cabin / wing / top fin / gun are cut from the base drawing (wing recolored), so the plane
language and the 3-frame wing animation stay the same. The white sticker rim is rebuilt last.

Re-runnable: column 0 is read back as the source and copied as-is.
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
ATLAS = os.path.join(ROOT, "src", "features", "plane", "planes_atlas_spaced.png")
FONT = os.path.join(ROOT, "assets", "fonts", "Nunito-Bold.ttf")
CELL_W, CELL_H = 288, 108
ROWS = 3  # idle, down, up
SS = 4  # supersampling for drawn bodies
RIM_RADIUS = 3.6
RIM_RGB = (253, 251, 246)
INK = (0.12, 0.13, 0.24)
PAPER = (0.98, 0.97, 0.95)

# Base drawing parts, per frame (idle, down, up), cell pixels.
CABIN = [
    [(55, 18), (70, 18), (73, 11), (104, 11), (108, 24), (101, 24), (101, 64), (64, 64), (64, 53), (55, 53)],
    [(55, 20), (66, 20), (68, 14), (102, 14), (106, 26), (99, 26), (99, 66), (61, 66), (61, 55), (55, 55)],
    [(51, 15), (55, 15), (55, 12), (100, 12), (103, 24), (97, 24), (97, 63), (58, 63), (58, 53), (51, 53)],
]
WING = [
    [(136, 59), (174, 59), (184, 95), (128, 95)],
    [(140, 59), (171, 59), (189, 101), (131, 101)],
    [(134, 55), (173, 55), (183, 75), (134, 75)],
]
TOP_FIN = [None, [(141, 4), (174, 4), (178, 25), (137, 25)], None]
GUN = [(204, 244, 78, 100), (204, 244, 77, 100), (204, 244, 75, 100)]  # x0, x1, y_cut, y1
# Flame (`FlameAnimation`, fixed for every plane) covers cell x <= 27 around y 62:
# drawn bodies are shrunk toward the nose so their back starts behind it, and get a nozzle there.
FIT_SCALE = 0.88
FIT_ANCHOR = (286.0, 54.0)
NOZZLE = [(20, 51), (32, 56), (44, 58), (44, 66), (32, 68), (20, 73)]  # rocket bell, mouth at the flame
BASE_BODY_TOP = 23  # top fin joint
BASE_BODY_BOTTOM = 75  # wing / gun joint


# ---------------------------------------------------------------- pixels

def load_base() -> list[np.ndarray]:
    atlas = np.array(Image.open(ATLAS).convert("RGBA")).astype(np.float32) / 255.0
    return [atlas[r * CELL_H:(r + 1) * CELL_H, 0:CELL_W].copy() for r in range(ROWS)]


def strip_rim(frame: np.ndarray) -> np.ndarray:
    """Remove the white sticker rim; returns the pencil drawing only (premultiplied RGBA)."""
    a = frame[..., 3] * 255.0
    rgb = frame[..., :3] * 255.0
    mn = rgb.min(-1)
    mx = rgb.max(-1)
    dt = ndi.distance_transform_edt(a >= 8)
    hard_white = (a > 0) & (mn > 232) & (mx - mn < 30) & (dt <= 7)
    passable = (a < 8) | hard_white
    lab, _ = ndi.label(passable)
    outside = np.unique(lab[a < 8])
    flooded = np.isin(lab, outside[outside > 0]) & (a >= 8)
    soft = (a >= 8) & (mn > 150) & (mx - mn < 40) & (dt <= 7)
    rim = flooded | (soft & ndi.binary_dilation(flooded, iterations=1))
    core = (a >= 8) & ~rim
    lab, n = ndi.label(core)
    if n:
        sizes = ndi.sum(core, lab, range(1, n + 1))
        core &= np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= 20])
    out = frame.copy()
    out[~core] = 0.0
    out[..., :3] *= out[..., 3:4]
    return out


def add_rim(core: np.ndarray) -> np.ndarray:
    """Rebuild the sticker rim around the drawing; returns straight-alpha RGBA."""
    solid = core[..., 3] > 0.5
    dist = ndi.distance_transform_edt(~solid)
    rim_a = np.clip(RIM_RADIUS + 0.5 - dist, 0.0, 1.0)
    rim = np.zeros_like(core)
    rim[..., :3] = np.array(RIM_RGB, np.float32) / 255.0
    rim[..., 3] = rim_a
    rim[..., :3] *= rim_a[..., None]
    out = over(core, rim)
    alpha = out[..., 3:4]
    out[..., :3] = np.where(alpha > 1e-4, out[..., :3] / np.maximum(alpha, 1e-4), 0.0)
    return out


def over(top: np.ndarray, bottom: np.ndarray) -> np.ndarray:
    return top + bottom * (1.0 - top[..., 3:4])


def poly_mask(points, shape=(CELL_H, CELL_W)) -> np.ndarray:
    img = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(img).polygon(points, fill=255)
    return np.array(img) > 0


def shift(part: np.ndarray, dx: float, dy: float) -> np.ndarray:
    return np.stack([ndi.shift(part[..., c], (dy, dx), order=1, mode="constant") for c in range(4)], axis=-1)


def recolor(part: np.ndarray, dark, light) -> np.ndarray:
    """Remap the colored-pencil fill of a part onto a dark..light ramp; ink lines stay ink."""
    a = part[..., 3:4]
    rgb = np.where(a > 1e-4, part[..., :3] / np.maximum(a, 1e-4), 0.0)
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    t = np.clip((lum - 0.3) / 0.6, 0.0, 1.0)[..., None]
    ramp = np.array(dark, np.float32) * (1.0 - t) + np.array(light, np.float32) * t
    fill = np.clip((lum - 0.22) / 0.12, 0.0, 1.0)[..., None]
    out_rgb = rgb * (1.0 - fill) + ramp * fill
    return np.concatenate([out_rgb * a, a], axis=-1)


# ---------------------------------------------------------------- base parts

class Parts:
    """Cabin / wing / top fin / gun of one base frame, ready to place on a new body."""

    def __init__(self, core: np.ndarray, row: int):
        self.core = core
        self.row = row

    def _take(self, mask: np.ndarray) -> np.ndarray:
        return self.core * mask[..., None]

    def cabin(self, dx: float, dy: float = 0.0) -> np.ndarray:
        return shift(self._take(poly_mask(CABIN[self.row])), dx, dy)

    def wing(self, dx: float, body_bottom: float, dark, light) -> np.ndarray:
        part = recolor(self._take(poly_mask(WING[self.row])), dark, light)
        return shift(part, dx, body_bottom - BASE_BODY_BOTTOM)

    def top_fin(self, dx: float, body_top: float, dark, light) -> np.ndarray | None:
        if TOP_FIN[self.row] is None:
            return None
        part = recolor(self._take(poly_mask(TOP_FIN[self.row])), dark, light)
        return shift(part, dx, body_top - BASE_BODY_TOP)

    def gun(self, dx: float, body_bottom: float) -> np.ndarray:
        x0, x1, y0, y1 = GUN[self.row]
        m = np.zeros((CELL_H, CELL_W), bool)
        m[y0:y1, x0:x1] = True
        return shift(self._take(m), dx, body_bottom - BASE_BODY_BOTTOM - 4)  # strut tucked under the body


# ---------------------------------------------------------------- pencil renderer

def _hatch_field(h: int, w: int, seed: int) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    noise = rng.random((h, w)).astype(np.float32)
    length = 9 * SS
    k = np.zeros((length, length), np.float32)
    ang = math.radians(-35.0)
    for i in range(length * 2):
        t = i / (length * 2 - 1) - 0.5
        x = int(round((length - 1) / 2 + t * (length - 1) * math.cos(ang)))
        y = int(round((length - 1) / 2 + t * (length - 1) * math.sin(ang)))
        k[y, x] = 1.0
    k /= k.sum()
    strokes = ndi.convolve(noise, k, mode="wrap")
    strokes = ndi.gaussian_filter(strokes, 0.6 * SS / 2)
    lo, hi = np.percentile(strokes, [3, 97])
    strokes = np.clip((strokes - lo) / (hi - lo), 0.0, 1.0)
    pressure = ndi.gaussian_filter(rng.random((h, w)).astype(np.float32), 9 * SS)
    lo, hi = pressure.min(), pressure.max()
    pressure = (pressure - lo) / max(hi - lo, 1e-6)
    return strokes, pressure


class Sketch:
    """Supersampled canvas: faceted polygons filled with pencil hatching + ink outlines."""

    def __init__(self, seed: int):
        self.h, self.w = CELL_H * SS, CELL_W * SS
        self.rgba = np.zeros((self.h, self.w, 4), np.float32)  # premultiplied
        self.strokes, self.pressure = _hatch_field(self.h, self.w, seed)
        self.rng = np.random.default_rng(seed + 1)

    def _pts(self, points, jitter=0.25):
        out = []
        for x, y in points:
            out.append(((x + self.rng.uniform(-jitter, jitter)) * SS, (y + self.rng.uniform(-jitter, jitter)) * SS))
        return out

    def _mask(self, draw_fn) -> np.ndarray:
        img = Image.new("L", (self.w, self.h), 0)
        draw_fn(ImageDraw.Draw(img))
        return np.array(img).astype(np.float32) / 255.0

    def _paint(self, mask: np.ndarray, rgb: np.ndarray) -> None:
        a = mask[..., None]
        self.rgba = np.concatenate([rgb * a, a], axis=-1) + self.rgba * (1.0 - a)

    def facet(self, points, color, outline=1.5, density=0.78):
        pts = self._pts(points)
        mask = self._mask(lambda d: d.polygon(pts, fill=255))
        dens = np.clip(density + 0.55 * (self.strokes - 0.5) + 0.18 * (self.pressure - 0.5), 0.3, 1.0)[..., None]
        rgb = np.array(PAPER, np.float32) * (1.0 - dens) + np.array(color, np.float32) * dens
        self._paint(mask, rgb)
        if outline > 0:
            self.line(points + [points[0]], outline, jitter=0.0, pts=pts + [pts[0]])

    def line(self, points, width=1.2, color=INK, jitter=0.25, pts=None):
        pts = pts if pts is not None else self._pts(points, jitter)
        w = max(1, int(round(width * SS)))
        mask = self._mask(lambda d: d.line(pts, fill=255, width=w, joint="curve"))
        r = w / 2.0
        mask = np.maximum(mask, self._mask(lambda d: [d.ellipse((x - r, y - r, x + r, y + r), fill=255) for x, y in pts]))
        self._paint(mask, np.broadcast_to(np.array(color, np.float32), mask.shape + (3,)))

    def text(self, x, y, s, size, color=INK):
        font = ImageFont.truetype(FONT, int(size * SS))
        mask = self._mask(lambda d: d.text((x * SS, y * SS), s, fill=255, font=font, anchor="mm"))
        self._paint(mask, np.broadcast_to(np.array(color, np.float32), mask.shape + (3,)))

    def result(self) -> np.ndarray:
        return self.rgba.reshape(CELL_H, SS, CELL_W, SS, 4).mean(axis=(1, 3))


def arc(cx, cy, rx, ry, a0, a1, n=10):
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def bands(x0, x1, ys, colors, sk: Sketch, outline=1.5):
    """Horizontal cylinder / prism bands between y levels (top -> bottom)."""
    for (ya, yb), c in zip(zip(ys, ys[1:]), colors):
        sk.facet([(x0, ya), (x1, ya), (x1, yb), (x0, yb)], c, outline)


# ---------------------------------------------------------------- palettes

def rgb(hex_str: str) -> tuple[float, float, float]:
    v = int(hex_str.lstrip("#"), 16)
    return ((v >> 16 & 255) / 255.0, (v >> 8 & 255) / 255.0, (v & 255) / 255.0)


METAL = [rgb("eef0f6"), rgb("c4c8d4"), rgb("8d93a6")]
VIOLET = [rgb("cdb6ff"), rgb("9b72f0"), rgb("6c3fc8"), rgb("4a2a94")]
GREEN = [rgb("b6f0a0"), rgb("5cc85a"), rgb("2f9a40"), rgb("1d6a2c")]
WHITE = [rgb("ffffff"), rgb("eceee9"), rgb("c9cdc8")]
RED = [rgb("ffc2b4"), rgb("ff8a78"), rgb("e9524a"), rgb("b4303a")]
ORANGE = [rgb("ffd9a8"), rgb("ffb066")]
GOLD = [rgb("fff0a8"), rgb("f7cf52"), rgb("d9a12a"), rgb("a8711a")]
LACQUER = [rgb("6a4a7a"), rgb("4a3058"), rgb("2e1c3a")]


# ---------------------------------------------------------------- planes

def pen(parts: Parts) -> np.ndarray:
    """Ballpoint pen: push button, front clip, ribbed grip, metal cone + ball."""
    sk = Sketch(11)
    top, bottom = 30, 74
    # push button + plunger
    sk.facet([(4, 46), (10, 46), (10, 58), (4, 58)], METAL[1])
    sk.facet(arc(22, 52, 13, 13, 90, 270) + [(30, 39), (30, 65)], VIOLET[3])
    sk.facet([(14, 42), (30, 42), (30, 50), (12, 50)], VIOLET[2], 0.9)
    # barrel (slight taper)
    bands(30, 202, [top, 41, 52, 63, bottom], [VIOLET[0], VIOLET[1], VIOLET[2], VIOLET[3]], sk)
    sk.facet([(28, top - 1), (36, top - 1), (36, bottom + 1), (28, bottom + 1)], METAL[0])
    sk.line([(31, top + 1), (31, bottom - 1)], 0.8, METAL[2])
    # front ring + ribbed grip
    sk.facet([(200, top + 1), (210, top + 1), (210, bottom - 1), (200, bottom - 1)], METAL[0])
    sk.facet([(210, 34), (238, 37), (238, 67), (210, 70)], VIOLET[3])
    sk.facet([(210, 34), (238, 37), (238, 46), (210, 45)], VIOLET[2], 0.9)
    for x in range(214, 237, 5):
        sk.line([(x, 35.5 + (x - 210) * 0.1), (x, 68.5 - (x - 210) * 0.1)], 0.9)
    # metal cone + ball
    sk.facet([(238, 37), (272, 48), (272, 52), (238, 52)], METAL[0])
    sk.facet([(238, 52), (272, 52), (272, 56), (238, 67)], METAL[2])
    sk.facet(arc(276, 52, 4.5, 4.5, 0, 360, 14), METAL[2], 1.2)
    # clip (in front of the cabin)
    sk.facet([(112, 26), (118, 22), (174, 22), (174, 27), (118, 27)], METAL[0], 1.3)
    sk.facet([(118, 27), (174, 27), (176, top + 1), (114, top + 1)], METAL[1], 1.3)
    sk.facet(arc(177, 25, 5, 5, 0, 360, 12), METAL[1], 1.2)
    body = sk.result()
    return assemble(body, parts, cabin_dx=0, cabin_dy=2, top=top, bottom=bottom,
                    fin_dx=40, wing_dx=0, gun_dx=0, gun_bottom=69, wing_ramp=(VIOLET[3], VIOLET[0]))


def marker(parts: Parts) -> np.ndarray:
    """Marker: fat white barrel with green label, cap posted on the back (clip = tail fin), felt chisel tip."""
    sk = Sketch(23)
    top, bottom = 20, 82
    # cap posted on the back + its clip
    sk.facet([(12, 4), (58, 6), (58, 12), (26, 12), (26, 20), (12, 20)], GREEN[2], 1.4)
    sk.facet(arc(20, 50, 14, 36, 90, 270) + [(72, 14), (72, 86)], GREEN[2])
    sk.facet(arc(20, 50, 12, 32, 180, 270, 6) + [(72, 18), (72, 34), (8, 34)], GREEN[1], 1.0)
    for x in (62, 66):
        sk.line([(x, 15), (x, 85)], 0.9)
    # barrel: white plastic
    bands(72, 206, [top, 34, 52, 68, bottom], [WHITE[0], WHITE[1], WHITE[1], WHITE[2]], sk)
    # label + scribble swatch
    sk.facet([(132, 26), (198, 26), (198, 58), (132, 58)], GREEN[1], 1.3)
    sk.facet([(132, 26), (198, 26), (198, 34), (132, 34)], GREEN[0], 1.0)
    sk.line([(140, 50), (146, 40), (152, 51), (158, 40), (164, 51), (170, 40), (176, 51), (182, 40), (188, 50)], 1.6, GREEN[3])
    # collar, tip holder, felt chisel tip
    sk.facet([(206, 24), (220, 24), (220, 78), (206, 78)], GREEN[3])
    sk.facet([(206, 24), (220, 24), (220, 36), (206, 36)], GREEN[2], 1.0)
    sk.facet([(220, 30), (238, 36), (238, 66), (220, 72)], WHITE[1])
    sk.facet([(220, 30), (238, 36), (238, 46), (220, 44)], WHITE[0], 1.0)
    sk.facet([(238, 38), (266, 34), (282, 47), (238, 50)], GREEN[1])
    sk.facet([(238, 50), (282, 47), (270, 62), (238, 64)], GREEN[3])
    body = sk.result()
    return assemble(body, parts, cabin_dx=22, cabin_dy=0, top=top, bottom=78,
                    fin_dx=6, wing_dx=0, gun_dx=0, gun_bottom=74, wing_ramp=(GREEN[3], GREEN[0]))


def ruler(parts: Parts) -> np.ndarray:
    """Ruler: flat red bar with cm ticks + numbers, pointed end, set-square tail with a cut-out."""
    sk = Sketch(37)
    top, bottom = 40, 70
    # set square tail (cut-out drawn as a hole later)
    sk.facet([(6, 2), (6, 74), (64, 74)], ORANGE[1], 1.6)
    sk.facet([(6, 2), (6, 74), (14, 74), (14, 26)], ORANGE[0], 1.0)
    hole = [(15, 34), (15, 64), (40, 64)]
    sk.facet(hole, PAPER, 1.3)
    # ruler bar: thin top bevel + flat face
    sk.facet([(30, top), (258, top), (258, top + 6), (30, top + 6)], RED[0])
    sk.facet([(30, top + 6), (258, top + 6), (258, bottom), (30, bottom)], RED[1])
    sk.facet([(258, top), (285, 57), (258, bottom)], RED[2])
    sk.facet([(258, top), (285, 57), (258, top + 6)], RED[0], 1.0)
    for i, x in enumerate(range(44, 252, 4)):
        length = 9 if i % 10 == 0 else (6 if i % 5 == 0 else 3.5)
        sk.line([(x, top + 6), (x, top + 6 + length)], 0.8, RED[3], jitter=0.1)
        if i % 10 == 0 and 0 < i:
            sk.text(x, top + 21, str(i // 10), 7.5, RED[3])
    sk.facet(arc(38, 61, 4, 4, 0, 360, 12), PAPER, 1.1)
    body = sk.result()
    # real holes in the set square + ruler: transparent, sticker rim goes around them
    body = cut_hole(body, [(18, 40), (18, 61), (33, 61)])
    return assemble(body, parts, cabin_dx=30, cabin_dy=4, top=top, bottom=bottom,
                    fin_dx=22, wing_dx=6, gun_dx=10, gun_bottom=bottom, wing_ramp=(RED[3], RED[0]))


def fountain_pen(parts: Parts) -> np.ndarray:
    """Fountain pen: gold barrel with rings, back clip, lacquer section, big gold nib with slit."""
    sk = Sketch(51)

    def edge(x, sign):
        return 52 + sign * (24 - 3.5 * ((x - 112) / 86.0) ** 2)

    xs = list(range(26, 200, 8)) + [198]
    ys_levels = [-1.0, -0.45, 0.15, 0.6, 1.0]
    colors = [GOLD[0], GOLD[1], GOLD[2], GOLD[3]]
    for (la, lb), c in zip(zip(ys_levels, ys_levels[1:]), colors):
        upper = [(x, 52 + la * (edge(x, 1) - 52)) for x in xs]
        lower = [(x, 52 + lb * (edge(x, 1) - 52)) for x in reversed(xs)]
        sk.facet(upper + lower, c)
    # back end cap + finial
    sk.facet(arc(26, 52, 20, 23, 90, 270, 12) + [(26, 29)], LACQUER[1])
    sk.facet(arc(26, 52, 17, 18, 180, 260, 6) + [(26, 34), (12, 46)], LACQUER[0], 0.9)
    sk.facet([(4, 47), (9, 47), (9, 57), (4, 57)], GOLD[1], 1.2)
    # rings
    for x0, x1, c in ((56, 64, LACQUER[1]), (186, 198, LACQUER[1]), (66, 70, GOLD[0])):
        sk.facet([(x0, edge(x0, -1) - 0.5), (x1, edge(x1, -1) - 0.5), (x1, edge(x1, 1) + 0.5), (x0, edge(x0, 1) + 0.5)], c)
    # section
    sk.facet([(198, 32), (218, 36), (218, 68), (198, 72)], LACQUER[2])
    sk.facet([(198, 32), (218, 36), (218, 44), (198, 42)], LACQUER[0], 1.0)
    # nib
    sk.facet([(214, 37), (240, 35), (268, 44), (286, 52), (250, 52), (214, 52)], GOLD[0])
    sk.facet([(214, 52), (250, 52), (286, 52), (268, 60), (240, 68), (214, 66)], GOLD[2])
    sk.line([(222, 44), (232, 41), (240, 44)], 0.9, GOLD[3])
    sk.line([(222, 60), (232, 63), (240, 60)], 0.9, GOLD[3])
    sk.facet(arc(248, 52, 3.4, 3.4, 0, 360, 12), INK, 0.6)
    sk.line([(251, 52), (286, 52)], 1.1)
    # clip on the back half
    sk.facet([(30, 22), (96, 22), (96, 28), (34, 28)], GOLD[0], 1.3)
    sk.facet(arc(100, 26, 5.5, 5.5, 0, 360, 12), GOLD[1], 1.2)
    body = sk.result()
    return assemble(body, parts, cabin_dx=50, cabin_dy=2, top=28, bottom=76,
                    fin_dx=44, wing_dx=6, gun_dx=-2, gun_bottom=70, wing_ramp=(GOLD[3], GOLD[0]))


def cut_hole(img: np.ndarray, poly) -> np.ndarray:
    m = poly_mask(poly)
    m = ndi.gaussian_filter(m.astype(np.float32), 0.5)
    return img * (1.0 - m[..., None])


def assemble(body, parts: Parts, cabin_dx, cabin_dy, top, bottom, fin_dx, wing_dx, gun_dx, gun_bottom, wing_ramp):
    """Body + base parts in the base draw order: gun, body, wing, top fin, cabin."""
    dark, light = wing_ramp
    out = over(body, parts.gun(gun_dx, gun_bottom))
    out = over(parts.wing(wing_dx, bottom, dark, light), out)
    fin = parts.top_fin(fin_dx, top, dark, light)
    if fin is not None:
        out = over(fin, out)
    return over(parts.cabin(cabin_dx, cabin_dy), out)


def fit_to_flame(core: np.ndarray) -> np.ndarray:
    ax, ay = FIT_ANCHOR
    scaled = np.stack([
        ndi.affine_transform(core[..., c], [1.0 / FIT_SCALE, 1.0 / FIT_SCALE],
                             offset=[ay - ay / FIT_SCALE, ax - ax / FIT_SCALE], order=1, mode="constant")
        for c in range(4)
    ], axis=-1)
    sk = Sketch(7)
    sk.facet(NOZZLE, METAL[1], 1.4)
    sk.facet([(20, 51), (32, 56), (44, 58), (44, 61), (20, 59)], METAL[0], 1.0)
    sk.facet([(20, 51), (25, 53), (25, 71), (20, 73)], METAL[2], 1.2)
    sk.line([(32, 56), (32, 68)], 1.0)
    return over(scaled, sk.result())


VARIANTS = [None, pen, marker, ruler, fountain_pen]  # index = atlas column


def main(out_path: str = ATLAS) -> None:
    base = load_base()
    atlas = np.zeros((CELL_H * ROWS, CELL_W * len(VARIANTS), 4), np.float32)
    for col, fn in enumerate(VARIANTS):
        for row, frame in enumerate(base):
            cell = frame if fn is None else add_rim(fit_to_flame(fn(Parts(strip_rim(frame), row))))
            atlas[row * CELL_H:(row + 1) * CELL_H, col * CELL_W:(col + 1) * CELL_W] = cell
    Image.fromarray((np.clip(atlas, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(out_path)
    print("wrote", out_path, atlas.shape[1], "x", atlas.shape[0])


if __name__ == "__main__":
    import sys

    main(sys.argv[1] if len(sys.argv) > 1 else ATLAS)
