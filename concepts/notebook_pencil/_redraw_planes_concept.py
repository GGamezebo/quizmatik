"""Fresh redraw: original silhouettes + concept pencil sticker look (no flame/shadow)."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
ORIG = ROOT / "concepts" / "notebook_pencil" / "_orig_planes"
DST = ROOT / "src" / "features" / "plane"
CONCEPT_DIR = ROOT / "concepts" / "notebook_pencil"
ASSETS = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets")
CONCEPT = ASSETS / (
	"c__Users_Admin_AppData_Roaming_Cursor_User_workspaceStorage_"
	"c8485cde00ab0c3f6d0a538627ccb7be_images_image-4b789cfe-8d7c-4c16-b513-ff9a1e422ca5.png"
)

OUTLINE = 7
CANVAS = (288 + OUTLINE * 2, 108 + OUTLINE * 2)
CREAM = (252, 248, 240, 255)

# Concept palette (sampled feel)
P_TOP = np.array([168, 120, 230], np.float32)
P_MID = np.array([128, 72, 205], np.float32)
P_SIDE = np.array([78, 38, 145], np.float32)
P_DEEP = np.array([48, 24, 95], np.float32)
C_LIGHT = np.array([120, 205, 240], np.float32)
C_MID = np.array([70, 165, 225], np.float32)
C_DEEP = np.array([40, 110, 185], np.float32)
B_MID = np.array([55, 105, 210], np.float32)
B_DEEP = np.array([30, 65, 160], np.float32)
S_LIGHT = np.array([235, 238, 245], np.float32)
S_MID = np.array([185, 190, 205], np.float32)
S_DEEP = np.array([110, 115, 130], np.float32)
INK = np.array([28, 22, 48], np.float32)


def flood_bg(img: Image.Image, tol: int = 48) -> Image.Image:
	rgba = np.array(img.convert("RGBA"))
	h, w = rgba.shape[:2]
	seen = np.zeros((h, w), dtype=bool)
	q: deque[tuple[int, int]] = deque()

	def darkish(y: int, x: int) -> bool:
		return int(rgba[y, x, :3].max()) <= tol + 30

	# paper is light — clear light border + dark shadow blobs from edges
	for x in range(0, w, 2):
		for y in (0, h - 1):
			lum = int(rgba[y, x, :3].mean())
			if lum >= 180 or darkish(y, x):
				q.append((y, x))
				seen[y, x] = True
	for y in range(0, h, 2):
		for x in (0, w - 1):
			if seen[y, x]:
				continue
			lum = int(rgba[y, x, :3].mean())
			if lum >= 180 or darkish(y, x):
				q.append((y, x))
				seen[y, x] = True
	while q:
		y, x = q.popleft()
		rgba[y, x] = 0
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx]:
				lum = int(rgba[ny, nx, :3].mean())
				# grow through paper / soft shadow
				if lum >= 165 or (lum < 100 and rgba[ny, nx, 3] > 0):
					# don't eat into sticker white rim / body — stop on saturated color
					sat = int(rgba[ny, nx, :3].max()) - int(rgba[ny, nx, :3].min())
					if sat < 28 or lum >= 200:
						seen[ny, nx] = True
						q.append((ny, nx))
					elif lum < 90:
						seen[ny, nx] = True
						q.append((ny, nx))
	return Image.fromarray(rgba, "RGBA")


def extract_concept_body(path: Path) -> Image.Image:
	"""Cut concept plane, drop flame + shadow, keep pencil body (+white for strip)."""
	raw = flood_bg(Image.open(path))
	arr = np.array(raw)
	rgb = arr[:, :, :3].astype(np.float32)
	a = arr[:, :, 3]
	lum = rgb.mean(axis=2)
	# soft shadow leftovers
	arr[(a > 0) & (lum < 105) & ((rgb.max(axis=2) - rgb.min(axis=2)) < 40)] = 0
	a = arr[:, :, 3]
	ys, xs = np.where(a > 40)
	if not len(xs):
		raise SystemExit("concept extract failed")
	x0, x1 = int(xs.min()), int(xs.max())
	span = max(1, x1 - x0)
	# kill icy flame on the left ~15%
	xx = np.arange(arr.shape[1])[None, :]
	left = (xx < x0 + span * 0.16) & (a > 0)
	ice = (rgb[:, :, 2] > rgb[:, :, 0] + 18) & (rgb[:, :, 1] > rgb[:, :, 0] - 8) & (rgb[:, :, 2] > 130)
	arr[left & ice] = 0
	# crop tight
	a = arr[:, :, 3]
	ys, xs = np.where(a > 20)
	body = arr[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]
	# strip outer white sticker so we only sample fill
	body = strip_rim(body, depth=14, th=205)
	img = Image.fromarray(body, "RGBA")
	img.save(ASSETS / "concept_body_clean.png")
	return img


def strip_rim(arr: np.ndarray, depth: float = 4.0, th: int = 210) -> np.ndarray:
	alpha = arr[:, :, 3] > 10
	h, w = alpha.shape
	inf = float(h + w + 5)
	dist = np.where(alpha, inf, 0.0).astype(np.float32)
	for y in range(h):
		for x in range(w):
			if not alpha[y, x]:
				continue
			best = dist[y, x]
			if x:
				best = min(best, dist[y, x - 1] + 1)
			if y:
				best = min(best, dist[y - 1, x] + 1)
			dist[y, x] = best
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			if not alpha[y, x]:
				continue
			best = dist[y, x]
			if x + 1 < w:
				best = min(best, dist[y, x + 1] + 1)
			if y + 1 < h:
				best = min(best, dist[y + 1, x] + 1)
			dist[y, x] = best
	rgb = arr[:, :, :3]
	white = (rgb[:, :, 0] >= th) & (rgb[:, :, 1] >= th) & (rgb[:, :, 2] >= th - 15)
	out = arr.copy()
	out[white & (dist <= depth) & alpha] = 0
	return out


def orig_mask(arr: np.ndarray) -> np.ndarray:
	body = strip_rim(arr, depth=3.0, th=208)
	return body[:, :, 3] > 24


def hatch_field(h: int, w: int, seed: int) -> np.ndarray:
	"""Colored-pencil cross-hatch + grain in [-1,1]."""
	rng = np.random.default_rng(seed)
	yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
	h1 = np.sin((xx + yy) * 0.95) * 0.55
	h2 = np.sin((xx - yy * 0.85) * 1.35) * 0.35
	h3 = np.sin(xx * 0.22 + yy * 0.08) * 0.2
	grain = rng.normal(0, 1, (max(1, h // 3), max(1, w // 3))).astype(np.float32)
	grain = np.array(
		Image.fromarray(((grain - grain.min()) / (np.ptp(grain) + 1e-6) * 255).astype(np.uint8), "L").resize(
			(w, h), Image.Resampling.BILINEAR
		)
	).astype(np.float32)
	grain = (grain / 255.0 - 0.5) * 0.45
	return np.clip(h1 + h2 + h3 + grain, -1.0, 1.0)


def classify_and_paint(orig: np.ndarray, mask: np.ndarray, concept: Image.Image, seed: int) -> np.ndarray:
	h, w = mask.shape
	out = np.zeros((h, w, 4), dtype=np.uint8)
	ys, xs = np.where(mask)
	if len(ys) == 0:
		return out
	y0, y1 = int(ys.min()), int(ys.max())
	x0, x1 = int(xs.min()), int(xs.max())
	bh = max(1, y1 - y0)
	bw = max(1, x1 - x0)

	o = orig.astype(np.float32)
	lum = (0.2126 * o[:, :, 0] + 0.7152 * o[:, :, 1] + 0.0722 * o[:, :, 2]) / 255.0
	lum = (
		np.array(
			Image.fromarray((lum * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(0.8))
		).astype(np.float32)
		/ 255.0
	)
	# blue-ish in orig → cyan modules; dark grey → silver/metal; else purple body
	bness = (o[:, :, 2] - o[:, :, 0]) / 255.0
	gness = (o[:, :, 1] - o[:, :, 0]) / 255.0

	# concept texture sample (pose-agnostic UV)
	cst = np.array(concept.convert("RGBA"))
	ca = cst[:, :, 3] > 30
	if ca.any():
		cy, cx = np.where(ca)
		crop = cst[cy.min() : cy.max() + 1, cx.min() : cx.max() + 1]
	else:
		crop = cst
	tex = np.array(Image.fromarray(crop, "RGBA").resize((bw, bh), Image.Resampling.LANCZOS))

	hat = hatch_field(h, w, seed)
	yy, xx = np.where(mask)
	y_rel = (yy - y0) / bh
	x_rel = (xx - x0) / bw
	L = lum[yy, xx]
	bn = bness[yy, xx]
	gn = gness[yy, xx]
	ht = hat[yy, xx]

	# base palette by bands
	cols = np.zeros((len(yy), 3), np.float32)
	# default purple body with top/side shading
	top = y_rel < 0.38
	side = y_rel > 0.62
	mid = ~top & ~side
	t = np.clip((L - 0.15) / 0.7, 0, 1)
	cols[mid] = P_SIDE * (1 - t[mid, None]) + P_TOP * t[mid, None]
	cols[mid] = cols[mid] * 0.35 + P_MID * 0.65
	cols[top] = P_MID * (1 - t[top, None]) + P_TOP * t[top, None]
	cols[side] = P_DEEP * (1 - t[side, None]) + P_SIDE * t[side, None]

	# cyan modules: upper rear block / wing-ish (blue in orig or top-center)
	cyan = ((bn > 0.04) & (L > 0.35)) | ((y_rel < 0.42) & (x_rel > 0.28) & (x_rel < 0.62) & (L > 0.45))
	# also bottom wing protrusion
	cyan |= (y_rel > 0.70) & (x_rel > 0.35) & (x_rel < 0.72) & (L > 0.3)
	tc = np.clip((L[cyan] - 0.25) / 0.55, 0, 1)[:, None]
	cols[cyan] = C_DEEP * (1 - tc) + C_LIGHT * tc
	cols[cyan] = cols[cyan] * 0.4 + C_MID * 0.6

	# deep blue accents
	blue = (bn > 0.08) & (L < 0.45) & (y_rel < 0.55)
	tb = np.clip(L[blue], 0, 1)[:, None]
	cols[blue] = B_DEEP * (1 - tb) + B_MID * tb

	# nose silver (right tip)
	nose = (x_rel > 0.82) | ((x_rel > 0.75) & (L < 0.35))
	# grey mechanical underbelly near rear
	metal = ((L < 0.28) & (x_rel < 0.35) & (y_rel > 0.55)) | ((x_rel > 0.88) & (L < 0.55))
	metal |= nose
	tm = np.clip((L[metal] - 0.1) / 0.6, 0, 1)[:, None]
	cols[metal] = S_DEEP * (1 - tm) + S_LIGHT * tm
	cols[metal] = cols[metal] * 0.45 + S_MID * 0.55

	# blend concept texture color (60%) for authentic pencil grain
	ly = np.clip(yy - y0, 0, bh - 1)
	lx = np.clip(xx - x0, 0, bw - 1)
	tr = tex[ly, lx]
	use = tr[:, 3] > 50
	# reject leftover ice from concept rear mapped into body
	ice = use & (tr[:, 2] > tr[:, 0] + 35) & (tr[:, 1] > tr[:, 0] + 5) & (x_rel < 0.12)
	use = use & ~ice
	cols[use] = cols[use] * 0.28 + tr[use, :3].astype(np.float32) * 0.72

	# hatching modulation
	cols *= 0.88 + 0.14 * (0.5 + 0.5 * ht)[:, None]
	# slight edge darkening near silhouette
	edge = np.array(
		Image.fromarray((mask.astype(np.uint8) * 255), "L")
		.filter(ImageFilter.MaxFilter(3))
		.point(lambda v: 255 if v > 0 else 0)
	)
	erode = np.array(
		Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.MinFilter(3))
	)
	ring = (edge > 0) & (erode < 128) & mask
	cols[ring[yy, xx]] *= 0.82

	out[yy, xx, :3] = np.clip(cols, 0, 255).astype(np.uint8)
	out[yy, xx, 3] = 255

	# ink facet lines from original gradients
	out = ink_facets(out, mask, lum, seed)
	return out


def ink_facets(rgba: np.ndarray, mask: np.ndarray, lum: np.ndarray, seed: int) -> np.ndarray:
	h, w = mask.shape
	# sobel-ish
	gx = np.zeros_like(lum)
	gy = np.zeros_like(lum)
	gx[:, 1:-1] = lum[:, 2:] - lum[:, :-2]
	gy[1:-1, :] = lum[2:, :] - lum[:-2, :]
	mag = np.sqrt(gx * gx + gy * gy)
	mag = mag / (mag.max() + 1e-6)
	edge = (mag > 0.12) & mask
	# thin
	edge_img = Image.fromarray((edge.astype(np.uint8) * 255), "L").filter(ImageFilter.MinFilter(3))
	edge = np.array(edge_img) > 128
	# wobble: keep ~70% of edge pixels
	rng = np.random.default_rng(seed + 9)
	keep = rng.random((h, w)) > 0.22
	edge &= keep
	out = rgba.copy()
	ys, xs = np.where(edge)
	out[ys, xs, :3] = (out[ys, xs, :3].astype(np.float32) * 0.25 + INK * 0.75).clip(0, 255)
	# outer body ink ring (thin)
	dil = np.array(Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.MaxFilter(3))) > 0
	ero = np.array(Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.MinFilter(3))) > 0
	ring = dil & ~ero & mask
	ys, xs = np.where(ring)
	out[ys, xs, :3] = (out[ys, xs, :3].astype(np.float32) * 0.35 + INK * 0.65).clip(0, 255)
	return out


def add_sticker_outline(body: Image.Image, radius: int = OUTLINE) -> Image.Image:
	scale = 2
	rad = radius * scale
	# crisp body at 2x
	hi = body.resize((body.size[0] * scale, body.size[1] * scale), Image.Resampling.NEAREST)
	pad = rad + 6
	base = Image.new("RGBA", (hi.size[0] + pad * 2, hi.size[1] + pad * 2), (0, 0, 0, 0))
	base.paste(hi, (pad, pad), hi)
	alpha = base.getchannel("A")
	# smooth outer field
	field = alpha.filter(ImageFilter.GaussianBlur(radius=rad * 0.72))
	f = np.array(field)
	body_a = np.array(alpha) > 40
	outer = f >= 58
	# round corners a bit more
	outer = np.array(
		Image.fromarray((outer.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(0.9))
	) >= 128
	canvas = np.zeros((base.size[1], base.size[0], 4), dtype=np.uint8)
	rim = outer & ~body_a
	canvas[rim] = CREAM
	sticker = Image.alpha_composite(Image.fromarray(canvas, "RGBA"), base)
	bb = sticker.getbbox()
	sprite = sticker.crop(bb)
	sprite = sprite.resize(
		(max(1, sprite.size[0] // scale), max(1, sprite.size[1] // scale)),
		Image.Resampling.LANCZOS,
	)
	return harden(sprite)


def harden(sprite: Image.Image) -> Image.Image:
	arr = np.array(sprite.convert("RGBA"))
	rgb = arr[:, :, :3].astype(np.int16)
	a = arr[:, :, 3]
	creamish = (rgb[:, :, 0] >= 225) & (rgb[:, :, 1] >= 215) & (rgb[:, :, 2] >= 195)
	body = (a >= 200) & ~creamish
	# kill gray halo
	soft = (a > 0) & (a < 245) & ~creamish & ~body
	arr[soft] = 0
	cs = creamish & (a > 0) & (a < 250) & ~body
	keep = a[cs] >= 100
	arr[cs] = 0
	ys, xs = np.where(cs)
	arr[ys[keep], xs[keep]] = CREAM
	return Image.fromarray(arr, "RGBA")


def process(name: str, concept: Image.Image, seed: int) -> None:
	orig = np.array(Image.open(ORIG / name).convert("RGBA"))
	mask = orig_mask(orig)
	colored = classify_and_paint(orig, mask, concept, seed)
	# slight AA on body edge
	mask_aa = Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(0.4))
	body = Image.new("RGBA", (288, 108), (0, 0, 0, 0))
	rgb = Image.fromarray(colored, "RGBA").convert("RGB")
	rgb = ImageEnhance.Color(rgb).enhance(1.22)
	rgb = ImageEnhance.Contrast(rgb).enhance(1.12)
	body.paste(rgb, mask=mask_aa)

	sprite = add_sticker_outline(body, OUTLINE)
	out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	sw, sh = sprite.size
	cw, ch = CANVAS
	if sw > cw or sh > ch:
		s = min(cw / sw, ch / sh)
		sprite = sprite.resize((max(1, int(sw * s)), max(1, int(sh * s))), Image.Resampling.LANCZOS)
	out.alpha_composite(sprite, ((cw - sprite.size[0]) // 2, (ch - sprite.size[1]) // 2))
	out.save(DST / name, optimize=True)
	out.save(CONCEPT_DIR / f"sticker_{name}", optimize=True)
	print("saved", name, out.size, out.getchannel("A").getbbox())


def main() -> None:
	concept = extract_concept_body(CONCEPT)
	for i, name in enumerate(["Plane.png", "PlaneUp.png", "PlaneDown.png"]):
		process(name, concept, seed=40 + i * 17)
	# preview sheet
	imgs = [Image.open(DST / n).convert("RGBA") for n in ["Plane.png", "PlaneUp.png", "PlaneDown.png"]]
	W = sum(i.size[0] for i in imgs) + 40
	H = max(i.size[1] for i in imgs) + 20
	sheet = Image.new("RGBA", (W, H), (28, 28, 32, 255))
	x = 10
	for im in imgs:
		sheet.alpha_composite(im, (x, 10))
		x += im.size[0] + 10
	sheet.save(ASSETS / "planes_redraw_check.png")
	print("preview", ASSETS / "planes_redraw_check.png")


if __name__ == "__main__":
	main()
