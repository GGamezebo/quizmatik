"""Restyle flame.png: transparent bg, pencil fill, cream sticker outline. Keep 300x161 / 100x40 cells."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
SRC = Path(
	r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\flame_orig_git.png"
)
DST = ROOT / "src" / "features" / "plane" / "flame.png"
CONCEPT = ROOT / "concepts" / "notebook_pencil" / "flame_pencil.png"

COLS, ROWS = 3, 4
CELL_W, CELL_H = 100, 40
ATLAS_W, ATLAS_H = 300, 161  # keep game atlas size
CREAM = np.array([252, 248, 240, 255], dtype=np.uint8)
OUTLINE = 3

CYAN_L = np.array([170, 230, 255], np.float32)
CYAN = np.array([90, 195, 245], np.float32)
BLUE = np.array([45, 130, 220], np.float32)
BLUE_D = np.array([30, 80, 170], np.float32)
INK = np.array([25, 35, 70], np.float32)


def cell_mask(cell: np.ndarray, tol: int = 38) -> np.ndarray:
	rgb = cell[:, :, :3].astype(np.float32)
	a = cell[:, :, 3] if cell.shape[2] == 4 else np.full(rgb.shape[:2], 255)
	lum = rgb.max(axis=2)
	# flame = bright-ish non-black; keep thin existing rim too
	return (a > 10) & (lum > tol)


def pencilize(mask: np.ndarray, seed: int) -> np.ndarray:
	h, w = mask.shape
	out = np.zeros((h, w, 4), dtype=np.uint8)
	if not mask.any():
		return out
	ys, xs = np.where(mask)
	y0, y1 = int(ys.min()), int(ys.max())
	x0, x1 = int(xs.min()), int(xs.max())
	bh = max(1, y1 - y0)
	bw = max(1, x1 - x0)

	rng = np.random.default_rng(seed)
	yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
	# distance from tip (left = exhaust tip, bright core)
	# actually flame points left in atlas — tip is left, base is right (near plane)
	x_rel = (xx - x0) / bw
	y_rel = (yy - y0) / bh
	# core along center, brighter toward tip (left / small x_rel)
	cy = 0.5
	core = np.exp(-((y_rel - cy) ** 2) / 0.08) * (1.0 - 0.55 * x_rel)
	edge = 1.0 - core

	hatch = (
		np.sin((xx * 0.55 + yy * 1.4)) * 0.22
		+ np.sin((xx * 1.25 - yy * 0.4) + 1.7) * 0.18
		+ np.sin((xx + yy * 0.3) * 0.7) * 0.12
	)
	# soft stroke bands (pencil pressure), not a crisp mesh
	stroke = np.sin(yy * 2.4 + xx * 0.15) * 0.2
	grain = rng.normal(0, 1, (max(1, h // 2), max(1, w // 2))).astype(np.float32)
	grain = np.array(
		Image.fromarray(((grain - grain.min()) / (np.ptp(grain) + 1e-6) * 255).astype(np.uint8), "L")
		.resize((w, h), Image.Resampling.BILINEAR)
		.filter(ImageFilter.GaussianBlur(0.4))
	).astype(np.float32)
	grain = (grain / 255.0 - 0.5) * 0.28
	tex = np.clip(0.62 + 0.18 * hatch + 0.14 * stroke + grain + 0.18 * core, 0.35, 1.12)

	# palette mix
	t = np.clip(core, 0, 1)[..., None]
	cols = CYAN_L * t + CYAN * (1 - t)
	cols = cols * (1 - 0.55 * edge[..., None]) + BLUE * (0.55 * edge[..., None])
	# outer darken
	cols = cols * (0.75 + 0.35 * tex[..., None])
	# tip brighter cyan
	tip = (x_rel < 0.35) & mask
	cols[tip] = cols[tip] * 0.55 + CYAN_L * 0.45
	# base (near plane, right) deeper blue
	base = (x_rel > 0.7) & mask
	cols[base] = cols[base] * 0.5 + BLUE_D * 0.5

	out[mask, :3] = np.clip(cols[mask], 0, 255).astype(np.uint8)
	out[mask, 3] = 255

	# thin dark inner sketch line on silhouette
	dil = np.array(Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.MaxFilter(3))) > 0
	ero = np.array(Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.MinFilter(3))) > 0
	ring = dil & ~ero & mask
	out[ring, :3] = (out[ring, :3].astype(np.float32) * 0.35 + INK * 0.65).clip(0, 255)
	return out


def add_outline(body: Image.Image, radius: int = OUTLINE) -> Image.Image:
	arr = np.array(body.convert("RGBA"))
	# 2x for smoother rim
	scale = 2
	hi = body.resize((body.size[0] * scale, body.size[1] * scale), Image.Resampling.NEAREST)
	rad = radius * scale
	pad = rad + 4
	base = Image.new("RGBA", (hi.size[0] + pad * 2, hi.size[1] + pad * 2), (0, 0, 0, 0))
	base.paste(hi, (pad, pad), hi)
	alpha = base.getchannel("A")
	field = np.array(alpha.filter(ImageFilter.GaussianBlur(radius=rad * 0.65)))
	body_a = np.array(alpha) > 40
	outer = field >= 55
	outer = np.array(
		Image.fromarray((outer.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(0.8))
	) >= 128
	canvas = np.zeros((base.size[1], base.size[0], 4), dtype=np.uint8)
	canvas[outer & ~body_a] = CREAM
	bl = np.array(base)
	bl[~body_a] = 0
	sticker = Image.alpha_composite(Image.fromarray(canvas, "RGBA"), Image.fromarray(bl, "RGBA"))
	bb = sticker.getbbox()
	sprite = sticker.crop(bb)
	sprite = sprite.resize(
		(max(1, sprite.size[0] // scale), max(1, sprite.size[1] // scale)),
		Image.Resampling.LANCZOS,
	)
	a = np.array(sprite)
	rgb = a[:, :, :3].astype(np.int16)
	aa = a[:, :, 3]
	cream = (aa > 50) & (rgb[:, :, 0] >= 225) & (rgb[:, :, 1] >= 215) & (rgb[:, :, 2] >= 190)
	body_m = (aa >= 180) & ~cream
	soft = (aa > 0) & (aa < 240) & ~cream & ~body_m
	a[soft] = 0
	cs = cream & (aa > 0) & (aa < 250) & ~body_m
	keep = aa[cs] >= 100
	a[cs] = 0
	ys, xs = np.where(cs)
	a[ys[keep], xs[keep]] = CREAM
	return Image.fromarray(a, "RGBA")


def process_cell(cell: Image.Image, seed: int) -> Image.Image:
	arr = np.array(cell.convert("RGBA"))
	mask = cell_mask(arr)
	# slight close to fill holes
	mimg = Image.fromarray((mask.astype(np.uint8) * 255), "L")
	mimg = mimg.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
	mask = np.array(mimg) > 0
	# slight shrink so cream rim fits inside 100x40 cell
	mask = np.array(
		Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.MinFilter(3))
	) > 0

	colored = pencilize(mask, seed)
	body = Image.fromarray(colored, "RGBA")
	body = ImageEnhance.Color(body.convert("RGBA")).enhance(1.2)
	body = ImageEnhance.Contrast(body).enhance(1.08)
	sticker = add_outline(body, OUTLINE)
	out = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
	bb = sticker.getbbox()
	if not bb:
		return out
	sprite = sticker.crop(bb)
	max_w, max_h = CELL_W - 1, CELL_H - 1
	sw, sh = sprite.size
	if sw > max_w or sh > max_h:
		s = min(max_w / sw, max_h / sh)
		sprite = sprite.resize((max(1, int(sw * s)), max(1, int(sh * s))), Image.Resampling.LANCZOS)
	out.alpha_composite(sprite, ((CELL_W - sprite.size[0]) // 2, (CELL_H - sprite.size[1]) // 2))
	return out


def main() -> None:
	src = Image.open(SRC).convert("RGBA")
	# force grid crop even if height 161
	atlas = Image.new("RGBA", (ATLAS_W, ATLAS_H), (0, 0, 0, 0))
	for row in range(ROWS):
		for col in range(COLS):
			x0, y0 = col * CELL_W, row * CELL_H
			# source may be 161 tall — last row slightly short
			y1 = min(src.size[1], y0 + CELL_H)
			x1 = min(src.size[0], x0 + CELL_W)
			cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
			piece = src.crop((x0, y0, x1, y1))
			cell.paste(piece, (0, 0))
			done = process_cell(cell, seed=11 + row * 3 + col)
			atlas.alpha_composite(done, (x0, y0))

	atlas.save(DST, optimize=True)
	atlas.save(CONCEPT, optimize=True)
	print("saved", DST, atlas.size)
	# verify middle column used by game
	for y in (0, 40, 80, 120):
		c = atlas.crop((100, y, 200, y + 40))
		a = np.array(c)[:, :, 3]
		print(f"frame y={y} opaque", int((a > 10).sum()))


if __name__ == "__main__":
	main()
