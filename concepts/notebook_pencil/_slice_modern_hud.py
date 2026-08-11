"""Slice modern notebook HUD atlas + lane strip into game-ready RGBA PNGs."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ATLAS = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\hud_notebook_modern_atlas.png")
LANE = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\lane_dash_strip.png")
CONCEPT_DST = Path(__file__).resolve().parent
GAME_HUD = Path(__file__).resolve().parents[2] / "src" / "ui" / "hud"


def chroma_black(img: Image.Image, threshold: int = 38) -> Image.Image:
	rgba = img.convert("RGBA")
	px = rgba.load()
	w, h = rgba.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if r <= threshold and g <= threshold and b <= threshold:
				px[x, y] = (0, 0, 0, 0)
			elif r < threshold + 40 and g < threshold + 40 and b < threshold + 40:
				fade = int(max(r, g, b) / (threshold + 40) * 255)
				px[x, y] = (r, g, b, min(a, fade))
	return rgba


def find_components(mask: list[list[bool]]) -> list[tuple[int, int, int, int]]:
	h = len(mask)
	w = len(mask[0]) if h else 0
	visited = [[False] * w for _ in range(h)]
	boxes: list[tuple[int, int, int, int]] = []
	for y in range(h):
		for x in range(w):
			if not mask[y][x] or visited[y][x]:
				continue
			stack = [(x, y)]
			visited[y][x] = True
			min_x = max_x = x
			min_y = max_y = y
			count = 0
			while stack:
				cx, cy = stack.pop()
				count += 1
				min_x = min(min_x, cx)
				max_x = max(max_x, cx)
				min_y = min(min_y, cy)
				max_y = max(max_y, cy)
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and mask[ny][nx] and not visited[ny][nx]:
						visited[ny][nx] = True
						stack.append((nx, ny))
			if count < 400:
				continue
			boxes.append((min_x, min_y, max_x + 1, max_y + 1))
	return boxes


def build_mask(img: Image.Image, alpha_min: int = 20) -> list[list[bool]]:
	px = img.load()
	w, h = img.size
	return [[px[x, y][3] >= alpha_min for x in range(w)] for y in range(h)]


def pad_box(box: tuple[int, int, int, int], w: int, h: int, pad: int = 4) -> tuple[int, int, int, int]:
	x0, y0, x1, y1 = box
	return (max(0, x0 - pad), max(0, y0 - pad), min(w, x1 + pad), min(h, y1 + pad))


def save(img: Image.Image, path: Path, max_side: int | None = None) -> None:
	out = img
	if max_side is not None:
		sw, sh = out.size
		scale = min(1.0, max_side / float(max(sw, sh)))
		if scale < 1.0:
			out = out.resize((max(1, int(sw * scale)), max(1, int(sh * scale))), Image.Resampling.LANCZOS)
	path.parent.mkdir(parents=True, exist_ok=True)
	out.save(path, optimize=True)
	print(f"saved {path} {out.size}")


def classify(boxes: list[tuple[int, int, int, int]]) -> dict[str, tuple[int, int, int, int]]:
	"""Heuristic naming by geometry + reading order."""
	enriched = []
	for b in boxes:
		x0, y0, x1, y1 = b
		bw, bh = x1 - x0, y1 - y0
		enriched.append({"box": b, "w": bw, "h": bh, "cx": (x0 + x1) / 2, "cy": (y0 + y1) / 2, "ar": bw / max(1, bh)})

	# Widest long ribbon = question banner
	banner = max(enriched, key=lambda e: e["w"] if e["ar"] > 2.2 else -1)
	# Long thin dash strip
	dash_candidates = [e for e in enriched if e["ar"] > 5.0 and e["h"] < banner["h"] * 0.55]
	dash = max(dash_candidates, key=lambda e: e["w"]) if dash_candidates else None

	# Score: wide-ish but shorter than banner, not circle
	rest = [e for e in enriched if e is not banner and e is not dash]
	score_candidates = [e for e in rest if e["ar"] > 1.4 and e["ar"] < 3.2 and e["w"] > 120]
	score = min(score_candidates, key=lambda e: e["cy"]) if score_candidates else max(rest, key=lambda e: e["w"])

	circles = [e for e in rest if e is not score and 0.75 <= e["ar"] <= 1.35]
	# Heart is often slightly taller / not perfectly circular — include near-square too
	near = [e for e in rest if e is not score and e not in circles and 0.7 <= e["ar"] <= 1.45]
	icons = circles + near
	# Deduplicate
	uniq = []
	for e in icons:
		if e not in uniq:
			uniq.append(e)
	icons = sorted(uniq, key=lambda e: (round(e["cy"] / 40), e["cx"]))

	# Heart: among icons, the one with more red — approximate by box later; use first tallish near top after score
	named: dict[str, tuple[int, int, int, int]] = {
		"question_banner": banner["box"],
		"score_frame": score["box"],
	}
	if dash:
		named["lane_dash_tile"] = dash["box"]

	# Remaining icon order left-to-right, top-to-bottom expected:
	# heart, sound_on, sound_off, movement, restart, exit, movement_plane
	icon_names = [
		"heart",
		"sound_on",
		"sound_off",
		"movement_direct",
		"restart",
		"exit",
		"movement_discrete",
	]
	remaining = [e for e in icons if e is not score]
	remaining = sorted(remaining, key=lambda e: (round(e["cy"] / 50), e["cx"]))
	for name, e in zip(icon_names, remaining):
		named[name] = e["box"]
	print("detected", {k: (v[2] - v[0], v[3] - v[1]) for k, v in named.items()})
	print("icon count", len(remaining))
	return named


def red_score(img: Image.Image, box: tuple[int, int, int, int]) -> float:
	crop = img.crop(box)
	px = crop.load()
	w, h = crop.size
	total = 0
	reddish = 0
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a < 40:
				continue
			total += 1
			if r > g + 30 and r > b + 20:
				reddish += 1
	return reddish / max(1, total)


def refine_names(img: Image.Image, named: dict[str, tuple[int, int, int, int]]) -> dict[str, tuple[int, int, int, int]]:
	"""Swap heart/exit among circular icons using redness."""
	icon_keys = [k for k in named if k not in ("question_banner", "score_frame", "lane_dash_tile")]
	if not icon_keys:
		return named
	scores = {k: red_score(img, named[k]) for k in icon_keys}
	heart_key = max(scores, key=scores.get)
	# Prefer assigning the reddest non-exit-sized to heart
	boxes = [(k, named[k], scores[k]) for k in icon_keys]
	boxes_sorted = sorted(boxes, key=lambda t: -t[2])
	# Most red = heart, second most red among cream buttons with X might be exit
	heart_box = boxes_sorted[0][1]
	# Rebuild ordered icons excluding heart by position
	others = sorted(
		[b for b in boxes if b[1] != heart_box],
		key=lambda t: (round((t[1][1] + t[1][3]) / 2 / 50), (t[1][0] + t[1][2]) / 2),
	)
	# Exit often last or has red X — pick highest red among remaining as exit if > 0.05
	exit_idx = 0
	best_red = -1.0
	for i, b in enumerate(others):
		if b[2] > best_red:
			best_red = b[2]
			exit_idx = i
	ordered_boxes = [heart_box] + [b[1] for b in others]
	# Move exit to dedicated slot
	if others:
		exit_box = others[exit_idx][1]
		ordered_boxes = [heart_box] + [b[1] for b in others if b[1] != exit_box]
		# Names: heart, sound_on, sound_off, movement_direct, restart, movement_discrete, exit
		names = ["heart", "sound_on", "sound_off", "movement_direct", "restart", "movement_discrete"]
		out = {
			"question_banner": named["question_banner"],
			"score_frame": named["score_frame"],
		}
		if "lane_dash_tile" in named:
			out["lane_dash_tile"] = named["lane_dash_tile"]
		for name, box in zip(names, ordered_boxes[1:]):
			out[name] = box
		out["exit"] = exit_box
		out["heart"] = heart_box
		return out
	return named


def main() -> None:
	print("atlas", ATLAS, "exists", ATLAS.exists())
	atlas = chroma_black(Image.open(ATLAS))
	save(atlas, CONCEPT_DST / "ui_atlas_modern.png")
	mask = build_mask(atlas)
	boxes = find_components(mask)
	print("components", len(boxes))
	named = refine_names(atlas, classify(boxes))
	w, h = atlas.size
	GAME_HUD.mkdir(parents=True, exist_ok=True)

	exports = {
		"score_frame": ("score_frame.png", 512),
		"question_banner": ("question_banner.png", 1024),
		"heart": ("heart.png", 128),
		"sound_on": ("btn_sound_on.png", 160),
		"sound_off": ("btn_sound_off.png", 160),
		"movement_direct": ("btn_movement_direct.png", 160),
		"movement_discrete": ("btn_movement_discrete.png", 160),
		"restart": ("btn_restart.png", 160),
		"exit": ("btn_exit.png", 160),
		"lane_dash_tile": ("lane_dash_tile.png", 512),
	}
	for key, (filename, max_side) in exports.items():
		if key not in named:
			print("MISSING", key)
			continue
		box = pad_box(named[key], w, h, 6)
		crop = atlas.crop(box)
		save(crop, CONCEPT_DST / "hud_modern" / filename, max_side)
		save(crop, GAME_HUD / filename, max_side)

	# Lane strip from dedicated image
	lane = chroma_black(Image.open(LANE), threshold=45)
	# Tight crop non-empty
	bbox = lane.getbbox()
	if bbox:
		lane = lane.crop(bbox)
	save(lane, CONCEPT_DST / "hud_modern" / "lane_dash_strip.png", 1024)
	save(lane, GAME_HUD / "lane_dash_strip.png", 1024)
	print("done")


if __name__ == "__main__":
	main()
