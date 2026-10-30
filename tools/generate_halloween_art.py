"""Halloween event art (seasonal event «halloween»): watercolor pumpkins atlas + battle / menu background.

    python tools/generate_halloween_art.py            # both
    python tools/generate_halloween_art.py pumpkins   # src/features/answer/pumpkins_atlas.png
    python tools/generate_halloween_art.py background # src/ui/backgrounds/halloween_2027/bg_haunted_house.png
    python tools/generate_halloween_art.py banner     # src/common/events/halloween/banner_moon_castle.png (2026 menu
                                                      #   banner, cut from the 2026 sky bg_moon_castle.png)

Pumpkins: same layout as `balloons_atlas.png` (1280x720, 5x3 cells of 256x240, body centered where the
balloon body is, so the answer number sits on it) and the same 15 hues in the same order (`Answer.BALLOON_TINTS`
= pop tint per frame). Background: 1080x720 twilight pumpkin hills (unique things near the middle,
generic sky / hills at the side edges: the sky scrolls mirrored), level horizon.
Deterministic (fixed seeds). Needs numpy + Pillow.
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUMPKINS_OUT = os.path.join(ROOT, "src", "features", "answer", "pumpkins_atlas.png")
BACKGROUND_OUT = os.path.join(ROOT, "src", "ui", "backgrounds", "halloween_2027", "bg_haunted_house.png")

# Same hues / order as the balloons (`Answer.BALLOON_TINTS`), a bit richer for a painted pumpkin.
HUES = [
	(0.74, 0.30, 0.34), (0.90, 0.70, 0.22), (0.50, 0.74, 0.58), (0.52, 0.70, 0.84), (0.80, 0.33, 0.56),
	(0.56, 0.42, 0.72), (0.93, 0.52, 0.20), (0.36, 0.76, 0.76), (0.34, 0.52, 0.40), (0.86, 0.62, 0.22),
	(0.18, 0.47, 0.50), (0.68, 0.74, 0.25), (0.24, 0.40, 0.72), (0.70, 0.56, 0.74), (0.58, 0.20, 0.25),
]
CELL_W, CELL_H = 256, 240
RIM = (252, 248, 240)


# --- noise ------------------------------------------------------------------------

def value_noise(h: int, w: int, cells: float, rng: np.random.Generator) -> np.ndarray:
	"""Smooth value noise 0..1 with about `cells` features across the longer side."""
	gx = int(math.ceil(cells * w / max(h, w))) + 2
	gy = int(math.ceil(cells * h / max(h, w))) + 2
	grid = rng.random((gy, gx))
	ys = np.linspace(0, gy - 2.001, h)
	xs = np.linspace(0, gx - 2.001, w)
	y0 = ys.astype(int)
	x0 = xs.astype(int)
	ty = ys - y0
	tx = xs - x0
	ty = ty * ty * (3 - 2 * ty)
	tx = tx * tx * (3 - 2 * tx)
	a = grid[np.ix_(y0, x0)]
	b = grid[np.ix_(y0, x0 + 1)]
	c = grid[np.ix_(y0 + 1, x0)]
	d = grid[np.ix_(y0 + 1, x0 + 1)]
	top = a + (b - a) * tx[None, :]
	bot = c + (d - c) * tx[None, :]
	return top + (bot - top) * ty[:, None]


def fbm(h: int, w: int, base: float, octaves: int, rng: np.random.Generator) -> np.ndarray:
	out = np.zeros((h, w))
	amp = 1.0
	total = 0.0
	for i in range(octaves):
		out += value_noise(h, w, base * 2 ** i, rng) * amp
		total += amp
		amp *= 0.5
	return out / total


def blur(arr: np.ndarray, radius: float) -> np.ndarray:
	img = Image.fromarray(np.clip(arr * 255, 0, 255).astype(np.uint8))
	return np.asarray(img.filter(ImageFilter.GaussianBlur(radius)), dtype=float) / 255.0


def ellipse_mask(h: int, w: int, cx: float, cy: float, rx: float, ry: float, ss: int = 3) -> np.ndarray:
	"""Antialiased filled ellipse 0..1."""
	img = Image.new("L", (w * ss, h * ss), 0)
	ImageDraw.Draw(img).ellipse(((cx - rx) * ss, (cy - ry) * ss, (cx + rx) * ss, (cy + ry) * ss), fill=255)
	return np.asarray(img.resize((w, h), Image.LANCZOS), dtype=float) / 255.0


def polygon_mask(h: int, w: int, points: list[tuple[float, float]], ss: int = 3) -> np.ndarray:
	img = Image.new("L", (w * ss, h * ss), 0)
	ImageDraw.Draw(img).polygon([(x * ss, y * ss) for x, y in points], fill=255)
	return np.asarray(img.resize((w, h), Image.LANCZOS), dtype=float) / 255.0


def stroke_mask(h: int, w: int, points: list[tuple[float, float]], width: float, ss: int = 3) -> np.ndarray:
	img = Image.new("L", (w * ss, h * ss), 0)
	draw = ImageDraw.Draw(img)
	pts = [(x * ss, y * ss) for x, y in points]
	draw.line(pts, fill=255, width=max(1, int(width * ss)), joint="curve")
	r = width * ss / 2
	for x, y in (pts[0], pts[-1]):
		draw.ellipse((x - r, y - r, x + r, y + r), fill=255)
	return np.asarray(img.resize((w, h), Image.LANCZOS), dtype=float) / 255.0


def dilate(mask: np.ndarray, px: int, soft: float = 0.6) -> np.ndarray:
	"""Round-ish grow by `px` (two passes of a square max filter = an octagon), lightly antialiased."""
	img = Image.fromarray(np.clip(mask * 255, 0, 255).astype(np.uint8))
	half = max(1, px // 2)
	img = img.filter(ImageFilter.MaxFilter(half * 2 + 1)).filter(ImageFilter.MaxFilter((px - half) * 2 + 1))
	return np.asarray(img.filter(ImageFilter.GaussianBlur(soft)), dtype=float) / 255.0


def edge_darkening(mask: np.ndarray, width: float) -> np.ndarray:
	"""1 at the inner rim of `mask`, fading inward (watercolor pigment pooling)."""
	inner = blur(mask, width)
	return np.clip((mask - inner) * 2.2, 0, 1) * mask


def lerp(a, b, t):
	return a + (b - a) * t


# --- pumpkins ---------------------------------------------------------------------

def bezier(p0, p1, p2, steps: int = 24) -> list[tuple[float, float]]:
	pts = []
	for i in range(steps + 1):
		t = i / steps
		x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
		y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
		pts.append((x, y))
	return pts


def paint_pumpkin(hue: tuple[float, float, float], seed: int) -> Image.Image:
	rng = np.random.default_rng(seed)
	h, w = CELL_H, CELL_W
	cx, cy = 128.0, 122.0
	body_rx, body_ry = 86.0, rng.uniform(64.0, 72.0)
	wobble = rng.uniform(-3, 3)
	spread = rng.uniform(0.94, 1.06)
	# Lobes back to front: (x offset, rx, ry, shade)
	lobes = [
		(-46 * spread + wobble, 44, body_ry - 4, 0.80),
		(46 * spread + wobble, 44, body_ry - 4, 0.80),
		(-25 * spread, 40, body_ry, 0.92),
		(25 * spread, 40, body_ry, 0.92),
		(0, 34, body_ry + 2, 1.0),
	]
	base = np.array(hue)
	color = np.zeros((h, w, 3))
	alpha = np.zeros((h, w))
	bloom = fbm(h, w, 4.0, 3, rng)
	grain = fbm(h, w, 40.0, 2, rng)
	yy, xx = np.mgrid[0:h, 0:w].astype(float)
	for dx, rx, ry, shade in lobes:
		lx = cx + dx
		mask = ellipse_mask(h, w, lx, cy, rx, ry)
		# Round shading: lighter toward the upper middle of the lobe, darker at its flanks.
		nx = (xx - lx) / rx
		ny = (yy - cy) / ry
		rad = np.clip(np.sqrt(nx * nx + ny * ny), 0, 1)
		light = 1.0 - 0.38 * rad ** 1.8 + 0.12 * np.clip(-ny, 0, 1)
		tone = base * shade * light[..., None]
		# Watercolor blooms: uneven pigment, a bit of granulation.
		tone = tone * (0.82 + 0.3 * bloom[..., None]) * (0.94 + 0.1 * grain[..., None])
		edge = edge_darkening(mask, 6.0)
		tone = tone * (1.0 - 0.32 * edge[..., None])
		color = color * (1 - mask[..., None]) + tone * mask[..., None]
		alpha = np.maximum(alpha, mask)
	color = np.clip(color, 0, 1)
	# Rib grooves between the lobes (darker hue pencil strokes).
	ink = base * 0.45
	for dx in (-31, -11, 11, 31):
		top = (cx + dx * 0.55, cy - body_ry + 8)
		mid = (cx + dx * 1.25, cy)
		bot = (cx + dx * 0.6, cy + body_ry - 6)
		groove = stroke_mask(h, w, bezier(top, mid, bot), 2.6) * alpha
		color = color * (1 - groove[..., None] * 0.55) + ink * groove[..., None] * 0.55
	# Highlight streak on the front lobe.
	hl = stroke_mask(h, w, bezier((cx - 14, cy - 44), (cx - 22, cy - 18), (cx - 16, cy + 4)), 7.0)
	hl = blur(hl, 2.0) * alpha
	color = color + (1 - color) * hl[..., None] * 0.35
	# Stem: curved green-brown block + a curly vine.
	stem_hue = np.array((0.36, 0.44, 0.22)) if seed % 3 else np.array((0.44, 0.36, 0.20))
	tilt = rng.uniform(-6, 6)
	stem_pts = [
		(cx - 9, cy - body_ry + 14), (cx - 11 + tilt * 0.3, cy - body_ry - 6), (cx - 6 + tilt, cy - body_ry - 26),
		(cx + 6 + tilt, cy - body_ry - 30), (cx + 10 + tilt * 0.6, cy - body_ry - 22), (cx + 7, cy - body_ry - 4),
		(cx + 9, cy - body_ry + 14),
	]
	stem = polygon_mask(h, w, stem_pts)
	stem_tone = stem_hue * (0.85 + 0.25 * bloom[..., None])
	stem_edge = edge_darkening(stem, 3.0)
	stem_tone = stem_tone * (1 - 0.35 * stem_edge[..., None])
	color = color * (1 - stem[..., None]) + stem_tone * stem[..., None]
	alpha = np.maximum(alpha, stem)
	side = 1 if seed % 2 else -1
	vine_pts = []
	for i in range(28):
		t = i / 27
		ang = t * 4.4
		r = 15 * (1 - t * 0.6)
		vine_pts.append((cx + side * (12 + 30 * t) + side * math.cos(ang) * r * 0.5, cy - body_ry - 4 + math.sin(ang) * r * 0.45 - t * 6))
	vine = stroke_mask(h, w, vine_pts, 2.4)
	color = color * (1 - vine[..., None]) + (stem_hue * 0.8) * vine[..., None]
	alpha = np.maximum(alpha, vine)
	# Soft graphite outline of the whole silhouette.
	outline = edge_darkening(np.clip(alpha, 0, 1), 1.6)
	color = color * (1 - outline[..., None] * 0.45) + np.array((0.16, 0.2, 0.25)) * outline[..., None] * 0.45
	# White sticker rim (die-cut) with a faint warm edge.
	rim = dilate(alpha, 9)
	rim_edge = np.clip(rim - dilate(alpha, 8), 0, 1)
	out = np.zeros((h, w, 4))
	rim_color = np.array(RIM) / 255.0
	out[..., :3] = rim_color * (1 - alpha[..., None]) + color * alpha[..., None]
	out[..., :3] = out[..., :3] * (1 - rim_edge[..., None] * 0.12)
	out[..., 3] = np.clip(np.maximum(rim, alpha), 0, 1)
	return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")


def make_pumpkins() -> None:
	atlas = Image.new("RGBA", (CELL_W * 5, CELL_H * 3), (0, 0, 0, 0))
	for index, hue in enumerate(HUES):
		cell = paint_pumpkin(hue, 1031 + index * 17)
		atlas.paste(cell, ((index % 5) * CELL_W, (index // 5) * CELL_H))
	atlas.save(PUMPKINS_OUT)
	print("wrote", os.path.relpath(PUMPKINS_OUT, ROOT))


# --- background -------------------------------------------------------------------

BG_W, BG_H = 1080, 720


def noisy_mask(mask: np.ndarray, rng: np.random.Generator, amount: float = 0.35, scale: float = 18.0,
		soften: float = 2.5) -> np.ndarray:
	"""Wobbly watercolor edge: blur the shape, push its 0.5 level around with noise."""
	h, w = mask.shape
	soft = blur(mask, soften)
	n = fbm(h, w, scale, 3, rng) - 0.5
	return np.clip((soft - 0.5 + n * amount) * 6.0 + 0.5, 0, 1)


def wash(canvas: np.ndarray, mask: np.ndarray, color, rng: np.random.Generator, *, bloom: float = 0.22,
		edge: float = 0.28, opacity: float = 1.0, bloom_scale: float = 5.0) -> np.ndarray:
	"""One watercolor layer: uneven pigment, darker drying edge, glazed over the canvas."""
	h, w = mask.shape
	pigment = np.array(color, dtype=float)
	var = fbm(h, w, bloom_scale, 3, rng)
	tone = pigment[None, None, :] * (1.0 - bloom + 2 * bloom * var[..., None])
	rim = edge_darkening(mask, 5.0)
	tone = tone * (1.0 - edge * rim[..., None])
	a = (mask * opacity)[..., None]
	return canvas * (1 - a) + np.clip(tone, 0, 1) * a


def hill_mask(h: int, w: int, base_y: float, bumps: list[tuple[float, float, float]], rng) -> np.ndarray:
	"""Everything below a smooth ridge line: base + gaussian bumps (x, height, width)."""
	xs = np.arange(w, dtype=float)
	ridge = np.full(w, float(base_y))
	for bx, bh, bw in bumps:
		ridge -= bh * np.exp(-((xs - bx) / bw) ** 2)
	ridge += (fbm(1, w, 12.0, 2, rng)[0] - 0.5) * 6.0
	yy = np.arange(h, dtype=float)[:, None]
	return np.clip(yy - ridge[None, :] + 0.5, 0, 1)


def glow(h: int, w: int, cx: float, cy: float, radius: float) -> np.ndarray:
	yy, xx = np.mgrid[0:h, 0:w].astype(float)
	d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / radius
	return np.clip(np.exp(-d * d * 2.2), 0, 1)


def bat_points(cx: float, cy: float, s: float) -> list[tuple[float, float]]:
	pts = [(0, -2), (-3, -6), (-8, -3), (-14, -7), (-20, -2), (-17, 0), (-13, 4), (-9, 1), (-5, 4), (-2, 2), (0, 5),
		(2, 2), (5, 4), (9, 1), (13, 4), (17, 0), (20, -2), (14, -7), (8, -3), (3, -6)]
	return [(cx + x * s, cy + y * s) for x, y in pts]


def layer(draw_fn, h: int = BG_H, w: int = BG_W, soft: float = 0.0) -> np.ndarray:
	"""0..1 mask drawn by `draw_fn(ImageDraw)` (supersampled)."""
	ss = 2
	img = Image.new("L", (w * ss, h * ss), 0)
	draw_fn(ImageDraw.Draw(img), ss)
	img = img.resize((w, h), Image.LANCZOS)
	if soft > 0:
		img = img.filter(ImageFilter.GaussianBlur(soft))
	return np.asarray(img, dtype=float) / 255.0


def make_background() -> None:
	rng = np.random.default_rng(31102026)
	h, w = BG_H, BG_W
	yy, xx = np.mgrid[0:h, 0:w].astype(float)
	# Sky: violet top → plum → warm orange glow over the horizon (wet-in-wet).
	t = np.clip(yy / 470.0, 0, 1)[..., None]
	top = np.array((0.30, 0.25, 0.47))
	mid = np.array((0.56, 0.40, 0.62))
	low = np.array((0.97, 0.69, 0.44))
	sky = np.where(t < 0.55, top + (mid - top) * (t / 0.55), mid + (low - mid) * ((t - 0.55) / 0.45))
	blooms = fbm(h, w, 3.0, 4, rng)
	sky = sky * (0.9 + 0.2 * blooms[..., None])
	sky = sky + (np.array((1.0, 0.84, 0.58)) - sky) * (glow(h, w, 540, 470, 420)[..., None] * 0.45)
	canvas = np.clip(sky, 0, 1)

	def draw_stars(d: ImageDraw.ImageDraw, ss: int) -> None:
		for _ in range(70):
			sx, sy = rng.uniform(20, w - 20), rng.uniform(15, 250)
			if abs(sx - 560) < 110 and sy < 270:
				continue
			r = rng.uniform(1.0, 2.4)
			d.ellipse(((sx - r) * ss, (sy - r) * ss, (sx + r) * ss, (sy + r) * ss), fill=int(rng.uniform(150, 255)))
		for _ in range(9):
			sx, sy, r = rng.uniform(60, w - 60), rng.uniform(20, 220), rng.uniform(5, 9)
			pts = [(sx, sy - r), (sx + r * 0.25, sy - r * 0.25), (sx + r, sy), (sx + r * 0.25, sy + r * 0.25),
				(sx, sy + r), (sx - r * 0.25, sy + r * 0.25), (sx - r, sy), (sx - r * 0.25, sy - r * 0.25)]
			d.polygon([(x * ss, y * ss) for x, y in pts], fill=230)

	stars = layer(draw_stars, soft=0.5)
	canvas = canvas + (np.array((1.0, 0.95, 0.78)) - canvas) * stars[..., None] * 0.9
	# Moon + halo + soft craters.
	mx0, my0 = 560.0, 168.0
	canvas = canvas + (np.array((1.0, 0.93, 0.75)) - canvas) * glow(h, w, mx0, my0, 170)[..., None] * 0.35
	moon = noisy_mask(ellipse_mask(h, w, mx0, my0, 64, 64), rng, amount=0.12, scale=30, soften=1.2)
	canvas = wash(canvas, moon, (1.0, 0.94, 0.74), rng, bloom=0.08, edge=0.18)
	for cx, cy, cr in ((540, 150, 13), (585, 182, 9), (566, 196, 6), (530, 186, 7)):
		crater = noisy_mask(ellipse_mask(h, w, cx, cy, cr, cr * 0.9), rng, amount=0.2, scale=40, soften=1.0)
		canvas = wash(canvas, crater, (0.93, 0.83, 0.6), rng, bloom=0.1, edge=0.3, opacity=0.6)
	# Wispy clouds.
	for cx, cy, rx, ry in ((470, 214, 150, 16), (690, 150, 120, 12), (200, 120, 130, 14), (900, 232, 140, 15)):
		cloud = noisy_mask(ellipse_mask(h, w, cx, cy, rx, ry), rng, amount=0.5, scale=14, soften=6)
		canvas = wash(canvas, cloud, (0.76, 0.64, 0.82), rng, bloom=0.15, edge=0.1, opacity=0.55)
	# Bats around the moon.
	bat_list = ((470, 120, 1.5), (650, 100, 1.2), (690, 232, 1.0), (430, 252, 0.9), (612, 60, 0.8))
	bats = layer(lambda d, ss: [d.polygon([(x * ss, y * ss) for x, y in bat_points(bx, by, bs)], fill=255)
		for bx, by, bs in bat_list], soft=0.4)
	canvas = wash(canvas, bats, (0.2, 0.15, 0.27), rng, bloom=0.1, edge=0.0)
	# Far hills.
	far = hill_mask(h, w, 470, [(140, 50, 160), (420, 30, 140), (760, 46, 170), (1000, 40, 150)], rng)
	canvas = wash(canvas, noisy_mask(far, rng, 0.25, 20, 2.0), (0.44, 0.38, 0.60), rng, bloom=0.18)
	# Mist band.
	mist = np.clip(1 - np.abs(yy - 500) / 34, 0, 1) * (0.6 + 0.4 * fbm(h, w, 6, 2, rng))
	canvas = canvas + (np.array((0.88, 0.82, 0.92)) - canvas) * mist[..., None] * 0.45
	# Middle hill with the haunted house.
	mid_hill = hill_mask(h, w, 548, [(540, 110, 210), (180, 36, 160), (900, 40, 170)], rng)
	canvas = wash(canvas, noisy_mask(mid_hill, rng, 0.25, 20, 2.0), (0.35, 0.31, 0.49), rng, bloom=0.2)
	hx, hy = 540.0, 448.0

	def draw_house(d: ImageDraw.ImageDraw, ss: int) -> None:
		for poly in (
			[(hx - 62, hy), (hx - 60, hy - 64), (hx + 44, hy - 66), (hx + 46, hy)],
			[(hx - 72, hy - 60), (hx - 6, hy - 118), (hx + 56, hy - 62)],
			[(hx + 18, hy - 66), (hx + 20, hy - 132), (hx + 50, hy - 130), (hx + 52, hy - 66)],
			[(hx + 10, hy - 126), (hx + 35, hy - 188), (hx + 62, hy - 124)],
			[(hx - 44, hy - 90), (hx - 42, hy - 116), (hx - 30, hy - 118), (hx - 30, hy - 100)],
		):
			d.polygon([(x * ss, y * ss) for x, y in poly], fill=255)

	house = noisy_mask(layer(draw_house), rng, 0.12, 30, 1.0)
	canvas = wash(canvas, house, (0.25, 0.2, 0.33), rng, bloom=0.15, edge=0.2)

	def draw_windows(d: ImageDraw.ImageDraw, ss: int) -> None:
		for x0, y0, x1, y1 in ((hx - 46, hy - 50, hx - 28, hy - 30), (hx - 8, hy - 50, hx + 10, hy - 30),
				(hx + 28, hy - 116, hx + 42, hy - 98), (hx + 20, hy - 38, hx + 34, hy)):
			d.rounded_rectangle((x0 * ss, y0 * ss, x1 * ss, y1 * ss), radius=5 * ss, fill=255)

	win = layer(draw_windows)
	canvas = canvas + (np.array((1.0, 0.78, 0.36)) - canvas) * blur(win, 9)[..., None] * 0.55
	canvas = wash(canvas, win, (1.0, 0.83, 0.4), rng, bloom=0.12, edge=0.25)
	# A friendly ghost by the house.
	gx, gy = 662.0, 362.0

	def draw_ghost(d: ImageDraw.ImageDraw, ss: int) -> None:
		d.ellipse(((gx - 22) * ss, (gy - 26) * ss, (gx + 22) * ss, (gy + 18) * ss), fill=255)
		tail = [(gx - 22, gy - 4), (gx - 24, gy + 30), (gx - 12, gy + 22), (gx, gy + 32), (gx + 12, gy + 22),
			(gx + 24, gy + 30), (gx + 22, gy - 4)]
		d.polygon([(x * ss, y * ss) for x, y in tail], fill=255)

	ghost = noisy_mask(layer(draw_ghost), rng, 0.15, 28, 1.5)
	canvas = wash(canvas, ghost, (0.98, 0.96, 1.0), rng, bloom=0.06, edge=0.2, opacity=0.88)
	face = np.maximum(ellipse_mask(h, w, gx - 8, gy - 6, 3.5, 5), ellipse_mask(h, w, gx + 8, gy - 6, 3.5, 5))
	face = np.maximum(face, ellipse_mask(h, w, gx, gy + 6, 4, 3))
	canvas = canvas * (1 - face[..., None] * 0.85) + np.array((0.2, 0.17, 0.27)) * face[..., None] * 0.85
	# Front hill + pumpkin patch.
	front = hill_mask(h, w, 640, [(540, 70, 260), (120, 40, 180), (960, 46, 190)], rng)
	canvas = wash(canvas, noisy_mask(front, rng, 0.25, 18, 2.0), (0.31, 0.27, 0.39), rng, bloom=0.22)
	for px, py, pr in ((430, 612, 30), (500, 596, 22), (612, 604, 34), (690, 622, 24), (360, 640, 20), (760, 640, 18)):
		body = noisy_mask(ellipse_mask(h, w, px, py, pr * 1.2, pr), rng, 0.15, 30, 1.0)
		canvas = wash(canvas, body, (0.94, 0.52, 0.17), rng, bloom=0.16, edge=0.35)
		for k in (-0.5, 0.0, 0.5):
			rib = stroke_mask(h, w, bezier((px + k * pr * 0.9, py - pr * 0.9), (px + k * pr * 1.5, py),
				(px + k * pr * 0.9, py + pr * 0.9), 12), 1.6)
			canvas = canvas * (1 - rib[..., None] * 0.35) + np.array((0.6, 0.27, 0.08)) * rib[..., None] * 0.35
		stem = polygon_mask(h, w, [(px - 3, py - pr + 3), (px - 2, py - pr - 9), (px + 4, py - pr - 10),
			(px + 3, py - pr + 3)])
		canvas = wash(canvas, stem, (0.33, 0.42, 0.2), rng, bloom=0.1, edge=0.2)
		if pr < 24:
			continue
		s = pr / 30.0

		def draw_face(d: ImageDraw.ImageDraw, ss: int, px=px, py=py, s=s) -> None:
			for poly in (
				[(px - 14 * s, py - 4 * s), (px - 8 * s, py - 14 * s), (px - 3 * s, py - 4 * s)],
				[(px + 3 * s, py - 4 * s), (px + 8 * s, py - 14 * s), (px + 14 * s, py - 4 * s)],
				[(px - 15 * s, py + 3 * s), (px - 8 * s, py + 9 * s), (px - 4 * s, py + 5 * s), (px, py + 11 * s),
					(px + 4 * s, py + 5 * s), (px + 8 * s, py + 9 * s), (px + 15 * s, py + 3 * s), (px, py + 16 * s)],
			):
				d.polygon([(x * ss, y * ss) for x, y in poly], fill=255)

		carved = layer(draw_face)
		canvas = canvas + (np.array((1.0, 0.85, 0.4)) - canvas) * blur(carved, 6)[..., None] * 0.4
		canvas = canvas * (1 - carved[..., None]) + np.array((1.0, 0.86, 0.42)) * carved[..., None]

	# Bare little trees at the sides (generic: the sky scrolls mirrored).
	def draw_trees(d: ImageDraw.ImageDraw, ss: int) -> None:
		for tx, ty, ts in ((96, 470, 1.0), (1000, 482, 0.9), (250, 560, 0.7), (850, 566, 0.75)):
			d.line([(tx * ss, ty * ss), ((tx - 4 * ts) * ss, (ty - 80 * ts) * ss)], fill=255, width=int(9 * ts * ss))
			for ang, length in ((-0.9, 46), (0.7, 40), (-0.4, 30), (1.1, 30)):
				bx = tx - 4 * ts * (0.5 + 0.2 * ang)
				by = ty - 50 * ts - 12 * ang
				d.line([(bx * ss, by * ss), ((bx + math.sin(ang) * length * ts) * ss,
					(by - math.cos(ang) * length * ts) * ss)], fill=255, width=max(2, int(4 * ts * ss)))

	trees = layer(draw_trees, soft=0.6)
	canvas = wash(canvas, trees, (0.2, 0.17, 0.25), rng, bloom=0.1, edge=0.0)
	# Paper grain + soft vignette.
	grain = fbm(h, w, 160.0, 2, rng)
	canvas = canvas * (0.95 + 0.07 * grain[..., None])
	vig = np.clip(1.0 - 0.18 * (((xx - w / 2) / (w / 2)) ** 2 * 0.4 + ((yy - h / 2) / (h / 2)) ** 2 * 0.6), 0, 1)
	canvas = canvas * vig[..., None]
	os.makedirs(os.path.dirname(BACKGROUND_OUT), exist_ok=True)
	Image.fromarray((np.clip(canvas, 0, 1) * 255).astype(np.uint8), "RGB").save(BACKGROUND_OUT)
	print("wrote", os.path.relpath(BACKGROUND_OUT, ROOT))


# --- 2026 menu banner (from the 2026 sky picture) ----------------------------------

MOON_CASTLE_SKY = os.path.join(ROOT, "src", "ui", "backgrounds", "halloween", "bg_moon_castle.png")
BANNER_2026_OUT = os.path.join(ROOT, "src", "common", "events", "halloween", "banner_moon_castle.png")
# Frame of the menu CTA buttons («ПРИКЛЮЧЕНИЕ» / «ПРАКТИКА»): nine-patch, margins 70 / 60, picture inside the inner line.
CTA_FRAME = os.path.join(ROOT, "src", "game", "scenes", "menu", "ui", "btn_cta_wide.png")
CTA_PATCH_X, CTA_PATCH_Y = 70, 60
# Inner line of that frame ends 23 px from every edge: the picture starts there.
BANNER_INSET = 23
# 2x of the on-screen banner (`EventBanner.size` 672x160).
BANNER_SCALE = 2
BANNER_W, BANNER_H = 672 * BANNER_SCALE, 160 * BANNER_SCALE


def sparkle(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
	"""Four-point star like the ones in the 2026 sky."""
	k = r * 0.28
	draw.polygon([(cx, cy - r), (cx + k, cy - k), (cx + r, cy), (cx + k, cy + k), (cx, cy + r), (cx - k, cy + k),
		(cx - r, cy), (cx - k, cy - k)], fill=255)


def cta_frame(w: int, h: int, scale: int) -> tuple[np.ndarray, np.ndarray]:
	"""CTA button frame nine-patched to `w` x `h` (`scale` x the texture): RGBA 0..1 and the inside of its inner line."""
	tex = Image.open(CTA_FRAME).convert("RGBA")
	tex = tex.resize((tex.width * scale, tex.height * scale), Image.LANCZOS)
	mx, my = CTA_PATCH_X * scale, CTA_PATCH_Y * scale
	tw, th = tex.size
	xs = [(0, mx, 0, mx), (mx, tw - mx, mx, w - mx), (tw - mx, tw, w - mx, w)]
	ys = [(0, my, 0, my), (my, th - my, my, h - my), (th - my, th, h - my, h)]
	out = Image.new("RGBA", (w, h))
	for sx0, sx1, dx0, dx1 in xs:
		for sy0, sy1, dy0, dy1 in ys:
			out.paste(tex.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS), (dx0, dy0))
	rgba = np.asarray(out, dtype=float) / 255.0
	# Inside = paper reached from the middle without crossing a dark line.
	walls = Image.fromarray((((rgba[..., 3] > 0.5) & (rgba[..., :3].mean(axis=2) > 0.5)) * 128).astype(np.uint8), "L").copy()
	ImageDraw.floodfill(walls, (w // 2, h // 2), 255)
	inside = (np.asarray(walls) == 255).astype(float)
	return rgba, inside


def make_banner_2026() -> None:
	"""Menu event button of Halloween 2026: the moonlit castle of `bg_moon_castle.png` on the left, misty violet
	night for the texts, lavender hills and fog along the bottom, a lit pumpkin; the frame of the menu CTA buttons."""
	rng = np.random.default_rng(25102026)
	s = BANNER_SCALE
	h, w = BANNER_H, BANNER_W
	inset = BANNER_INSET
	src = Image.open(MOON_CASTLE_SKY).convert("RGB")
	yy, xx = np.mgrid[0:h, 0:w].astype(float)
	# Night sky = the picture's own sky, row by row (same rows as the castle cut below), so the cut melts in.
	cut = (462, 52, 822, 420)
	rows = np.asarray(src.crop((830, cut[1], 1060, cut[3])), dtype=float).mean(axis=1) / 255.0
	rows = np.asarray(Image.fromarray((rows[:, None, :] * 255).astype(np.uint8)).resize((1, h - 2 * inset * s), Image.BILINEAR),
		dtype=float)[:, 0, :] / 255.0
	rows = np.stack([np.convolve(np.pad(rows[:, c], 30, mode="edge"), np.ones(61) / 61, "valid") for c in range(3)], 1)
	rows = np.concatenate([np.repeat(rows[:1], inset * s, 0), rows, np.repeat(rows[-1:], inset * s, 0)])
	sky = np.repeat(rows[:, None, :], w, 1)
	sky = sky * (0.93 + 0.14 * fbm(h, w, 6.0, 4, rng)[..., None])
	canvas = np.clip(sky, 0, 1)
	# Where the moon of the castle cut sits: its glow spills over the sky.
	ch = h - 2 * inset * s
	cw = int(round((cut[2] - cut[0]) * ch / (cut[3] - cut[1])))
	moon_x = inset * s + (718 - cut[0]) * cw / (cut[2] - cut[0])
	moon_y = inset * s + (148 - cut[1]) * ch / (cut[3] - cut[1])
	canvas = canvas + (np.array((0.80, 0.72, 0.84)) - canvas) * (glow(h, w, moon_x, moon_y, 120 * s) * 0.55)[..., None]
	# Soft painted clouds behind the texts.
	for cx, cy, rx, ry in ((460, 40, 110, 13), (612, 28, 60, 9), (540, 94, 80, 9)):
		m = noisy_mask(ellipse_mask(h, w, cx * s, cy * s, rx * s, ry * s), rng, 0.7, 7.0, 10.0)
		canvas = wash(canvas, m, (0.62, 0.55, 0.80), rng, bloom=0.2, edge=0.12, opacity=0.45, bloom_scale=8.0)
	# Stars.
	stars = layer(lambda d, ss: [sparkle(d, x * s * ss, y * s * ss, r * s * ss) for x, y, r in (
		(214, 32, 3.6), (300, 30, 2.4), (402, 66, 3.0), (530, 60, 3.8), (640, 48, 2.6), (505, 31, 2.2),
		(355, 40, 2.0), (634, 86, 2.4), (440, 33, 1.8), (590, 100, 2.0))], h, w, 0.6)
	canvas = canvas + (np.array((1.0, 0.94, 0.74)) - canvas) * stars[..., None] * 0.9
	# Far hills with little pines, as in the picture.
	far = hill_mask(h, w, 127 * s, [(250 * s, 12 * s, 90 * s), (500 * s, 9 * s, 120 * s), (660 * s, 14 * s, 80 * s)], rng)
	pines = layer(lambda d, ss: [d.polygon([((x - 6 * k) * s * ss, (y + 2) * s * ss), ((x - 3 * k) * s * ss, (y - 7 * k) * s * ss),
		((x - 4.5 * k) * s * ss, (y - 7 * k) * s * ss), (x * s * ss, (y - 17 * k) * s * ss),
		((x + 4.5 * k) * s * ss, (y - 7 * k) * s * ss), ((x + 3 * k) * s * ss, (y - 7 * k) * s * ss),
		((x + 6 * k) * s * ss, (y + 2) * s * ss)], fill=255) for x, y, k in (
		(176, 123, 1.0), (186, 125, 0.8), (232, 116, 1.1), (241, 119, 0.8), (300, 119, 0.9), (318, 121, 0.7),
		(372, 123, 0.8), (478, 119, 0.9), (488, 122, 0.7))], h, w, 0.8)
	canvas = wash(canvas, np.maximum(noisy_mask(far, rng, 0.25, 30.0, 1.5), pines), (0.50, 0.42, 0.68), rng,
		bloom=0.15, edge=0.2, opacity=0.9)
	near = hill_mask(h, w, 144 * s, [(140 * s, 14 * s, 110 * s), (400 * s, 7 * s, 140 * s), (615 * s, 9 * s, 90 * s)], rng)
	canvas = wash(canvas, noisy_mask(near, rng, 0.25, 30.0, 2.0), (0.41, 0.34, 0.60), rng, bloom=0.18, edge=0.25)
	fog = np.clip((yy - 107 * s) / (40 * s), 0, 1) * (0.35 + 0.4 * fbm(h, w, 5.0, 3, rng))
	canvas = canvas + (np.array((0.86, 0.80, 0.94)) - canvas) * (fog * 0.4)[..., None]
	# Castle on its hill under the full moon, cut from the picture, melting into the night on the right.
	crop = src.crop(cut).resize((cw, ch), Image.LANCZOS)
	piece = np.zeros((h, w, 3))
	piece[inset * s:inset * s + ch, inset * s:inset * s + cw] = np.asarray(crop, dtype=float) / 255.0
	d = np.sqrt(((xx - (inset * s + cw * 0.40)) / (cw * 0.62)) ** 2 + ((yy - h * 0.62) / (h * 0.85)) ** 2)
	fade = np.clip((1.0 - d) / 0.32, 0, 1)
	fade = np.clip(fade + (fbm(h, w, 10.0, 3, rng) - 0.5) * 0.45 * (fade > 0.02) * (fade < 0.98), 0, 1)
	fade = blur(fade, 6) * (xx >= inset * s) * (xx < inset * s + cw)
	canvas = canvas * (1 - fade[..., None]) + piece * fade[..., None]
	# A lit jack-o'-lantern from the picture between the texts and the gift pile (soft oval cut).
	pump = src.crop((22, 568, 172, 676))
	pw = 64 * s
	ph = int(round(pump.height * pw / pump.width))
	pump = pump.resize((pw, ph), Image.LANCZOS)
	px, py = 404 * s, h - inset * s - ph + 6 * s
	piece = np.zeros((h, w, 3))
	piece[py:py + ph, px:px + pw] = np.asarray(pump, dtype=float) / 255.0
	pm = blur(ellipse_mask(h, w, px + pw * 0.5, py + ph * 0.6, pw * 0.4, ph * 0.42), 3)
	canvas = canvas + (np.array((1.0, 0.75, 0.40)) - canvas) * (glow(h, w, px + pw * 0.5, py + ph * 0.6, 50 * s) * 0.22)[..., None]
	canvas = canvas * (1 - pm[..., None]) + piece * pm[..., None]
	# Calm, slightly darker night behind the title / subtitle.
	shade = glow(h, w, 300 * s, 80 * s, 190 * s) * 0.22
	canvas = canvas * (1 - shade[..., None])
	# Frame of the menu CTA buttons; the night fills the inside of its inner line.
	frame, inside = cta_frame(w, h, s)
	rgb = frame[..., :3] * (1 - inside[..., None]) + np.clip(canvas, 0, 1) * inside[..., None]
	out = np.dstack([rgb, frame[..., 3]])
	Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(BANNER_2026_OUT)
	print("wrote", os.path.relpath(BANNER_2026_OUT, ROOT))


def main() -> None:
	what = sys.argv[1:] or ["pumpkins", "background", "banner"]
	if "pumpkins" in what:
		make_pumpkins()
	if "background" in what:
		make_background()
	if "banner" in what:
		make_banner_2026()


if __name__ == "__main__":
	main()
