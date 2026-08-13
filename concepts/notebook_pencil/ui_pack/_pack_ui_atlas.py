"""Slice generated notebook UI sheets into RGBA sprites and pack a master atlas."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
SHEETS = ROOT / "sheets"
SLICES = ROOT / "slices"
DEBUG = ROOT / "_debug"

BLACK_HARD = 28
BLACK_SOFT = 52
TRIM_PAD = 8
# Matches `src/ui/hud/btn_restart.png` transparent margin so sticker_drop_shadow
# (offset 10 + blur 2) is not clipped. Same gutter on X and Y.
BUTTON_SHADOW_PAD = 20
ATLAS_PAD = 16
CLUSTER_NAMES = {
	"stamp_empty",
	"lane_dash",
	"icon_stars",
	"doodle_stars",
}
ATLAS_WIDTH = 2048

SHEET_LAYOUTS: list[tuple[str, int, int, list[str]]] = [
	(
		"ui_pack_buttons.png",
		4,
		4,
		[
			"btn_sound_on",
			"btn_sound_off",
			"btn_movement_direct",
			"btn_movement_discrete",
			"btn_restart",
			"btn_exit",
			"btn_back",
			"btn_next",
			"btn_play",
			"btn_pause",
			"btn_settings",
			"btn_home",
			"btn_check",
			"btn_lock",
			"btn_menu",
			"btn_blank",
		],
	),
	(
		"ui_pack_frames.png",
		2,
		3,
		[
			"panel_card",
			"banner_question",
			"chip_score",
			"panel_scalloped",
			"btn_wide",
			"note_folded",
		],
	),
	(
		"ui_pack_stamps_icons.png",
		3,
		4,
		[
			"stamp_sun",
			"stamp_flower",
			"stamp_cat",
			"stamp_empty",
			"heart",
			"heart_empty",
			"icon_paperclip",
			"icon_stars",
			"well_circle",
			"checkbox",
			"checkbox_checked",
			"lane_dash",
		],
	),
	(
		"ui_pack_decor.png",
		3,
		4,
		[
			"doodle_sun",
			"doodle_clouds",
			"doodle_globe",
			"doodle_books",
			"doodle_pencil",
			"doodle_tree",
			"doodle_school",
			"doodle_flower",
			"notebook_holes",
			"doodle_stars",
			"doodle_airplane",
			"doodle_paperclip",
		],
	),
	(
		"ui_pack_controls.png",
		2,
		4,
		[
			"toggle_off",
			"toggle_on",
			"bar_empty",
			"bar_fill",
			"speech_bubble",
			"star_pin",
			"slider",
			"tab",
		],
	),
]


def chroma_black(img: Image.Image) -> Image.Image:
	rgba = img.convert("RGBA")
	px = rgba.load()
	w, h = rgba.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			mx = max(r, g, b)
			if mx <= BLACK_HARD:
				px[x, y] = (0, 0, 0, 0)
			elif mx <= BLACK_SOFT:
				fade = int((mx - BLACK_HARD) / float(BLACK_SOFT - BLACK_HARD) * 255)
				px[x, y] = (r, g, b, min(a, fade))
	return rgba


def alpha_bbox(img: Image.Image, alpha_min: int = 24) -> tuple[int, int, int, int] | None:
	px = img.load()
	w, h = img.size
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


def find_components(img: Image.Image, alpha_min: int = 24) -> list[tuple[int, int, int, int, int, float, float]]:
	"""Return (area, x0, y0, x1, y1, cx, cy) for each opaque blob."""
	px = img.load()
	w, h = img.size
	visited = [[False] * w for _ in range(h)]
	comps: list[tuple[int, int, int, int, int, float, float]] = []
	for y in range(h):
		for x in range(w):
			if visited[y][x] or px[x, y][3] < alpha_min:
				continue
			stack = [(x, y)]
			visited[y][x] = True
			min_x = max_x = x
			min_y = max_y = y
			sx = sy = 0
			count = 0
			while stack:
				cx, cy = stack.pop()
				count += 1
				sx += cx
				sy += cy
				min_x = min(min_x, cx)
				max_x = max(max_x, cx)
				min_y = min(min_y, cy)
				max_y = max(max_y, cy)
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and px[nx, ny][3] >= alpha_min:
						visited[ny][nx] = True
						stack.append((nx, ny))
			if count < 40:
				continue
			comps.append((count, min_x, min_y, max_x + 1, max_y + 1, sx / count, sy / count))
	return comps


def isolate_main(img: Image.Image, cluster: bool) -> Image.Image:
	"""Drop neighbor slivers. `cluster` keeps nearby dashed/star groups."""
	comps = find_components(img)
	if not comps:
		return img
	w, h = img.size
	if cluster:
		tot = sum(c[0] for c in comps)
		pcx = sum(c[0] * c[5] for c in comps) / tot
		pcy = sum(c[0] * c[6] for c in comps) / tot
		radius = 0.50 * min(w, h)
	else:
		primary = max(comps, key=lambda c: c[0])
		pcx, pcy = primary[5], primary[6]
		radius = 0.08 * min(w, h)
	px = img.load()
	mask = [[False] * w for _ in range(h)]
	visited = [[False] * w for _ in range(h)]
	alpha_min = 24
	for y in range(h):
		for x in range(w):
			if visited[y][x] or px[x, y][3] < alpha_min:
				visited[y][x] = True
				continue
			stack = [(x, y)]
			visited[y][x] = True
			pixels: list[tuple[int, int]] = []
			sx = sy = 0
			while stack:
				cx, cy = stack.pop()
				pixels.append((cx, cy))
				sx += cx
				sy += cy
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and px[nx, ny][3] >= alpha_min:
						visited[ny][nx] = True
						stack.append((nx, ny))
			n = len(pixels)
			if n < 40:
				continue
			cxm, cym = sx / n, sy / n
			if cluster:
				keep_blob = (cxm - pcx) ** 2 + (cym - pcy) ** 2 <= radius * radius
			else:
				keep_blob = n >= int(0.92 * max(c[0] for c in comps))
			if keep_blob:
				for mx, my in pixels:
					mask[my][mx] = True
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	opx = out.load()
	for y in range(h):
		for x in range(w):
			if mask[y][x]:
				opx[x, y] = px[x, y]
	return out


def trim(img: Image.Image, pad: int = TRIM_PAD) -> Image.Image:
	box = alpha_bbox(img)
	if box is None:
		return img
	x0, y0, x1, y1 = box
	x0 = max(0, x0 - pad)
	y0 = max(0, y0 - pad)
	x1 = min(img.size[0], x1 + pad)
	y1 = min(img.size[1], y1 + pad)
	return img.crop((x0, y0, x1, y1))


def add_margin(img: Image.Image, pad: int) -> Image.Image:
	out = Image.new("RGBA", (img.size[0] + pad * 2, img.size[1] + pad * 2), (0, 0, 0, 0))
	out.paste(img, (pad, pad), img)
	return out


def opaque_bbox(img: Image.Image, alpha_min: int = 24) -> tuple[int, int, int, int] | None:
	return alpha_bbox(img, alpha_min)


def chroma_black_and_red(img: Image.Image) -> Image.Image:
	rgba = img.convert("RGBA")
	px = rgba.load()
	w, h = rgba.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if r > 200 and g < 110 and b < 110:
				px[x, y] = (0, 0, 0, 0)
			else:
				mx = max(r, g, b)
				if mx <= BLACK_HARD:
					px[x, y] = (0, 0, 0, 0)
				elif mx <= BLACK_SOFT:
					fade = int((mx - BLACK_HARD) / float(BLACK_SOFT - BLACK_HARD) * 255)
					px[x, y] = (r, g, b, min(a, fade))
	return rgba


def _is_red(p: tuple[int, ...]) -> bool:
	return p[0] > 200 and p[1] < 110 and p[2] < 110


def extract_buttons_from_debug() -> list[Image.Image]:
	"""Pull 16 full circles from the original grid shot, merging splits on red cell lines."""
	src = Image.open(DEBUG / "grid_ui_pack_buttons.png").convert("RGB")
	rgb = src.load()
	w, h = src.size

	def is_fg(x: int, y: int) -> bool:
		p = rgb[x, y]
		if max(p) <= BLACK_HARD:
			return False
		if _is_red(p):
			return False
		return True

	def is_bridge(x: int, y: int) -> bool:
		if not _is_red(rgb[x, y]):
			return False
		left = x > 0 and is_fg(x - 1, y)
		right = x < w - 1 and is_fg(x + 1, y)
		up = y > 0 and is_fg(x, y - 1)
		down = y < h - 1 and is_fg(x, y + 1)
		return (left and right) or (up and down)

	visited = [[False] * w for _ in range(h)]
	blobs: list[tuple[int, int, int, int, int, float, float, list[tuple[int, int]]]] = []
	for y in range(h):
		for x in range(w):
			if visited[y][x] or not (is_fg(x, y) or is_bridge(x, y)):
				continue
			stack = [(x, y)]
			visited[y][x] = True
			pixels: list[tuple[int, int]] = []
			min_x = max_x = x
			min_y = max_y = y
			sx = sy = 0
			while stack:
				cx, cy = stack.pop()
				if is_fg(cx, cy):
					pixels.append((cx, cy))
					sx += cx
					sy += cy
					min_x = min(min_x, cx)
					max_x = max(max_x, cx)
					min_y = min(min_y, cy)
					max_y = max(max_y, cy)
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and (is_fg(nx, ny) or is_bridge(nx, ny)):
						visited[ny][nx] = True
						stack.append((nx, ny))
			count = len(pixels)
			if count < 500:
				continue
			blobs.append((count, min_x, min_y, max_x + 1, max_y + 1, sx / count, sy / count, pixels))

	def h_gap(a: tuple, b: tuple) -> int:
		return max(0, b[1] - a[3], a[1] - b[3])

	def y_overlap(a: tuple, b: tuple) -> int:
		return min(a[4], b[4]) - max(a[2], b[2])

	merged = True
	while merged:
		merged = False
		for i in range(len(blobs)):
			for j in range(i + 1, len(blobs)):
				a, b = blobs[i], blobs[j]
				min_h = min(a[4] - a[2], b[4] - b[2])
				if h_gap(a, b) <= 8 and y_overlap(a, b) > min_h * 0.5:
					pixels = a[7] + b[7]
					n = len(pixels)
					x0 = min(a[1], b[1])
					y0 = min(a[2], b[2])
					x1 = max(a[3], b[3])
					y1 = max(a[4], b[4])
					sx = sum(p[0] for p in pixels)
					sy = sum(p[1] for p in pixels)
					blobs[i] = (n, x0, y0, x1, y1, sx / n, sy / n, pixels)
					del blobs[j]
					merged = True
					break
			if merged:
				break

	blobs.sort(key=lambda b: b[0], reverse=True)
	blobs = blobs[:16]
	blobs.sort(key=lambda b: (int(b[6] / (h / 4.0)), b[5]))
	if len(blobs) != 16:
		raise RuntimeError(f"expected 16 buttons, got {len(blobs)}")

	rgba_src = chroma_black_and_red(src)
	out: list[Image.Image] = []
	for count, x0, y0, x1, y1, _cx, _cy, pixels in blobs:
		crop = rgba_src.crop((x0, y0, x1, y1))
		cp = crop.load()
		cw, ch = crop.size
		for py in range(ch):
			x = 0
			while x < cw:
				if cp[x, py][3] > 80:
					x += 1
					continue
				x1 = x
				while x1 < cw and cp[x1, py][3] <= 80:
					x1 += 1
				gap = x1 - x
				if 1 <= gap <= 6 and x > 0 and x1 < cw:
					left = cp[x - 1, py]
					right = cp[x1, py]
					if left[3] > 80 and right[3] > 80:
						for k in range(gap):
							t = (k + 1) / (gap + 1)
							cp[x + k, py] = (
								int(left[0] * (1 - t) + right[0] * t),
								int(left[1] * (1 - t) + right[1] * t),
								int(left[2] * (1 - t) + right[2] * t),
								int(left[3] * (1 - t) + right[3] * t),
							)
				x = max(x1, x + 1)
		print(f"  blob {crop.size} at ({x0},{y0})-({x1},{y1}) n={count}")
		out.append(crop)
	return out


def relayout_buttons_sheet() -> None:
	"""Square 4x4 grid, equal gutters = BUTTON_SHADOW_PAD, transparent background."""
	names = SHEET_LAYOUTS[0][3]
	debug_src = DEBUG / "grid_ui_pack_buttons.png"
	if debug_src.exists() and Image.open(debug_src).size[0] > 1200:
		print("extracting full buttons from original debug sheet")
		crops = extract_buttons_from_debug()
		named_crops = list(zip(names, crops))
	else:
		named_crops = []
		for name in names:
			img = Image.open(SLICES / f"{name}.png").convert("RGBA")
			box = opaque_bbox(img)
			if box is None:
				raise RuntimeError(f"empty slice {name}")
			named_crops.append((name, img.crop(box)))
	max_side = 0
	tight: list[tuple[str, Image.Image]] = []
	for name, crop in named_crops:
		box = opaque_bbox(crop)
		if box is None:
			raise RuntimeError(f"empty crop {name}")
		crop = crop.crop(box)
		max_side = max(max_side, crop.size[0], crop.size[1])
		tight.append((name, crop))
	cell = max_side + BUTTON_SHADOW_PAD * 2
	cols = rows = 4
	atlas = Image.new("RGBA", (cell * cols, cell * rows), (0, 0, 0, 0))
	for i, (name, crop) in enumerate(tight):
		r, c = divmod(i, cols)
		cell_img = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
		x = (cell - crop.size[0]) // 2
		y = (cell - crop.size[1]) // 2
		cell_img.paste(crop, (x, y), crop)
		atlas.paste(cell_img, (c * cell, r * cell), cell_img)
		save(cell_img, SLICES / f"{name}.png")
	save(atlas, SHEETS / "ui_pack_buttons.png")
	print(f"buttons grid cell={cell} pad={BUTTON_SHADOW_PAD} atlas={atlas.size}")


def square_pad(img: Image.Image) -> Image.Image:
	w, h = img.size
	side = max(w, h)
	out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	out.paste(img, ((side - w) // 2, (side - h) // 2), img)
	return out


def slice_sheet(path: Path, rows: int, cols: int, names: list[str], square: bool) -> list[tuple[str, Image.Image]]:
	src = Image.open(path)
	debug = src.convert("RGB").copy()
	draw = ImageDraw.Draw(debug)
	w, h = src.size
	cw, ch = w // cols, h // rows
	out: list[tuple[str, Image.Image]] = []
	for i, name in enumerate(names):
		r, c = divmod(i, cols)
		x0, y0 = c * cw, r * ch
		x1, y1 = x0 + cw, y0 + ch
		draw.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(255, 64, 64))
		cell = chroma_black(src.crop((x0, y0, x1, y1)))
		cell = isolate_main(cell, name in CLUSTER_NAMES)
		cell = trim(cell)
		if square:
			cell = square_pad(cell)
			cell = add_margin(cell, BUTTON_SHADOW_PAD)
		out.append((name, cell))
	DEBUG.mkdir(parents=True, exist_ok=True)
	debug.save(DEBUG / f"grid_{path.stem}.png")
	return out


def pack_atlas(items: list[tuple[str, Image.Image]], width: int = ATLAS_WIDTH) -> Image.Image:
	x = ATLAS_PAD
	y = ATLAS_PAD
	row_h = 0
	placed: list[tuple[int, int, Image.Image]] = []
	for _name, img in items:
		iw, ih = img.size
		if x + iw + ATLAS_PAD > width:
			x = ATLAS_PAD
			y += row_h + ATLAS_PAD
			row_h = 0
		placed.append((x, y, img))
		x += iw + ATLAS_PAD
		row_h = max(row_h, ih)
	height = y + row_h + ATLAS_PAD
	atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
	for px, py, img in placed:
		atlas.paste(img, (px, py), img)
	return atlas


def pack_preview(groups: list[tuple[str, list[tuple[str, Image.Image]]]]) -> Image.Image:
	try:
		font = ImageFont.truetype("arial.ttf", 28)
		small = ImageFont.truetype("arial.ttf", 16)
	except OSError:
		font = ImageFont.load_default()
		small = font
	label_h = 44
	width = ATLAS_WIDTH
	rows: list[tuple[str, int, list[tuple[int, int, Image.Image, str]]]] = []
	total_h = ATLAS_PAD
	for title, items in groups:
		x = ATLAS_PAD
		y = 0
		row_h = 0
		placed: list[tuple[int, int, Image.Image, str]] = []
		for name, img in items:
			thumb = img
			max_side = 220
			tw, th = thumb.size
			scale = min(1.0, max_side / float(max(tw, th)))
			if scale < 1.0:
				thumb = thumb.resize((max(1, int(tw * scale)), max(1, int(th * scale))), Image.Resampling.LANCZOS)
			iw, ih = thumb.size
			need = ih + 18
			if x + iw + ATLAS_PAD > width:
				x = ATLAS_PAD
				y += row_h + ATLAS_PAD
				row_h = 0
			placed.append((x, y, thumb, name))
			x += iw + ATLAS_PAD
			row_h = max(row_h, need)
		block_h = label_h + y + row_h
		rows.append((title, block_h, placed))
		total_h += block_h + ATLAS_PAD
	preview = Image.new("RGBA", (width, total_h + ATLAS_PAD), (18, 16, 14, 255))
	draw = ImageDraw.Draw(preview)
	cy = ATLAS_PAD
	for title, block_h, placed in rows:
		draw.text((ATLAS_PAD, cy), title, fill=(243, 230, 200, 255), font=font)
		base = cy + label_h
		for px, py, img, name in placed:
			preview.paste(img, (px, base + py), img)
			draw.text((px, base + py + img.size[1] + 1), name, fill=(180, 170, 150, 255), font=small)
		cy += block_h + ATLAS_PAD
	return preview


def save(img: Image.Image, path: Path) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	img.save(path, optimize=True)
	print(f"saved {path.relative_to(ROOT)} {img.size}")


def main() -> None:
	SLICES.mkdir(parents=True, exist_ok=True)
	groups: list[tuple[str, list[tuple[str, Image.Image]]]] = []
	all_items: list[tuple[str, Image.Image]] = []
	titles = {
		"ui_pack_buttons.png": "Buttons",
		"ui_pack_frames.png": "Frames",
		"ui_pack_stamps_icons.png": "Stamps & icons",
		"ui_pack_decor.png": "Decor doodles",
		"ui_pack_controls.png": "Controls",
	}
	for filename, rows, cols, names in SHEET_LAYOUTS:
		square = filename == "ui_pack_buttons.png"
		items = slice_sheet(SHEETS / filename, rows, cols, names, square)
		for name, img in items:
			save(img, SLICES / f"{name}.png")
		groups.append((titles[filename], items))
		all_items.extend(items)
	atlas = pack_atlas(all_items)
	save(atlas, ROOT / "ui_atlas_pack.png")
	preview = pack_preview(groups)
	save(preview, ROOT / "ui_atlas_pack_preview.png")
	print(f"slices: {len(all_items)}")


if __name__ == "__main__":
	import sys

	if len(sys.argv) > 1 and sys.argv[1] == "buttons":
		relayout_buttons_sheet()
	else:
		main()
