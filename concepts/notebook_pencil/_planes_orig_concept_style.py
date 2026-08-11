"""Exact original silhouettes + concept pencil fill + clean sticker outline (no flame/shadow)."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
ORIG = ROOT / "concepts" / "notebook_pencil" / "_orig_planes"
DST = ROOT / "src" / "features" / "plane"
CONCEPT = ROOT / "concepts" / "notebook_pencil"
SHEET = Path(
	r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\planes_origshape_concept_style.png"
)
STYLE_REF = Path(
	r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets"
	r"\c__Users_Admin_AppData_Roaming_Cursor_User_workspaceStorage_"
	r"c8485cde00ab0c3f6d0a538627ccb7be_images_image-8825861e-ae53-469c-b387-e76523d97d53.png"
)

OUTLINE_PX = 7
CANVAS = (288 + OUTLINE_PX * 2, 108 + OUTLINE_PX * 2)
CREAM = np.array([252, 248, 240, 255], dtype=np.uint8)

# Concept palette fallbacks
PURPLE = np.array([130, 75, 210], np.float32)
PURPLE_D = np.array([75, 40, 135], np.float32)
PURPLE_L = np.array([175, 125, 235], np.float32)
CYAN = np.array([90, 185, 230], np.float32)
CYAN_D = np.array([55, 140, 195], np.float32)
BLUE = np.array([55, 115, 215], np.float32)
BLUE_D = np.array([35, 75, 165], np.float32)
SILV = np.array([220, 224, 232], np.float32)
SILV_D = np.array([140, 145, 158], np.float32)


def flood_clear(img: Image.Image, tol: int = 42) -> Image.Image:
	rgba = np.array(img.convert("RGBA"))
	h, w = rgba.shape[:2]
	seen = np.zeros((h, w), dtype=bool)
	q: deque[tuple[int, int]] = deque()
	for x in range(0, w, 3):
		for y in (0, h - 1):
			if int(rgba[y, x, :3].max()) <= tol + 25:
				q.append((y, x))
				seen[y, x] = True
	for y in range(0, h, 3):
		for x in (0, w - 1):
			if not seen[y, x] and int(rgba[y, x, :3].max()) <= tol + 25:
				q.append((y, x))
				seen[y, x] = True
	while q:
		y, x = q.popleft()
		rgba[y, x] = 0
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx]:
				if int(rgba[ny, nx, :3].max()) <= tol + 55:
					seen[ny, nx] = True
					q.append((ny, nx))
	return Image.fromarray(rgba, "RGBA")


def scrub_concept_extras(img: Image.Image) -> Image.Image:
	"""Drop concept flame + soft shadow; keep pencil body (+ white for strip later)."""
	arr = np.array(img.convert("RGBA"))
	rgb = arr[:, :, :3].astype(np.float32)
	a = arr[:, :, 3]
	lum = rgb.mean(axis=2)
	# soft gray drop shadow (graph paper under sticker)
	shadow = (a > 5) & (lum < 110) & (np.max(rgb, axis=2) - np.min(rgb, axis=2) < 35)
	arr[shadow] = 0
	a = arr[:, :, 3]
	ys, xs = np.where(a > 40)
	if len(xs) == 0:
		return Image.fromarray(arr, "RGBA")
	x0, x1 = int(xs.min()), int(xs.max())
	y0, y1 = int(ys.min()), int(ys.max())
	span = max(1, x1 - x0)
	# Aggressive rear cut: leftmost ~12% of content bbox (flame lives there on concept)
	cut_x = x0 + int(span * 0.12)
	rear = (np.arange(arr.shape[1])[None, :] < cut_x) & (a > 0)
	# keep dark nozzle / purple body fragments, kill icy cyan flame
	rgb = arr[:, :, :3].astype(np.float32)
	is_ice = (rgb[:, :, 2] > rgb[:, :, 0] + 15) & (rgb[:, :, 1] > rgb[:, :, 0] - 5) & (rgb[:, :, 2] > 120)
	arr[rear & is_ice] = 0
	# also kill isolated bright cyan anywhere left of 18% 
	cut2 = x0 + int(span * 0.18)
	left = (np.arange(arr.shape[1])[None, :] < cut2) & (a > 0)
	arr[left & is_ice & (rgb[:, :, 2] > 160)] = 0
	return Image.fromarray(arr, "RGBA")


def components(mask: np.ndarray, min_count: int = 800) -> list[tuple[int, int, int, int]]:
	h, w = mask.shape
	seen = np.zeros_like(mask, dtype=bool)
	boxes: list[tuple[int, int, int, int]] = []
	for y in range(h):
		for x in range(w):
			if not mask[y, x] or seen[y, x]:
				continue
			q = deque([(y, x)])
			seen[y, x] = True
			min_x = max_x = x
			min_y = max_y = y
			count = 0
			while q:
				cy, cx = q.popleft()
				count += 1
				min_x = min(min_x, cx)
				max_x = max(max_x, cx)
				min_y = min(min_y, cy)
				max_y = max(max_y, cy)
				for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
					if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
						seen[ny, nx] = True
						q.append((ny, nx))
			if count >= min_count:
				boxes.append((min_x, min_y, max_x + 1, max_y + 1))
	return boxes


def strip_white(arr: np.ndarray, depth: float = 4.0, th: int = 210) -> np.ndarray:
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
	white = (rgb[:, :, 0] >= th) & (rgb[:, :, 1] >= th) & (rgb[:, :, 2] >= th - 12)
	out = arr.copy()
	out[white & (dist <= depth) & alpha] = 0
	return out


def exact_orig_mask(orig: np.ndarray) -> np.ndarray:
	"""Original opaque pixels after removing thin white rim — exact game silhouette."""
	body = strip_white(orig, depth=3.2, th=208)
	return body[:, :, 3] > 20


def sample_style_into_mask(mask: np.ndarray, style: Image.Image, orig: np.ndarray) -> np.ndarray:
	"""Map style texture into original mask via relative UV; fallback palette from orig luminance."""
	h, w = mask.shape
	out = np.zeros((h, w, 4), dtype=np.uint8)
	ys, xs = np.where(mask)
	if len(ys) == 0:
		return out
	y0, y1 = int(ys.min()), int(ys.max())
	x0, x1 = int(xs.min()), int(xs.max())
	bw, bh = x1 - x0 + 1, y1 - y0 + 1

	st = np.array(scrub_concept_extras(style.convert("RGBA")))
	st = strip_white(st, depth=12, th=198)
	# drop leftover rear flame / trail before UV map
	sa0 = st[:, :, 3] > 20
	if sa0.any():
		sy0, sx0 = np.where(sa0)
		x0s, x1s = int(sx0.min()), int(sx0.max())
		span = max(1, x1s - x0s)
		cut = x0s + max(2, int(span * 0.08))
		rgb = st[:, :, :3].astype(np.float32)
		flame = (
			(st[:, :, 3] > 20)
			& (np.arange(st.shape[1])[None, :] < cut)
			& (rgb[:, :, 2] > rgb[:, :, 0] + 18)
			& (rgb[:, :, 1] > rgb[:, :, 0])
			& (rgb[:, :, 2] > 130)
		)
		st[flame] = 0
	sa = st[:, :, 3] > 20
	if not sa.any():
		style_crop = st
	else:
		sy, sx = np.where(sa)
		style_crop = st[sy.min() : sy.max() + 1, sx.min() : sx.max() + 1]
	style_r = np.array(
		Image.fromarray(style_crop, "RGBA").resize((bw, bh), Image.Resampling.LANCZOS)
	)

	# luminance of original for band classification
	o = orig.astype(np.float32)
	lum = (0.2126 * o[:, :, 0] + 0.7152 * o[:, :, 1] + 0.0722 * o[:, :, 2]) / 255.0
	lum_s = (
		np.array(
			Image.fromarray((lum * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.0))
		).astype(np.float32)
		/ 255.0
	)

	yy, xx = np.where(mask)
	ly = yy - y0
	lx = xx - x0
	sr = style_r[ly, lx]
	use = sr[:, 3] > 40

	# start with style colors where available
	out[yy[use], xx[use], :3] = sr[use, :3]
	out[yy[use], xx[use], 3] = 255

	# fill holes / weak style with palette guided by orig bands
	miss = ~use
	if miss.any():
		my, mx = yy[miss], xx[miss]
		y_rel = (my - y0) / max(1, bh - 1)
		x_rel = (mx - x0) / max(1, bw - 1)
		L = lum_s[my, mx]
		cols = np.zeros((len(my), 3), dtype=np.float32)
		# defaults purple
		t = np.clip((L - 0.2) / 0.6, 0, 1)[:, None]
		cols[:] = PURPLE_D * (1 - t) + PURPLE_L * t
		cols = cols * 0.45 + PURPLE * 0.55
		# cyan top
		top = (y_rel < 0.34) & (L > 0.4)
		t2 = np.clip((L[top] - 0.35) / 0.5, 0, 1)[:, None]
		cols[top] = CYAN_D * (1 - t2) + CYAN * t2
		# blue bottom
		bot = y_rel > 0.66
		t3 = np.clip(L[bot], 0, 1)[:, None]
		cols[bot] = BLUE_D * (1 - t3) + BLUE * t3
		# nose silver
		nose = (x_rel > 0.84) & ((L < 0.5) | (L > 0.7))
		t4 = np.clip(L[nose], 0, 1)[:, None]
		cols[nose] = SILV_D * (1 - t4) + SILV * t4
		out[my, mx, :3] = np.clip(cols, 0, 255).astype(np.uint8)
		out[my, mx, 3] = 255

	# mild color smooth inside mask only
	for c in range(3):
		ch = Image.fromarray(out[:, :, c], "L").filter(ImageFilter.GaussianBlur(0.7))
		blurred = np.array(ch)
		out[mask, c] = blurred[mask]

	# subtle low-freq pencil grain (no speckles)
	grain = np.array(
		Image.fromarray(
			np.random.default_rng(4).integers(0, 255, (max(1, h // 5), max(1, w // 5)), dtype=np.uint8),
			"L",
		).resize((w, h), Image.Resampling.BICUBIC)
	).astype(np.float32)
	rgb = out[:, :, :3].astype(np.float32)
	rgb[mask] *= 0.95 + 0.10 * (grain[mask] / 255.0)[:, None]
	out[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
	out[~mask, 3] = 0
	return out


def harden_sticker_edge(sprite: Image.Image) -> Image.Image:
	"""Kill LANCZOS gray fringe / fake drop-shadow outside cream rim."""
	arr = np.array(sprite.convert("RGBA"))
	rgb = arr[:, :, :3].astype(np.int16)
	a = arr[:, :, 3]
	# cream-ish or near-white rim pixels
	creamish = (rgb[:, :, 0] >= 230) & (rgb[:, :, 1] >= 220) & (rgb[:, :, 2] >= 200)
	# body: opaque non-cream
	body = (a >= 200) & ~creamish
	# soft outside pixels that aren't cream → drop (shadow / gray AA)
	soft = (a > 0) & (a < 240) & ~creamish & ~body
	arr[soft] = 0
	# cream fringe: snap to solid cream or clear
	cream_soft = creamish & (a > 0) & (a < 250) & ~body
	keep = a[cream_soft] >= 90
	arr[cream_soft] = 0
	ys, xs = np.where(cream_soft)
	arr[ys[keep], xs[keep]] = CREAM
	return Image.fromarray(arr, "RGBA")


def add_outline_hires(body: Image.Image, radius: int = OUTLINE_PX) -> Image.Image:
	"""Smooth sticker outline at 2x then downscale — no drop shadow."""
	scale = 2
	rad = radius * scale
	body_hi = body.resize((body.size[0] * scale, body.size[1] * scale), Image.Resampling.NEAREST)
	# slight blur only for rim field, keep body crisp via NEAREST then composite original
	pad = rad + 4
	base = Image.new("RGBA", (body_hi.size[0] + pad * 2, body_hi.size[1] + pad * 2), (0, 0, 0, 0))
	base.paste(body_hi, (pad, pad), body_hi)
	alpha = base.getchannel("A")
	field = np.array(alpha.filter(ImageFilter.GaussianBlur(radius=rad * 0.75)))
	body_a = np.array(alpha) > 40
	oi = Image.fromarray(((field >= 55).astype(np.uint8) * 255), "L").filter(
		ImageFilter.GaussianBlur(0.8)
	)
	outer = np.array(oi) >= 128
	canvas = np.zeros((base.size[1], base.size[0], 4), dtype=np.uint8)
	rim = outer & ~body_a
	canvas[rim] = CREAM
	# solid rim only — no semi-transparent fringe (avoids gray halo after downscale)
	sticker = Image.alpha_composite(Image.fromarray(canvas, "RGBA"), base)
	bb = sticker.getbbox()
	sprite = sticker.crop(bb)
	sprite = sprite.resize(
		(max(1, sprite.size[0] // scale), max(1, sprite.size[1] // scale)),
		Image.Resampling.LANCZOS,
	)
	return harden_sticker_edge(sprite)


def clear_rear_flame_in_body(colored: np.ndarray, mask: np.ndarray) -> np.ndarray:
	"""Ensure no icy exhaust remains inside original silhouette."""
	out = colored.copy()
	ys, xs = np.where(mask)
	if len(xs) == 0:
		return out
	x0 = int(xs.min())
	span = max(1, int(xs.max()) - x0)
	cut = x0 + max(3, int(span * 0.07))
	rgb = out[:, :, :3].astype(np.float32)
	zone = mask & (np.arange(out.shape[1])[None, :] < cut)
	ice = zone & (rgb[:, :, 2] > rgb[:, :, 0] + 20) & (rgb[:, :, 1] > rgb[:, :, 0]) & (rgb[:, :, 2] > 140)
	# replace with nearby purple from body
	if ice.any():
		out[ice, 0] = 110
		out[ice, 1] = 65
		out[ice, 2] = 185
		out[ice, 3] = 255
	return out


def process_one(name: str, style_img: Image.Image) -> None:
	orig = np.array(Image.open(ORIG / name).convert("RGBA"))
	mask = exact_orig_mask(orig)
	# Keep exact original opaque footprint — do not smooth away shape details
	colored = clear_rear_flame_in_body(sample_style_into_mask(mask, style_img, orig), mask)
	# AA only on body edge into outline
	mask_aa = Image.fromarray((mask.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(0.45))
	body = Image.new("RGBA", (288, 108), (0, 0, 0, 0))
	rgb = ImageEnhance.Color(Image.fromarray(colored, "RGBA").convert("RGB")).enhance(1.18)
	rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
	body.paste(rgb, mask=mask_aa)

	sprite = add_outline_hires(body, OUTLINE_PX)
	out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	sw, sh = sprite.size
	cw, ch = CANVAS
	if sw > cw or sh > ch:
		s = min(cw / sw, ch / sh)
		sprite = sprite.resize((max(1, int(sw * s)), max(1, int(sh * s))), Image.Resampling.LANCZOS)
	out.alpha_composite(sprite, ((cw - sprite.size[0]) // 2, (ch - sprite.size[1]) // 2))
	out.save(DST / name, optimize=True)
	out.save(CONCEPT / f"sticker_{name}", optimize=True)
	print("saved", name, out.size, out.getchannel("A").getbbox())


def main() -> None:
	# Primary: user concept sticker (pencil fill + rim language). Sheet crops = pose-matched backup.
	style_ref = None
	if STYLE_REF.exists():
		style_ref = scrub_concept_extras(flood_clear(Image.open(STYLE_REF), tol=55))
		style_ref.save(
			Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets")
			/ "style_ref_scrubbed.png",
			optimize=True,
		)
	boxes: list[tuple[int, int, int, int]] = []
	sheet_arr = None
	if SHEET.exists():
		sheet = flood_clear(Image.open(SHEET))
		sheet_arr = np.array(sheet)
		boxes_x = sorted(components(sheet_arr[:, :, 3] > 25), key=lambda b: b[0])
		boxes_y = sorted(components(sheet_arr[:, :, 3] > 25), key=lambda b: b[1])
		if len(boxes_x) >= 3:
			xs = [b[0] for b in boxes_x[:3]]
			ys = [b[1] for b in boxes_y[:3]]
			boxes = boxes_x if (max(xs) - min(xs)) >= (max(ys) - min(ys)) else boxes_y
		print("style components", len(boxes), boxes[:3])

	names = ["Plane.png", "PlaneUp.png", "PlaneDown.png"]
	for i, name in enumerate(names):
		# Always UV-map scrubbed concept fill into exact original silhouette.
		if style_ref is not None:
			style = style_ref
		elif i < len(boxes) and sheet_arr is not None:
			b = boxes[i]
			style = scrub_concept_extras(Image.fromarray(sheet_arr, "RGBA").crop(b))
		else:
			raise SystemExit("no style source")
		process_one(name, style)
	print("done canvas", CANVAS)


if __name__ == "__main__":
	main()
