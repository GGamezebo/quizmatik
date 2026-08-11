"""Clean plane stickers: fill scuffs/holes, smooth jagged outline nicks."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
DST = ROOT / "src" / "features" / "plane"
CONCEPT = ROOT / "concepts" / "notebook_pencil"
ASSETS = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets")

CREAM = np.array([252, 248, 240, 255], dtype=np.uint8)
OUTLINE = 7


def is_cream(rgb: np.ndarray, a: np.ndarray) -> np.ndarray:
	return (a > 60) & (rgb[:, :, 0] >= 225) & (rgb[:, :, 1] >= 215) & (rgb[:, :, 2] >= 190)


def is_scuff(rgb: np.ndarray, a: np.ndarray, cream: np.ndarray) -> np.ndarray:
	"""White / paper-show-through patches inside drawing (not intentional silver)."""
	lum = rgb.mean(axis=2)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	# pale holes
	pale = (a > 40) & ~cream & (lum >= 188) & (sat <= 55)
	# chalky light streaks (high lum, weak chroma)
	chalk = (a > 40) & ~cream & (lum >= 175) & (sat <= 35)
	return pale | chalk


def dilate(mask: np.ndarray, k: int = 3) -> np.ndarray:
	img = Image.fromarray((mask.astype(np.uint8) * 255), "L")
	for _ in range(max(1, k // 2)):
		img = img.filter(ImageFilter.MaxFilter(3))
	return np.array(img) > 0


def erode(mask: np.ndarray, k: int = 3) -> np.ndarray:
	img = Image.fromarray((mask.astype(np.uint8) * 255), "L")
	for _ in range(max(1, k // 2)):
		img = img.filter(ImageFilter.MinFilter(3))
	return np.array(img) > 0


def close_mask(mask: np.ndarray, rounds: int = 2) -> np.ndarray:
	m = mask.copy()
	for _ in range(rounds):
		m = dilate(m, 3)
		m = erode(m, 3)
	return m


def open_mask(mask: np.ndarray, rounds: int = 1) -> np.ndarray:
	m = mask.copy()
	for _ in range(rounds):
		m = erode(m, 3)
		m = dilate(m, 3)
	return m


def fill_scuffs(arr: np.ndarray) -> np.ndarray:
	out = arr.copy().astype(np.float32)
	rgb = out[:, :, :3]
	a = out[:, :, 3]
	cream = is_cream(rgb, a)
	body = (a > 80) & ~cream
	scuff = is_scuff(rgb, a, cream) & (dilate(body, 5) | body)

	# keep intentional silver nose: rightmost ~12% AND grey (low sat) AND not huge blotches
	ys, xs = np.where(body | scuff)
	if len(xs) == 0:
		return arr
	x0, x1 = int(xs.min()), int(xs.max())
	span = max(1, x1 - x0)
	nose_zone = np.arange(arr.shape[1])[None, :] > (x0 + span * 0.86)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	lum = rgb.mean(axis=2)
	# small silver tip: grey, mid-lum, in nose — don't fill those
	silver = nose_zone & (sat < 45) & (lum > 140) & (lum < 230) & (a > 80)
	# only keep compact silver (erode a bit)
	silver = erode(silver, 1) 
	silver = dilate(silver, 2)
	scuff = scuff & ~silver

	# neighbor color: blur body colors excluding scuffs
	src = out.copy()
	src[scuff | cream] = 0
	# iterative pull from neighbors
	mask_good = (src[:, :, 3] > 80) & ~cream
	for _ in range(10):
		if not scuff.any():
			break
		for c in range(3):
			ch = Image.fromarray(np.clip(src[:, :, c], 0, 255).astype(np.uint8), "L")
			# replace zeros with blur of good pixels — use max-ish neighborhood
			blurred = np.array(ch.filter(ImageFilter.BoxBlur(2))).astype(np.float32)
			# also median-like via min/max mix
			mx = np.array(ch.filter(ImageFilter.MaxFilter(3))).astype(np.float32)
			mn = np.array(ch.filter(ImageFilter.MinFilter(3))).astype(np.float32)
			est = blurred * 0.5 + ((mx + mn) * 0.5) * 0.5
			src[scuff, c] = est[scuff]
		src[scuff, 3] = 255
		# remaining scuffs: still too pale?
		still = is_scuff(src[:, :, :3], src[:, :, 3], cream) & scuff & ~silver
		# force tint from local purple/blue mean of nearby good
		if still.any():
			# sample mean of good body
			good = mask_good
			if good.any():
				mean_col = src[good, :3].mean(axis=0)
				# darker fill for stubborn holes
				src[still, :3] = mean_col * 0.85 + np.array([110, 70, 190]) * 0.15
				src[still, 3] = 255
		scuff = still

	# light smooth inside body only (kill remaining grit)
	body2 = (src[:, :, 3] > 80) & ~is_cream(src[:, :, :3], src[:, :, 3])
	for c in range(3):
		ch = Image.fromarray(np.clip(src[:, :, c], 0, 255).astype(np.uint8), "L")
		sm = np.array(ch.filter(ImageFilter.GaussianBlur(0.55))).astype(np.float32)
		src[body2, c] = src[body2, c] * 0.55 + sm[body2] * 0.45

	# restore silver tip untouched from original if present
	if silver.any():
		src[silver] = arr[silver].astype(np.float32)

	src[~body2 & ~is_cream(src[:, :, :3], src[:, :, 3]) & ~(src[:, :, 3] > 0), 3] = 0
	# clear old cream — rebuild later
	cream2 = is_cream(src[:, :, :3], src[:, :, 3])
	src[cream2] = 0
	return np.clip(src, 0, 255).astype(np.uint8)


def smooth_body_mask(body: np.ndarray) -> np.ndarray:
	"""Remove outline nicks: close holes, open tiny spikes."""
	m = close_mask(body, rounds=2)
	m = open_mask(m, rounds=1)
	# slight extra close for silhouette smoothness
	m = dilate(m, 3)
	m = erode(m, 3)
	return m


def rebuild_outline(body_rgba: np.ndarray, radius: int = OUTLINE) -> Image.Image:
	rgb = body_rgba[:, :, :3]
	a = body_rgba[:, :, 3]
	body = (a > 80) & ~is_cream(rgb, a)
	body = smooth_body_mask(body)

	# paste body colors onto smoothed mask (fill new edge pixels from nearest)
	h, w = body.shape
	canvas = np.zeros((h, w, 4), dtype=np.float32)
	canvas[body, :3] = body_rgba[body, :3]
	canvas[body, 3] = 255
	# fill any mask pixels that were empty in source
	need = body & (body_rgba[:, :, 3] < 80)
	if need.any():
		src = body_rgba.copy().astype(np.float32)
		src[~((body_rgba[:, :, 3] > 80) & ~is_cream(body_rgba[:, :, :3], body_rgba[:, :, 3]))] = 0
		for _ in range(6):
			for c in range(3):
				ch = Image.fromarray(np.clip(src[:, :, c], 0, 255).astype(np.uint8), "L")
				est = np.array(ch.filter(ImageFilter.MaxFilter(3))).astype(np.float32)
				src[need, c] = np.maximum(src[need, c], est[need])
			src[need, 3] = 255
		canvas[need] = src[need]

	# hi-res smooth outline
	scale = 2
	body_img = Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8), "RGBA")
	hi = body_img.resize((w * scale, h * scale), Image.Resampling.NEAREST)
	rad = radius * scale
	pad = rad + 8
	base = Image.new("RGBA", (hi.size[0] + pad * 2, hi.size[1] + pad * 2), (0, 0, 0, 0))
	base.paste(hi, (pad, pad), hi)
	alpha = base.getchannel("A")
	# smooth silhouette before dilate
	a_np = np.array(alpha)
	body_hi = a_np > 40
	# morphological smooth at hi-res
	bh = Image.fromarray((body_hi.astype(np.uint8) * 255), "L")
	bh = bh.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
	bh = bh.filter(ImageFilter.GaussianBlur(1.2))
	body_hi = np.array(bh) >= 128
	field = np.array(
		Image.fromarray((body_hi.astype(np.uint8) * 255), "L").filter(
			ImageFilter.GaussianBlur(radius=rad * 0.7)
		)
	)
	outer = field >= 50
	# round outer edge
	outer = np.array(
		Image.fromarray((outer.astype(np.uint8) * 255), "L").filter(ImageFilter.GaussianBlur(1.1))
	) >= 128
	# remove micro-nicks on outer with close
	outer = close_mask(outer, rounds=1)

	rim = outer & ~body_hi
	layer = np.zeros((base.size[1], base.size[0], 4), dtype=np.uint8)
	layer[rim] = CREAM
	# body layer from smoothed mask + colors
	body_layer = np.array(base)
	body_layer[~body_hi] = 0
	sticker = Image.alpha_composite(Image.fromarray(layer, "RGBA"), Image.fromarray(body_layer, "RGBA"))
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
	cream = is_cream(rgb.astype(np.float32), a.astype(np.float32))
	body = (a >= 200) & ~cream
	soft = (a > 0) & (a < 245) & ~cream & ~body
	arr[soft] = 0
	cs = cream & (a > 0) & (a < 250) & ~body
	keep = a[cs] >= 110
	arr[cs] = 0
	ys, xs = np.where(cs)
	arr[ys[keep], xs[keep]] = CREAM
	return Image.fromarray(arr, "RGBA")


def process(name: str) -> None:
	src = Image.open(DST / name).convert("RGBA")
	filled = fill_scuffs(np.array(src))
	# also reduce extreme chalky patches after fill
	rgb = filled[:, :, :3].astype(np.float32)
	a = filled[:, :, 3]
	cream = is_cream(rgb, a)
	body = (a > 80) & ~cream
	lum = rgb.mean(axis=2)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	# darken leftover pale scuffs toward local color
	pale = body & (lum > 170) & (sat < 70)
	if pale.any():
		# pull toward purple/blue mid
		target = rgb.copy()
		for c in range(3):
			ch = Image.fromarray(rgb[:, :, c].astype(np.uint8), "L").filter(ImageFilter.BoxBlur(3))
			target[:, :, c] = np.array(ch)
		rgb[pale] = rgb[pale] * 0.35 + target[pale] * 0.65
		filled[:, :, :3] = np.clip(rgb, 0, 255)

	sprite = rebuild_outline(filled, OUTLINE)
	# fit back to original canvas size, centered
	cw, ch = src.size
	out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
	sw, sh = sprite.size
	if sw > cw or sh > ch:
		s = min(cw / sw, ch / sh) * 0.98
		sprite = sprite.resize((max(1, int(sw * s)), max(1, int(sh * s))), Image.Resampling.LANCZOS)
	out.alpha_composite(sprite, ((cw - sprite.size[0]) // 2, (ch - sprite.size[1]) // 2))
	out.save(DST / name, optimize=True)
	out.save(CONCEPT / f"sticker_{name}", optimize=True)
	# stats
	a2 = np.array(out)
	c2 = is_cream(a2[:, :, :3].astype(np.float32), a2[:, :, 3].astype(np.float32))
	holes = is_scuff(a2[:, :, :3].astype(np.float32), a2[:, :, 3].astype(np.float32), c2)
	print(name, "scuff_left", int(holes.sum()), "size", out.size)


def main() -> None:
	for name in ["Plane.png", "PlaneUp.png", "PlaneDown.png"]:
		process(name)
	imgs = [Image.open(DST / n).convert("RGBA") for n in ["Plane.png", "PlaneUp.png", "PlaneDown.png"]]
	W = sum(i.size[0] for i in imgs) + 40
	H = max(i.size[1] for i in imgs) + 20
	sheet = Image.new("RGBA", (W, H), (28, 28, 32, 255))
	x = 10
	for im in imgs:
		sheet.alpha_composite(im, (x, (H - im.size[1]) // 2))
		x += im.size[0] + 10
	sheet.save(ASSETS / "planes_cleaned_sheet.png")
	print("preview", ASSETS / "planes_cleaned_sheet.png")


if __name__ == "__main__":
	main()
