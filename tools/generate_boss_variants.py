"""Boss airship color variants: recolors the hand-drawn base SVGs with curated palettes.

Base art (source of truth, variant 0 look):
  src/features/boss/art/airship_body.svg       — regular boss (slate envelope, red fins)
  src/features/boss/art/exam_airship_body.svg  — royal / exam chief (iron hull, crimson fins)
Output: src/features/boss/art/variants/{regular|royal}_<name>.svg (wired into the boss scenes'
`body_variants`). Ink (#2A3340), white rim, face, gondola wood, crown and plates are never recolored,
so every variant stays in the notebook-pencil palette. Edit palettes here and re-run:
  python tools/generate_boss_variants.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "src" / "features" / "boss" / "art"
OUT = ART / "variants"

# Base color → role. Each palette gives a value per role (missing role = keep base color).
REGULAR_ROLES = {
    "#8C97AD": "env", "#66718A": "shade", "#46506A": "seam", "#B5BFD1": "hl", "#DCE2EC": "hl2",
    "#7A8296": "pod", "#C65A4C": "fin", "#B44F43": "fin_dark", "#9C3D33": "fin_line",
}
REGULAR = {
    "slate": {},  # base look
    "moss": {"env": "#8FA386", "shade": "#6B8062", "seam": "#4C5E45", "hl": "#B8C9AE", "hl2": "#DDE7D6",
             "pod": "#7C8A74", "fin": "#D19A3E", "fin_dark": "#BC8733", "fin_line": "#9A6B22"},
    "plum": {"env": "#9D8AAE", "shade": "#776589", "seam": "#54466A", "hl": "#C3B5D1", "hl2": "#E3DBEC",
             "pod": "#857796", "fin": "#4E9A8F", "fin_dark": "#43867C", "fin_line": "#326B62"},
    "sand": {"env": "#B9A47F", "shade": "#957F5C", "seam": "#6E5B3F", "hl": "#D8C8A6", "hl2": "#EEE4CF",
             "pod": "#8E8270", "fin": "#4F6A9A", "fin_dark": "#445D88", "fin_line": "#344A6F"},
    "teal": {"env": "#7FA3A6", "shade": "#5D8083", "seam": "#425E61", "hl": "#A9C7C9", "hl2": "#D6E6E7",
             "pod": "#6F8789", "fin": "#D9775A", "fin_dark": "#C4664B", "fin_line": "#A1503A"},
    "rose": {"env": "#B48E8E", "shade": "#8F6A6A", "seam": "#684B4B", "hl": "#D3B5B3", "hl2": "#EBDAD8",
             "pod": "#8A7A82", "fin": "#5E7896", "fin_dark": "#506884", "fin_line": "#3E526B"},
}

ROYAL_ROLES = {
    "#4C5266": "hull", "#646B82": "face", "#353A4A": "shade", "#A3ABBF": "hl", "#6A7186": "spike",
    "#8A93A8": "pod_hl", "#3E4354": "gondola", "#262A36": "gondola_line",
    "#A8323A": "fin", "#8A2830": "fin_dark", "#E6B44A": "fin_stripe",
}
ROYAL = {
    "iron": {},  # base look
    "violet": {"hull": "#54476A", "face": "#6E5F88", "shade": "#3A3050", "hl": "#AE9FC6", "spike": "#75668F",
               "pod_hl": "#9A8DB0", "gondola": "#43394F", "gondola_line": "#2B2436"},
    "navy": {"hull": "#3E4A6B", "face": "#56638A", "shade": "#2B3450", "hl": "#9CA8C8", "spike": "#5F6C92",
             "pod_hl": "#8995B5", "gondola": "#343D55", "gondola_line": "#232A3C",
             "fin": "#C9962F", "fin_dark": "#A87A22", "fin_stripe": "#A8323A"},
    "pine": {"hull": "#3F5658", "face": "#57716F", "shade": "#2C3E40", "hl": "#9FB9B6", "spike": "#5F7A78",
             "pod_hl": "#87A09D", "gondola": "#34454A", "gondola_line": "#223034",
             "fin": "#C0602F", "fin_dark": "#9E4C24"},
    "bronze": {"hull": "#5A4A40", "face": "#75614F", "shade": "#3E322B", "hl": "#B9A48E", "spike": "#7D6857",
               "pod_hl": "#A08B76", "gondola": "#45392F", "gondola_line": "#2E2620",
               "fin": "#2F6E6A", "fin_dark": "#24564F"},
}


def recolor(svg: str, roles: dict, palette: dict) -> str:
    for base, role in roles.items():
        if role in palette:
            svg = svg.replace(base, palette[role])
    return svg


def main() -> None:
    OUT.mkdir(exist_ok=True)
    jobs = [("regular", ART / "airship_body.svg", REGULAR_ROLES, REGULAR),
            ("royal", ART / "exam_airship_body.svg", ROYAL_ROLES, ROYAL)]
    written = 0
    for kind, src, roles, palettes in jobs:
        base = src.read_text(encoding="utf-8")
        for name, palette in palettes.items():
            if not palette:
                continue  # base look = the source SVG itself
            out = OUT / f"{kind}_{name}.svg"
            out.write_text(recolor(base, roles, palette), encoding="utf-8", newline="\n")
            written += 1
    print(f"Wrote {written} boss variants to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
