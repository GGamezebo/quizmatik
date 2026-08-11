"""Import cleaned generated planes: cut black bg, fit canvas, light polish."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
DST = ROOT / "src" / "features" / "plane"
CONCEPT = ROOT / "concepts" / "notebook_pencil"
ASSETS = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets")

CREAM = np.array([252, 248, 240, 255], dtype=np.uint8)
CANVAS = (312, 126)
OUTLINE = 7

SOURCES = {
	"Plane.png": ASSETS / "plane_clean_idle.png",
	"PlaneUp.png": ASSETS / "plane_clean_up.png",
	"PlaneDown.png": ASSETS / "plane_clean_down.png",
}


def cut_black(img: Image.Image, tol: int = 28) -> Image.Image:
	rgba = np.array(img.convert("RGBA"))
	h, w = rgba.shape[:2]
	seen = np.zeros((h, w), dtype=bool)
	q: deque[tuple[int, int]] = deque()

	def dark(y: int, x: int) -> bool:
		return int(rgba[y, x, :3].max()) <= tol

	for x in range(0, w, 2):
		for y in (0, h - 1):
			if dark(y, x):
				q.append((y, x))
				seen[y, x] = True
	for y in range(0, h, 2):
		for x in (0, w - 1):
			if not seen[y, x] and dark(y, x):
				q.append((y, x))
				seen[y, x] = True
	while q:
		y, x = q.popleft()
		rgba[y, x] = 0
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and dark(ny, nx):
				seen[ny, nx] = True
				q.append((ny, nx))
	# also kill leftover near-black
	lum = rgba[:, :, :3].max(axis=2)
	rgba[(lum <= tol) & (rgba[:, :, 3] > 0)] = 0
	return Image.fromarray(rgba, "RGBA")


def largest(mask: np.ndarray) -> np.ndarray:
	h, w = mask.shape
	seen = np.zeros_like(mask, dtype=bool)
	best = None
	best_n = 0
	for y in range(h):
		for x in range(w):
			if not mask[y, x] or seen[y, x]:
				continue
			q = deque([(y, x)])
			seen[y, x] = True
			cells = []
			while q:
				cy, cx = q.popleft()
				cells.append((cy, cx))
				for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
					if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
						seen[ny, nx] = True
						q.append((ny, nx))
			if len(cells) > best_n:
				best_n = len(cells)
				best = cells
	out = np.zeros_like(mask)
	if best:
		for y, x in best:
			out[y, x] = True
	return out


def fill_pale(arr: np.ndarray) -> np.ndarray:
	out = arr.astype(np.float32)
	rgb = out[:, :, :3]
	a = out[:, :, 3]
	cream = (a > 60) & (rgb[:, :, 0] >= 225) & (rgb[:, :, 1] >= 215) & (rgb[:, :, 2] >= 190)
	body = (a > 80) & ~cream
	lum = rgb.mean(axis=2)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	pale = body & (lum >= 185) & (sat <= 50)
	if not pale.any():
		return arr
	src = out.copy()
	src[pale | cream] = 0
	for _ in range(8):
		for c in range(3):
			ch = Image.fromarray(np.clip(src[:, :, c], 0, 255).astype(np.uint8), "L")
			est = np.array(ch.filter(ImageFilter.MaxFilter(3))).astype(np.float32)
			src[pale, c] = np.maximum(src[pale, c], est[pale])
		src[pale, 3] = 255
		still = pale & (src[:, :, :3].mean(axis=2) >= 185)
		if not still.any():
			break
		pale = still
	# stubborn → purple mid
	still = pale & (src[:, :, :3].mean(axis=2) >= 180)
	src[still, :3] = np.array([125, 75, 200], np.float32)
	src[still, 3] = 255
	return np.clip(src, 0, 255).astype(np.uint8)


def smooth_outline(body: Image.Image, radius: int = OUTLINE) -> Image.Image:
	arr = np.array(body.convert("RGBA"))
	rgb = arr[:, :, :3].astype(np.float32)
	a = arr[:, :, 3]
	cream = (a > 60) & (rgb[:, :, 0] >= 225) & (rgb[:, :, 1] >= 215) & (rgb[:, :, 2] >= 190)
	body_m = (a > 80) & ~cream
	# strip old cream, keep body
	arr[cream] = 0
	body_m = (arr[:, :, 3] > 80)

	scale = 2
	bi = Image.fromarray(arr, "RGBA").resize(
		(arr.shape[1] * scale, arr.shape[0] * scale), Image.Resampling.NEAREST
	)
	rad = radius * scale
	pad = rad + 8
	base = Image.new("RGBA", (bi.size[0] + pad * 2, bi.size[1] + pad * 2), (0, 0, 0, 0))
	base.paste(bi, (pad, pad), bi)
	alpha = base.getchannel("A")
	bh = np.array(alpha) > 40
	# smooth silhouette
	sm = Image.fromarray((bh.astype(np.uint8) * 255), "L")
	sm = sm.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
	sm = sm.filter(ImageFilter.GaussianBlur(1.4))
	bh = np.array(sm) >= 128
	field = np.array(
		Image.fromarray((bh.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(rad * 0.68))
	)
	outer = field >= 48
	outer = np.array(
		Image.fromarray((outer.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(1.2))
	) >= 128
	# close micro-nicks
	oi = Image.fromarray((outer.astype(np.uint8) * 255), "L")
	oi = oi.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
	outer = np.array(oi) > 0

	layer = np.zeros((base.size[1], base.size[0], 4), dtype=np.uint8)
	layer[outer & ~bh] = CREAM
	bl = np.array(base)
	bl[~bh] = 0
	sticker = Image.alpha_composite(Image.fromarray(layer, "RGBA"), Image.fromarray(bl, "RGBA"))
	bb = sticker.getbbox()
	sprite = sticker.crop(bb)
	sprite = sprite.resize(
		(max(1, sprite.size[0] // scale), max(1, sprite.size[1] // scale)),
		Image.Resampling.LANCZOS,
	)
	# harden
	a2 = np.array(sprite)
	rgb2 = a2[:, :, :3].astype(np.int16)
	aa = a2[:, :, 3]
	cr = (aa > 60) & (rgb2[:, :, 0] >= 225) & (rgb2[:, :, 1] >= 215) & (rgb2[:, :, 2] >= 190)
	bd = (aa >= 200) & ~cr
	soft = (aa > 0) & (aa < 245) & ~cr & ~bd
	a2[soft] = 0
	cs = cr & (aa > 0) & (aa < 250) & ~bd
	keep = aa[cs] >= 110
	a2[cs] = 0
	ys, xs = np.where(cs)
	a2[ys[keep], xs[keep]] = CREAM
	return Image.fromarray(a2, "RGBA")


def process(name: str, path: Path) -> None:
	cut = cut_black(Image.open(path))
	arr = np.array(cut)
	mask = largest(arr[:, :, 3] > 20)
	arr[~mask] = 0
	ys, xs = np.where(mask)
	crop = arr[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]
	crop = fill_pale(crop)
	sprite = smooth_outline(Image.fromarray(crop, "RGBA"), OUTLINE)

	# fit into canvas
	cw, ch = CANVAS
	sw, sh = sprite.size
	s = min((cw - 4) / sw, (ch - 4) / sh)
	sprite = sprite.resize((max(1, int(sw * s)), max(1, int(sh * s))), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	out.alpha_composite(sprite, ((cw - sprite.size[0]) // 2, (ch - sprite.size[1]) // 2))
	out.save(DST / name, optimize=True)
	out.save(CONCEPT / f"sticker_{name}", optimize=True)
	print("saved", name, out.size, out.getchannel("A").getbbox())


def main() -> None:
	for name, path in SOURCES.items():
		process(name, path)
	imgs = [Image.open(DST / n).convert("RGBA") for n in SOURCES]
	W = sum(i.size[0] for i in imgs) + 40
	H = max(i.size[1] for i in imgs) + 20
	sheet = Image.new("RGBA", (W, H), (28, 28, 32, 255))
	x = 10
	for im in imgs:
		sheet.alpha_composite(im, (x, (H - im.size[1]) // 2))
		x += im.size[0] + 10
	sheet.save(ASSETS / "planes_cleaned_sheet.png")
	print("preview ok")


if __name__ == "__main__":
	main()
