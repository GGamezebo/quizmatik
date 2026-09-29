"""Redesign v1 concept frames (AI look-reference only, never shipped).

Builds SVG mockups from real game art (read-only) and renders PNGs via headless Chrome.
Run from anywhere:  python concepts/redesign_v1/_build_concepts.py [name ...]
"""
from __future__ import annotations

import base64
import math
import pathlib
import random
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SCALE = 1.5  # 1280x720 layout -> 1920x1080 png

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "google-chrome",
    "chromium",
]

# ---------------------------------------------------------------- palette
CREAM = "#F3E6C8"
PAPER_HI = "#FAF0DB"
PAPER_LO = "#E0D1B3"
RIM = "#FFFDF4"
INK = "#2A3340"
INK_SOFT = "#5B6573"
ACCENT = "#F0C94A"
HEART = "#E85A5A"
WIN = "#38704D"
LOSE = "#B34742"
WARM = "#D9822B"
GREEN_CTA = "#86BF5C"
GREEN_DARK = "#2E5A24"
VALLEY = {
    "addition": ("Сложение", "#5E9E4A"),
    "subtraction": ("Вычитание", "#4A86C0"),
    "multiplication": ("Умножение", "#E08A3C"),
    "division": ("Деление", "#8A62B8"),
    "mix": ("Микс", "#D35A8A"),
}

# ---------------------------------------------------------------- assets
_uri_cache: dict[str, str] = {}


def uri(rel: str) -> str:
    if rel not in _uri_cache:
        p = ROOT / rel
        mime = "image/png" if p.suffix == ".png" else "font/ttf"
        _uri_cache[rel] = f"data:{mime};base64," + base64.b64encode(p.read_bytes()).decode()
    return _uri_cache[rel]


BG_COLOR = "src/ui/backgrounds/classic_sky/bg_gameplay_sky1.png"
BG_PENCIL = "assets/ui/backgrounds/bg_gameplay_sky.png"
BG_HANGAR = "src/game/scenes/menu/trophy_room_window/ui/bg_hangar_achievements.png"
VALLEY_IMG = "assets/ui/backgrounds/valleys/valley_{}.png"
BALLOONS = "src/features/answer/balloons_atlas.png"
PLANES = "src/features/plane/planes_atlas_spaced.png"
STAMP = "assets/ui/stamps/stamp_{}.png"
TROPHY = "src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_{}.png"

# ---------------------------------------------------------------- svg helpers


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def defs() -> str:
    return f"""
<defs>
  <pattern id="grid" width="24" height="24" patternUnits="userSpaceOnUse">
    <path d="M24 0H0V24" fill="none" stroke="#8FB0C8" stroke-width="1" opacity=".45"/>
  </pattern>
  <pattern id="hatch" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(35)">
    <line x1="0" y1="0" x2="0" y2="7" stroke="{INK}" stroke-width="1.2" opacity=".18"/>
  </pattern>
  <filter id="rough" x="-5%" y="-5%" width="110%" height="110%">
    <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="3" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="3.2" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
  <filter id="wash" x="-5%" y="-10%" width="110%" height="120%">
    <feTurbulence type="fractalNoise" baseFrequency="0.02 0.05" numOctaves="3" seed="8" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="7" xChannelSelector="R" yChannelSelector="G" result="d"/>
    <feTurbulence type="fractalNoise" baseFrequency="0.09" numOctaves="2" seed="2" result="g"/>
    <feColorMatrix in="g" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 .55 -.18" result="spots"/>
    <feComposite in="spots" in2="d" operator="in" result="s2"/>
    <feMerge><feMergeNode in="d"/><feMergeNode in="s2"/></feMerge>
  </filter>
  <filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
    <feDropShadow dx="0" dy="5" stdDeviation="4" flood-color="{INK}" flood-opacity=".28"/>
  </filter>
  <filter id="shadowS" x="-20%" y="-20%" width="140%" height="150%">
    <feDropShadow dx="0" dy="3" stdDeviation="2" flood-color="{INK}" flood-opacity=".25"/>
  </filter>
  <filter id="sticker" x="-25%" y="-25%" width="150%" height="150%">
    <feMorphology in="SourceAlpha" operator="dilate" radius="5" result="d"/>
    <feFlood flood-color="{RIM}"/><feComposite in2="d" operator="in" result="rim"/>
    <feGaussianBlur in="d" stdDeviation="3.5" result="b"/><feOffset in="b" dy="5" result="bo"/>
    <feFlood flood-color="{INK}" flood-opacity=".3"/><feComposite in2="bo" operator="in" result="sh"/>
    <feMerge><feMergeNode in="sh"/><feMergeNode in="rim"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="stickerBig" x="-25%" y="-25%" width="150%" height="150%">
    <feMorphology in="SourceAlpha" operator="dilate" radius="8" result="d"/>
    <feFlood flood-color="{RIM}"/><feComposite in2="d" operator="in" result="rim"/>
    <feGaussianBlur in="d" stdDeviation="4" result="b"/><feOffset in="b" dy="6" result="bo"/>
    <feFlood flood-color="{INK}" flood-opacity=".32"/><feComposite in2="bo" operator="in" result="sh"/>
    <feMerge><feMergeNode in="sh"/><feMergeNode in="rim"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="grain" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency=".85" numOctaves="2" seed="5"/>
    <feColorMatrix type="matrix" values="0 0 0 0 .16  0 0 0 0 .2  0 0 0 0 .25  0 0 0 .09 0"/>
  </filter>
  <filter id="bleed" x="-10%" y="-10%" width="120%" height="120%">
    <feTurbulence type="fractalNoise" baseFrequency="0.012 0.03" numOctaves="4" seed="11" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="90" xChannelSelector="R" yChannelSelector="G" result="d"/>
    <feGaussianBlur in="d" stdDeviation="5"/>
  </filter>
  <filter id="soft"><feGaussianBlur stdDeviation="6"/></filter>
  <filter id="hueGreen"><feColorMatrix type="hueRotate" values="215"/></filter>
  <filter id="hueRed"><feColorMatrix type="hueRotate" values="100"/><feColorMatrix type="saturate" values="1.3"/></filter>
  <filter id="hueGold"><feColorMatrix type="hueRotate" values="150"/><feColorMatrix type="saturate" values="1.6"/></filter>
  <filter id="graphite"><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncA type="linear" slope=".55"/></feComponentTransfer></filter>
  <filter id="desat"><feColorMatrix type="saturate" values=".55"/></filter>
  <radialGradient id="nulikBody" cx="35%" cy="30%" r="75%">
    <stop offset="0" stop-color="#B793EA"/><stop offset=".6" stop-color="#8E5BD0"/><stop offset="1" stop-color="#6B3FAE"/>
  </radialGradient>
  <radialGradient id="coin" cx="35%" cy="30%" r="80%">
    <stop offset="0" stop-color="#FFE9A0"/><stop offset=".55" stop-color="{ACCENT}"/><stop offset="1" stop-color="#C9932A"/>
  </radialGradient>
  <linearGradient id="ctaGreen" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#A6D47E"/><stop offset="1" stop-color="{GREEN_CTA}"/>
  </linearGradient>
  <linearGradient id="dimTop" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{CREAM}" stop-opacity=".55"/><stop offset=".25" stop-color="{CREAM}" stop-opacity="0"/>
  </linearGradient>
</defs>"""


def svg_doc(body: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'width="1280" height="720" viewBox="0 0 1280 720">'
        + defs()
        + body
        + '<rect width="1280" height="720" filter="url(#grain)" pointer-events="none"/>'
        + "</svg>"
    )


def html_doc(svg: str) -> str:
    css = (
        "@font-face{font-family:'Nunito';src:url(" + uri("assets/fonts/Nunito-Bold.ttf") + ");}"
        "@font-face{font-family:'Doodle';src:url(" + uri("assets/fonts/RubikDoodleShadow-Regular.ttf") + ");}"
        "html,body{margin:0;padding:0;overflow:hidden;background:#000}"
        "svg{display:block}text{font-family:'Nunito';}"
        ".t{font-family:'Doodle';}"
    )
    return f"<!doctype html><html><head><meta charset='utf-8'><style>{css}</style></head><body>{svg}</body></html>"


def image(rel: str, x, y, w, h, extra: str = "", par: str = "xMidYMid slice") -> str:
    return f'<image href="{uri(rel)}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="{par}" {extra}/>'


def text(x, y, s, size=24, fill=INK, anchor="middle", cls="", extra="") -> str:
    c = f' class="{cls}"' if cls else ""
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" text-anchor="{anchor}"{c} {extra}>{esc(s)}</text>'


def outlined(x, y, s, size, fill="#fff", stroke=INK, sw=6, anchor="middle", cls="") -> str:
    return text(x, y, s, size, fill, anchor, cls,
                f'stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" paint-order="stroke"')


def title(x, y, s, size=64, fill=WIN, big=True) -> str:
    f = "stickerBig" if big else "sticker"
    return f'<g filter="url(#{f})">{text(x, y, s, size, fill, cls="t")}</g>'


def rrect(x, y, w, h, r, fill=CREAM, stroke=INK, sw=3, extra="") -> str:
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" {extra}/>'


def card(x, y, w, h, r=22, fill=CREAM, sw=3, rot=0.0, stroke=INK) -> str:
    cx, cy = x + w / 2, y + h / 2
    return (
        f'<g transform="rotate({rot} {cx} {cy})">'
        f'<g filter="url(#shadow)">{rrect(x - 6, y - 6, w + 12, h + 12, r + 6, RIM, "none", 0)}</g>'
        f'<g filter="url(#rough)">{rrect(x, y, w, h, r, fill, stroke, sw)}'
        f'{rrect(x + 7, y + 7, w - 14, h - 14, max(r - 6, 4), "none", stroke, 1.2, "opacity=.35")}</g>'
        "</g>"
    )


def pill(x, y, w, h, label, icon_name=None, primary=True, size=30) -> str:
    fill = "url(#ctaGreen)" if primary else CREAM
    out = (
        f'<g filter="url(#shadow)">{rrect(x - 5, y - 5, w + 10, h + 10, (h + 10) / 2, RIM, "none", 0)}</g>'
        f'<g filter="url(#rough)">{rrect(x, y, w, h, h / 2, fill, INK, 3)}</g>'
    )
    if primary:
        out += f'<path d="M{x + h / 2} {y + 9} H{x + w - h / 2}" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".35"/>'
    tx = x + w / 2
    if icon_name:
        ic = x + h * 0.62
        out += icon(icon_name, ic, y + h / 2, h * 0.36, "#fff" if primary else INK, fill_icon=True)
        tx = x + h * 0.95 + (w - h * 0.95) / 2
    if primary:
        out += outlined(tx, y + h / 2 + size * 0.36, label, size, "#fff", GREEN_DARK, 6)
    else:
        out += text(tx, y + h / 2 + size * 0.36, label, size, INK)
    return out


def round_btn(cx, cy, r, name, label=None, fill=CREAM, color=INK, ring=None, dim=False) -> str:
    op = ' opacity=".55"' if dim else ""
    out = f"<g{op}>"
    out += f'<g filter="url(#shadow)"><circle cx="{cx}" cy="{cy}" r="{r + 5}" fill="{RIM}"/></g>'
    out += f'<g filter="url(#rough)"><circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{INK}" stroke-width="3"/>'
    out += f'<circle cx="{cx}" cy="{cy}" r="{r - 6}" fill="none" stroke="{INK}" stroke-width="1.2" opacity=".3"/></g>'
    if ring:
        out += f'<circle cx="{cx}" cy="{cy}" r="{r + 10}" fill="none" stroke="{ring}" stroke-width="4" stroke-dasharray="10 7"/>'
    out += icon(name, cx, cy, r * 0.62, color)
    if label:
        out += chip_label(cx, cy + r + 22, label)
    out += "</g>"
    return out


def chip_label(cx, cy, label, size=17) -> str:
    w = len(label) * size * 0.58 + 22
    return (
        f'<g transform="rotate(-2 {cx} {cy})"><g filter="url(#shadowS)">{rrect(cx - w / 2, cy - 15, w, 30, 6, PAPER_HI, INK, 1.8)}</g>'
        + text(cx, cy + 6, label, size)
        + "</g>"
    )


def gear_path() -> str:
    pts = []
    teeth = 8
    for i in range(teeth * 4):
        a = i / (teeth * 4) * math.tau
        r = 0.62 if (i % 4) in (1, 2) else 0.46
        pts.append(f"{r * math.cos(a):.3f},{r * math.sin(a):.3f}")
    return "M" + " L".join(pts) + " Z"


GEAR = gear_path()


def icon(name, cx, cy, s, color=INK, fill_icon=False, sw=None) -> str:
    """Stroke icons in unit space (~[-0.6, 0.6]) scaled by s."""
    w = (sw or max(3.2, s * 0.14)) / s
    st = f'fill="none" stroke="{color}" stroke-width="{w:.3f}" stroke-linecap="round" stroke-linejoin="round"'
    fl = f'fill="{color}" stroke="{color}" stroke-width="{w * 0.6:.3f}" stroke-linejoin="round"'
    p = {
        "back": f'<path d="M.5 .45 C.5 -.1 .15 -.22 -.42 -.22" {st}/><path d="M-.18 -.48 L-.46 -.22 L-.18 .04" {st}/>',
        "next": f'<path d="M-.5 0 H.48 M.14 -.34 L.5 0 L.14 .34" {st}/>',
        "prev": f'<path d="M.5 0 H-.48 M-.14 -.34 L-.5 0 L-.14 .34" {st}/>',
        "restart": f'<path d="M.46 .05 A.46 .46 0 1 1 .24 -.4" {st}/><path d="M.02 -.58 L.3 -.4 L.06 -.16" {st}/>',
        "check": f'<path d="M-.46 0 L-.12 .34 L.5 -.4" {st}/>',
        "x": f'<path d="M-.4 -.4 L.4 .4 M.4 -.4 L-.4 .4" {st}/>',
        "pause": f'<path d="M-.2 -.42 V.42 M.2 -.42 V.42" {st} stroke-width="{w * 1.5:.3f}"/>',
        "play": f'<path d="M-.3 -.46 L.52 0 L-.3 .46 Z" {fl}/>',
        "gear": f'<path d="{GEAR}" {st}/><circle r=".18" {st}/>',
        "plus": f'<path d="M0 -.46 V.46 M-.46 0 H.46" {st}/>',
        "music": f'<path d="M-.1 .32 V-.46 L.42 -.56 V.2" {st}/><ellipse cx="-.26" cy=".34" rx=".17" ry=".13" {fl}/><ellipse cx=".26" cy=".22" rx=".17" ry=".13" {fl}/>',
        "sound": f'<path d="M-.52 -.16 H-.28 L.02 -.44 V.44 L-.28 .16 H-.52 Z" {fl}/><path d="M.2 -.2 Q.34 0 .2 .2 M.34 -.36 Q.6 0 .34 .36" {st}/>',
        "vibrate": f'<rect x="-.22" y="-.46" width=".44" height=".92" rx=".08" {st}/><path d="M-.44 -.22 L-.36 -.1 L-.44 .02 L-.36 .14 M.44 -.22 L.36 -.1 L.44 .02 L.36 .14" {st}/>',
        "home": f'<path d="M-.5 -.02 L0 -.48 L.5 -.02 M-.36 -.14 V.44 H.36 V-.14" {st}/><rect x="-.1" y=".14" width=".2" height=".3" {fl}/>',
        "lock": f'<rect x="-.36" y="-.08" width=".72" height=".56" rx=".08" {fl}/><path d="M-.22 -.08 V-.26 A.22 .22 0 0 1 .22 -.26 V-.08" {st}/>',
        "map": f'<path d="M-.55 -.36 L-.18 -.46 L.18 -.36 L.55 -.46 V.36 L.18 .46 L-.18 .36 L-.55 .46 Z" fill="#F7E3B5" stroke="{color}" stroke-width="{w:.3f}" stroke-linejoin="round"/><path d="M-.38 .22 Q-.1 -.1 .1 .12 T.36 -.2" fill="none" stroke="{color}" stroke-width="{w * .6:.3f}" stroke-dasharray=".06 .07"/><path d="M.28 -.28 L.44 -.12 M.44 -.28 L.28 -.12" stroke="{HEART}" stroke-width="{w * .8:.3f}" stroke-linecap="round"/>',
        "pencil": f'<g transform="rotate(45)"><rect x="-.14" y="-.55" width=".28" height=".8" fill="{ACCENT}" stroke="{color}" stroke-width="{w * .8:.3f}"/><path d="M-.14 .25 L0 .55 L.14 .25 Z" fill="#F4D7A8" stroke="{color}" stroke-width="{w * .8:.3f}" stroke-linejoin="round"/><rect x="-.14" y="-.62" width=".28" height=".12" fill="{HEART}" stroke="{color}" stroke-width="{w * .6:.3f}"/></g>',
        "trophy": f'<path d="M-.34 -.46 H.34 L.3 -.02 Q0 .24 -.3 -.02 Z" fill="{ACCENT}" stroke="{color}" stroke-width="{w:.3f}" stroke-linejoin="round"/><path d="M-.33 -.36 Q-.6 -.3 -.5 -.1 Q-.42 .04 -.26 .02 M.33 -.36 Q.6 -.3 .5 -.1 Q.42 .04 .26 .02 M0 .14 V.34 M-.24 .46 H.24 V.36 H-.24 Z" {st}/>',
        "plane": f'<path d="M-.55 .06 L.5 -.06 L.58 0 L.5 .06 L-.55 .06 Z M-.1 0 L-.25 -.4 L0 -.4 L.18 0 M-.1 .04 L-.2 .36 L.02 .36 L.14 .04 M-.5 .04 L-.56 -.22 L-.44 -.22 L-.36 .02" {st}/>',
        "hand": f'<path d="M-.1 .55 L-.34 .12 Q-.4 0 -.28 -.02 Q-.18 -.03 -.1 .1 V-.48 Q-.1 -.6 0 -.6 Q.1 -.6 .1 -.48 V-.12 Q.12 -.22 .22 -.2 Q.3 -.18 .3 -.06 Q.34 -.14 .42 -.1 Q.48 -.06 .48 .04 V.24 Q.46 .44 .34 .55 Z" fill="#fff" stroke="{color}" stroke-width="{w:.3f}" stroke-linejoin="round"/>',
        "arrows_ud": f'<path d="M0 -.55 V.55 M-.22 -.3 L0 -.55 L.22 -.3 M-.22 .3 L0 .55 L.22 .3" {st}/>',
        "clock": f'<circle r=".46" {st}/><path d="M0 -.28 V0 L.2 .14" {st}/>',
        "star": f'<path d="{star_path(0, 0, .55, .24)}" fill="{ACCENT}" stroke="{color}" stroke-width="{w * .7:.3f}" stroke-linejoin="round"/>',
        "flame": f'<path d="M0 .52 Q-.44 .44 -.36 .02 Q-.3 -.2 -.12 -.34 Q-.12 -.12 0 -.08 Q-.06 -.36 .12 -.56 Q.16 -.3 .34 -.1 Q.5 .1 .38 .34 Q.26 .52 0 .52 Z" fill="{WARM}" stroke="{color}" stroke-width="{w * .7:.3f}" stroke-linejoin="round"/><path d="M0 .44 Q-.18 .38 -.14 .16 Q-.08 .02 .02 -.04 Q.04 .12 .16 .2 Q.2 .38 0 .44 Z" fill="{ACCENT}"/>',
        "edit": f'<g transform="rotate(45)"><rect x="-.12" y="-.5" width=".24" height=".7" {st}/><path d="M-.12 .2 L0 .48 L.12 .2" {st}/></g>',
    }[name]
    return f'<g transform="translate({cx} {cy}) scale({s})">{p}</g>'


def star_path(cx, cy, ro, ri, n=5) -> str:
    pts = []
    for i in range(n * 2):
        a = -math.pi / 2 + i * math.pi / n
        r = ro if i % 2 == 0 else ri
        pts.append(f"{cx + r * math.cos(a):.3f},{cy + r * math.sin(a):.3f}")
    return "M" + " L".join(pts) + " Z"


def star(cx, cy, r, filled=True) -> str:
    return (f'<path d="{star_path(cx, cy, r, r * .46)}" fill="{ACCENT if filled else PAPER_HI}" '
            f'stroke="{INK if filled else "#A8A08C"}" stroke-width="2" stroke-linejoin="round" filter="url(#shadowS)"/>')


def coin(cx, cy, r) -> str:
    return (
        f'<g filter="url(#shadowS)"><circle cx="{cx}" cy="{cy}" r="{r + 3}" fill="{RIM}"/>'
        f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#coin)" stroke="#9A6B18" stroke-width="2"/>'
        f'<circle cx="{cx}" cy="{cy}" r="{r * .72}" fill="none" stroke="#B9862A" stroke-width="1.5"/>'
        f'<path d="{star_path(cx, cy, r * .5, r * .22)}" fill="#FFF3C4" stroke="#B9862A" stroke-width="1.2"/></g>'
    )


def heart_path(cx, cy, s) -> str:
    return (f"M{cx} {cy + s * .9} C{cx - s * 1.3} {cy + s * .1} {cx - s * .9} {cy - s * .95} {cx} {cy - s * .35} "
            f"C{cx + s * .9} {cy - s * .95} {cx + s * 1.3} {cy + s * .1} {cx} {cy + s * .9} Z")


def heart(cx, cy, s, full=True, cracked=False) -> str:
    fill = HEART if full else PAPER_LO
    out = f'<g filter="url(#sticker)"><path d="{heart_path(cx, cy, s)}" fill="{fill}" stroke="{INK}" stroke-width="2.5"/></g>'
    if full:
        out += f'<path d="M{cx - s * .55} {cy - s * .2} Q{cx - s * .5} {cy - s * .55} {cx - s * .2} {cy - s * .5}" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" opacity=".7"/>'
    if cracked:
        out += f'<path d="M{cx} {cy - s * .35} L{cx - s * .15} {cy} L{cx + s * .12} {cy + s * .2} L{cx - s * .05} {cy + s * .6}" stroke="{INK}" stroke-width="3" fill="none"/>'
        out += f'<path d="M{cx - s * 1.5} {cy - s * .6} l-10 -6 M{cx + s * 1.5} {cy - s * .6} l10 -6 M{cx + s * 1.6} {cy + s * .1} l12 0" stroke="{INK}" stroke-width="2.5" stroke-linecap="round"/>'
    return out


def stamp(cx, cy, name, size=110, rot=0.0, op=1.0) -> str:
    return (f'<g transform="rotate({rot} {cx} {cy})" opacity="{op}">'
            + image(STAMP.format(name), cx - size / 2, cy - size / 2, size, size, par="xMidYMid meet") + "</g>")


BALLOON_COLS = 5


def balloon(cx, cy, frame, number, size=118, op=1.0, extra_g="") -> str:
    """cx, cy = balloon body center."""
    col, row = frame % BALLOON_COLS, frame // BALLOON_COLS
    w, h = size * 1.35, size * 1.35 * 240 / 256
    x, y = cx - w / 2, cy - h * 0.46
    string_y = y + h * 0.95
    s = (f'<path d="M{cx} {string_y} q18 20 40 8 t44 12 t40 -4" fill="none" stroke="#A88A5C" stroke-width="3" '
         f'stroke-linecap="round" opacity=".9"/>')
    img = (f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{col * 256} {row * 240} 256 240" overflow="hidden">'
           f'<image href="{uri(BALLOONS)}" width="1280" height="720"/></svg>')
    fs = size * (0.46 if len(str(number)) <= 2 else 0.36)
    num = outlined(cx, cy + fs * 0.35, str(number), fs, "#fff", INK, 6)
    return f'<g opacity="{op}" {extra_g}>{s}<g filter="url(#shadowS)">{img}</g>{num}</g>'


def plane(x, y, w, row=0, hue=None, op=1.0, graphite=False) -> str:
    h = w * 108 / 288
    f = ""
    if graphite:
        f = ' filter="url(#graphite)"'
    elif hue:
        f = f' filter="url(#{hue})"'
    return (f'<g opacity="{op}"><g filter="url(#shadowS)"><g{f}>'
            f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="0 {row * 108} 288 108" overflow="hidden">'
            f'<image href="{uri(PLANES)}" width="288" height="324"/></svg></g></g></g>')


def nulik(cx, cy, s=1.0, mood="happy", flip=False) -> str:
    """Mascot «Нулик»: purple pencil-shaded blob with antenna."""
    r = 62
    arms = {
        "happy": f'<ellipse cx="{r * .95}" cy="{-r * .55}" rx="16" ry="26" transform="rotate(35 {r * .95} {-r * .55})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>'
                 f'<ellipse cx="{-r * .98}" cy="{r * .2}" rx="14" ry="22" transform="rotate(-20 {-r * .98} {r * .2})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>',
        "cheer": f'<ellipse cx="{r * .9}" cy="{-r * .75}" rx="15" ry="27" transform="rotate(30 {r * .9} {-r * .75})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>'
                 f'<ellipse cx="{-r * .9}" cy="{-r * .75}" rx="15" ry="27" transform="rotate(-30 {-r * .9} {-r * .75})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>',
        "think": f'<ellipse cx="{r * .35}" cy="{r * .72}" rx="14" ry="20" transform="rotate(-50 {r * .35} {r * .72})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>'
                 f'<ellipse cx="{-r * .98}" cy="{r * .25}" rx="14" ry="22" transform="rotate(-20 {-r * .98} {r * .25})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>',
        "point": f'<ellipse cx="{r * 1.1}" cy="{-r * .05}" rx="28" ry="14" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>'
                 f'<ellipse cx="{-r * .98}" cy="{r * .25}" rx="14" ry="22" transform="rotate(-20 {-r * .98} {r * .25})" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>',
    }[mood]
    mouth = {
        "happy": f'<path d="M-20 14 Q0 40 20 14 Q0 22 -20 14 Z" fill="#7A2335" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/><path d="M-9 26 Q0 34 9 26 Q0 22 -9 26Z" fill="#F07C8E"/>',
        "cheer": f'<path d="M-24 10 Q0 50 24 10 Q0 18 -24 10 Z" fill="#7A2335" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/><path d="M-11 28 Q0 40 11 28 Q0 23 -11 28Z" fill="#F07C8E"/>',
        "think": f'<path d="M-10 22 Q2 17 12 22" fill="none" stroke="{INK}" stroke-width="3.5" stroke-linecap="round"/>',
        "point": f'<path d="M-20 14 Q0 40 20 14 Q0 22 -20 14 Z" fill="#7A2335" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>',
    }[mood]
    look = 4 if mood != "think" else -3
    eyes = ""
    for ex in (-22, 22):
        eyes += (f'<ellipse cx="{ex}" cy="-12" rx="15" ry="18" fill="#fff" stroke="{INK}" stroke-width="3"/>'
                 f'<circle cx="{ex + look}" cy="{-9 if mood != "think" else -16}" r="9" fill="{INK}"/>'
                 f'<circle cx="{ex + look + 3}" cy="{-13 if mood != "think" else -20}" r="3.2" fill="#fff"/>')
    brows = ""
    if mood == "think":
        brows = f'<path d="M-34 -36 Q-22 -42 -10 -36 M10 -40 Q22 -46 34 -38" fill="none" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>'
    fx = -1 if flip else 1
    body = (
        f'<g filter="url(#stickerBig)">'
        f'<path d="M0 {-r} Q4 {-r - 22} -2 {-r - 38}" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>'
        f'<circle cx="-2" cy="{-r - 42}" r="10" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3"/>'
        f"{arms}"
        f'<ellipse cx="0" cy="0" rx="{r}" ry="{r * .95}" fill="url(#nulikBody)" stroke="{INK}" stroke-width="3.5"/>'
        "</g>"
        f'<ellipse cx="0" cy="0" rx="{r}" ry="{r * .95}" fill="url(#hatch)"/>'
        f'<ellipse cx="-30" cy="-34" rx="14" ry="8" fill="#fff" opacity=".35" transform="rotate(-30 -30 -34)"/>'
        f'<ellipse cx="-38" cy="14" rx="10" ry="6" fill="#F28BB0" opacity=".7"/><ellipse cx="38" cy="14" rx="10" ry="6" fill="#F28BB0" opacity=".7"/>'
        f"{eyes}{brows}{mouth}"
    )
    return f'<g transform="translate({cx} {cy}) scale({s * fx} {s})">{body}</g>'


def bubble(x, y, w, h, lines: list[str], tail=(0, 0), size=24) -> str:
    """Speech bubble; tail=(tx, ty) absolute point the tail aims at."""
    tx, ty = tail
    bx = min(max(tx, x + 30), x + w - 30)
    by = y + h if ty > y + h else y
    base = (f'<path d="M{bx - 16} {by} L{tx} {ty} L{bx + 18} {by}" fill="{RIM}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
            if tx or ty else "")
    out = (f'<g filter="url(#shadow)"><g filter="url(#rough)">{rrect(x, y, w, h, h / 2.3 if h < 90 else 30, RIM, INK, 3)}{base}'
           f'{rrect(x + 2, y + 2, w - 4, h - 4, h / 2.3 if h < 90 else 30, RIM, "none", 0)}</g></g>')
    lh = size * 1.25
    y0 = y + h / 2 - (len(lines) - 1) * lh / 2 + size * 0.35
    for i, ln in enumerate(lines):
        out += text(x + w / 2, y0 + i * lh, ln, size)
    return out


def tape(cx, cy, w=90, h=28, rot=-8) -> str:
    return (f'<rect x="{cx - w / 2}" y="{cy - h / 2}" width="{w}" height="{h}" fill="#EFE3C0" opacity=".82" '
            f'transform="rotate({rot} {cx} {cy})" stroke="#CDBE96" stroke-width="1" filter="url(#rough)"/>')


def torn_banner(cx, cy, w, h, fill=PAPER_HI) -> str:
    rnd = random.Random(int(cx * 7 + w))
    pts_top, pts_bot = [], []
    n = int(w / 18)
    for i in range(n + 1):
        x = cx - w / 2 + i * w / n
        pts_top.append(f"{x:.1f},{cy - h / 2 + rnd.uniform(-3, 3):.1f}")
        pts_bot.append(f"{x:.1f},{cy + h / 2 + rnd.uniform(-3, 3):.1f}")
    d = "M" + " L".join(pts_top) + " L" + " L".join(reversed(pts_bot)) + " Z"
    ear = h * 0.7
    ears = (f'<path d="M{cx - w / 2 + 10} {cy - ear / 2 + 10} l-50 0 l18 {ear / 2} l-18 {ear / 2} l50 0 Z" fill="{PAPER_LO}" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>'
            f'<path d="M{cx + w / 2 - 10} {cy - ear / 2 + 10} l50 0 l-18 {ear / 2} l18 {ear / 2} l-50 0 Z" fill="{PAPER_LO}" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>')
    return f'<g filter="url(#shadow)"><g filter="url(#rough)">{ears}<path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="3"/></g></g>'


def chip(x, y, w, h, content: str, fill=PAPER_HI, rot=0.0) -> str:
    return (f'<g transform="rotate({rot} {x + w / 2} {y + h / 2})"><g filter="url(#shadowS)"><g filter="url(#rough)">'
            f'{rrect(x, y, w, h, h / 2, fill, INK, 2.5)}</g></g>{content}</g>')


def paper_bg(holes=True, margin=True) -> str:
    out = f'<rect width="1280" height="720" fill="{CREAM}"/><rect width="1280" height="720" fill="url(#grid)"/>'
    if margin:
        out += '<line x1="96" y1="0" x2="96" y2="720" stroke="#E07A7A" stroke-width="2" opacity=".6"/>'
    if holes:
        for i in range(12):
            out += f'<circle cx="40" cy="{40 + i * 58}" r="11" fill="#D8C9A6" stroke="{INK}" stroke-width="1.5" opacity=".8"/>'
    return out


def full_bg(rel, op=1.0, extra="") -> str:
    return f'<g opacity="{op}" {extra}>' + image(rel, 0, 0, 1280, 720) + "</g>"


def catmull(points) -> str:
    d = f"M{points[0][0]} {points[0][1]}"
    for i in range(len(points) - 1):
        p0 = points[i - 1] if i > 0 else points[i]
        p1, p2 = points[i], points[i + 1]
        p3 = points[i + 2] if i + 2 < len(points) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]} {p2[1]}"
    return d


def confetti(cx, cy, spread, n=26, seed=1) -> str:
    rnd = random.Random(seed)
    cols = [HEART, ACCENT, "#6FB36A", "#5A9BD5", "#A77BD8", WARM]
    out = ""
    for _ in range(n):
        x = cx + rnd.uniform(-spread, spread)
        y = cy + rnd.uniform(-spread * .45, spread * .45)
        w, h = rnd.uniform(9, 18), rnd.uniform(6, 11)
        out += (f'<rect x="{x:.0f}" y="{y:.0f}" width="{w:.0f}" height="{h:.0f}" fill="{rnd.choice(cols)}" '
                f'stroke="{INK}" stroke-width="1" transform="rotate({rnd.uniform(-60, 60):.0f} {x:.0f} {y:.0f})" opacity=".92"/>')
    return out


def sparkle(cx, cy, r, color=ACCENT) -> str:
    return f'<path d="{star_path(cx, cy, r, r * .28, 4)}" fill="{color}" stroke="{INK}" stroke-width="1.5"/>'


def ink_blot(cx, cy, r, seed=4) -> str:
    rnd = random.Random(seed)
    pts = []
    n = 16
    for i in range(n):
        a = i / n * math.tau
        rr = r * rnd.uniform(.6, 1.1)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d = catmull(pts + [pts[0]]) + " Z"
    drops = "".join(f'<circle cx="{cx + r * 1.4 * math.cos(a):.0f}" cy="{cy + r * 1.4 * math.sin(a):.0f}" r="{rnd.uniform(4, 9):.0f}" fill="#4A5260"/>'
                    for a in [rnd.uniform(0, math.tau) for _ in range(6)])
    return f'<g opacity=".85"><path d="{d}" fill="#4A5260"/>{drops}</g>'


# ---------------------------------------------------------------- shared battle scene

LANES = [218, 355, 492, 629]


def battle_world(bg_op=1.0, dim_band=True) -> str:
    out = full_bg(BG_COLOR, bg_op)
    out += '<rect width="1280" height="720" fill="url(#dimTop)"/>'
    if dim_band:
        out += f'<rect x="0" y="150" width="1280" height="570" fill="{CREAM}" opacity=".16"/>'
    for y in [150, 287, 424, 561, 698]:
        out += (f'<g filter="url(#rough)"><rect x="-10" y="{y - 3}" width="1300" height="6" rx="3" fill="#fff" opacity=".55"/></g>'
                f'<rect x="-10" y="{y + 3}" width="1300" height="2" fill="{INK}" opacity=".06"/>')
    return out


def progress_strip(x, y, w, total, done, marker=True) -> str:
    out = f'<g filter="url(#shadowS)"><g filter="url(#rough)">{rrect(x, y, w, 22, 11, PAPER_HI, INK, 2.2)}</g></g>'
    fw = (w - 8) * done / total
    out += f'<g filter="url(#wash)">{rrect(x + 4, y + 4, fw, 14, 7, "#8CC063", "none", 0)}</g>'
    for i in range(1, total):
        tx = x + 4 + (w - 8) * i / total
        out += f'<line x1="{tx:.1f}" y1="{y + 6}" x2="{tx:.1f}" y2="{y + 16}" stroke="{INK}" stroke-width="1.5" opacity=".35"/>'
    fx = x + w + 8
    out += (f'<path d="M{fx} {y + 22} V{y - 16}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>'
            f'<path d="M{fx} {y - 16} h24 l-6 7 l6 7 h-24 Z" fill="{HEART}" stroke="{INK}" stroke-width="2"/>')
    if marker:
        out += plane(x + fw - 22, y - 6, 40)
    return out


def hud(question: list[tuple[str, str]], score="5 / 12", hearts=(True, True, False), combo=True,
        progress=(12, 5), banner_w=520) -> str:
    out = round_btn(52, 56, 30, "pause")
    out += chip(98, 30, 128, 52, outlined(162, 67, score, 30, INK, RIM, 5))
    if combo:
        out += chip(106, 92, 150, 40, icon("flame", 132, 112, 20) + text(196, 120, "СЕРИЯ ×3", 20, "#fff",
                    extra=f'stroke="{GREEN_DARK}" stroke-width="0" '), fill=WARM, rot=-4)
    out += torn_banner(640, 60, banner_w, 88)
    # colored numerals
    total = sum(len(t) for t, _ in question)
    total_w = sum(38 if ch != " " else 14 for t, _ in question for ch in t)
    x = 640 - total_w / 2 - 0
    for t, c in question:
        for ch in t:
            if ch != " ":
                out += outlined(x + 19, 84, ch, 62, c, RIM, 5)
                x += 38
            else:
                x += 14
    if progress:
        out += progress_strip(490, 128, 300, *progress)
    for i, full in enumerate(hearts):
        out += heart(1090 + i * 58, 58, 20, full)
    return out


# ---------------------------------------------------------------- screens


def s00_style_board() -> str:
    b = paper_bg()
    b += title(640, 70, "Улётная математика · стиль", 50, WIN)
    b += text(640, 104, "Графит + акварель на тетрадном листе · наклейки с белой кромкой · штампы · один главный CTA на экран", 19, INK_SOFT)
    # palette
    b += text(150, 150, "ПАЛИТРА UI", 20, INK, "start")
    base = [(CREAM, "Крем"), (PAPER_HI, "Hover"), (PAPER_LO, "Нажата"), (INK, "Графит"),
            (ACCENT, "Звёзды"), (HEART, "Жизни"), (WIN, "Победа"), (WARM, "Почти!")]
    for i, (c, n) in enumerate(base):
        x = 150 + i * 62
        b += f'<g filter="url(#sticker)"><rect x="{x}" y="164" width="50" height="50" rx="10" fill="{c}" stroke="{INK}" stroke-width="2"/></g>'
        b += text(x + 25, 232, n, 13, INK_SOFT)
    b += text(150, 272, "ЦВЕТ ДОЛИНЫ (акцент кнопок, баннеров, прогресса)", 20, INK, "start")
    for i, (k, (n, c)) in enumerate(VALLEY.items()):
        x = 150 + i * 98
        b += f'<g filter="url(#wash)"><rect x="{x}" y="286" width="86" height="44" rx="12" fill="{c}"/></g>'
        b += text(x + 43, 350, n, 14, INK_SOFT)
    # fonts
    b += text(700, 150, "ШРИФТЫ", 20, INK, "start")
    b += title(700, 206, "Победный полёт!", 46, WIN, False).replace('text-anchor="middle"', 'text-anchor="start"')
    b += text(700, 246, "Rubik Doodle Shadow — только заголовки, без outline", 16, INK_SOFT, "start")
    b += outlined(700, 296, "7 × 8 = 56", 44, "#fff", INK, 6, "start")
    b += text(930, 290, "Nunito Bold — всё остальное;", 16, INK_SOFT, "start")
    b += text(930, 310, "цифры на шариках: белые + графит 6px", 16, INK_SOFT, "start")
    # buttons
    b += text(150, 400, "КНОПКИ", 20, INK, "start")
    b += pill(150, 418, 250, 70, "Продолжить", "play", True, 28)
    b += pill(420, 418, 210, 70, "Практика", "pencil", False, 26)
    b += '<g opacity=".45" filter="url(#desat)">' + pill(650, 418, 180, 70, "Скоро", "lock", False, 26) + "</g>"
    b += text(275, 512, "главный — 1 на экран", 14, INK_SOFT)
    b += text(525, 512, "вторичный", 14, INK_SOFT)
    b += text(740, 512, "недоступно", 14, INK_SOFT)
    b += round_btn(890, 452, 32, "gear")
    b += round_btn(970, 452, 32, "trophy", ring="#8CC063")
    b += '<g transform="translate(1050 455) scale(.92) translate(-1050 -455)">' + round_btn(1050, 455, 32, "back", fill=PAPER_LO) + "</g>"
    b += round_btn(1130, 452, 32, "sound", dim=True)
    b += text(890, 512, "обычная", 13, INK_SOFT) + text(970, 512, "активная", 13, INK_SOFT)
    b += text(1050, 512, "нажата", 13, INK_SOFT) + text(1130, 512, "выкл.", 13, INK_SOFT)
    # chips & game objects
    b += text(150, 560, "ЧИПЫ / ИГРОВЫЕ ОБЪЕКТЫ", 20, INK, "start")
    b += chip(150, 578, 110, 48, coin(178, 602, 15) + text(222, 611, "7", 26))
    b += chip(275, 578, 120, 48, star(302, 602, 15) + text(348, 611, "34", 26))
    b += chip(410, 580, 150, 44, icon("flame", 436, 602, 20) + text(500, 610, "СЕРИЯ ×3", 20, "#fff"), fill=WARM, rot=-4)
    b += heart(598, 600, 18) + heart(648, 600, 18) + heart(698, 600, 18, False)
    b += balloon(170, 660, 0, 12, 50) + balloon(246, 660, 2, 48, 50) + balloon(322, 660, 3, 7, 50)
    for i, n in enumerate(["sun", "flower", "cat", "empty"]):
        b += stamp(420 + i * 68, 675, n, 64, [-8, 5, -3, 0][i])
    b += progress_strip(660, 664, 180, 12, 5)
    # mascot poses
    b += text(1060, 560, "НУЛИК — гид", 20, INK)
    b += nulik(975, 650, .5, "happy") + nulik(1075, 650, .5, "think") + nulik(1180, 650, .5, "cheer")
    return svg_doc(b)


def s01_menu() -> str:
    b = full_bg(BG_PENCIL)
    # 3/5 dailies -> world painted left-to-right with a watercolor edge (not a uniform grey wash)
    b += ('<mask id="paint"><g filter="url(#bleed)"><rect x="-80" y="-80" width="870" height="900" fill="#fff"/></g></mask>'
          f'<g mask="url(#paint)">{image(BG_COLOR, 0, 0, 1280, 720)}</g>')
    b += f'<rect width="1280" height="720" fill="{CREAM}" opacity=".12"/>'
    # profile chip
    b += card(22, 18, 262, 80, 40, PAPER_HI)
    b += f'<g filter="url(#shadowS)"><circle cx="62" cy="58" r="30" fill="#CFE4F2" stroke="{INK}" stroke-width="3"/></g>'
    b += plane(38, 47, 50, hue="hueGreen")
    b += text(104, 50, "Маша", 24, INK, "start")
    b += coin(116, 76, 11) + text(134, 83, "7", 18, INK, "start")
    b += star(172, 76, 11) + text(190, 83, "34", 18, INK, "start")
    # right utilities (grouped)
    b += round_btn(1140, 56, 32, "trophy") + round_btn(1222, 56, 32, "gear")
    # title
    b += title(660, 122, "Улётная математика", 60, "#4E8F3A")
    # mascot + bubble
    b += nulik(300, 430, 1.55, "happy")
    b += bubble(120, 196, 330, 96, ["Ещё 2 полёта —", "и будет золотая!"], (270, 318), 25)
    # continue card (primary)
    b += card(560, 180, 640, 196, 28, PAPER_HI)
    b += f'<g filter="url(#shadowS)"><clipPath id="thumb"><rect x="584" y="204" width="172" height="148" rx="18"/></clipPath>'
    b += f'<g clip-path="url(#thumb)">{image(VALLEY_IMG.format("addition"), 584, 204, 172, 148)}</g>'
    b += f'<rect x="584" y="204" width="172" height="148" rx="18" fill="none" stroke="{INK}" stroke-width="3"/></g>'
    b += text(782, 232, "ПРОДОЛЖИТЬ", 18, INK_SOFT, "start")
    b += text(782, 272, "Долина сложения", 28, VALLEY["addition"][1], "start")
    b += text(782, 310, "Уровень 7 из 17", 22, INK, "start")
    b += star(794, 338, 12, False) + star(824, 338, 12, False) + star(854, 338, 12, False)
    b += f'<g filter="url(#shadow)"><circle cx="1128" cy="278" r="56" fill="{RIM}"/></g>'
    b += f'<g filter="url(#rough)"><circle cx="1128" cy="278" r="50" fill="url(#ctaGreen)" stroke="{INK}" stroke-width="3.5"/></g>'
    b += icon("play", 1133, 278, 40, "#fff")
    # secondary
    b += pill(560, 400, 310, 84, "Карта", "map", False, 30)
    b += pill(890, 400, 310, 84, "Практика", "pencil", False, 30)
    # daily strip
    b += card(560, 516, 640, 150, 24, PAPER_HI, rot=-0.8)
    b += title(740, 562, "Ежедневная серия", 28, INK, False)
    b += text(1060, 560, "3 / 5", 26, INK)
    for i, n in enumerate(["sun", "flower", "cat", "empty", "empty"]):
        b += stamp(630 + i * 92, 614, n, 78, [-8, 4, -5, 0, 0][i])
    b += f'<path d="M1090 614 h26 m-10 -10 l10 10 l-10 10" stroke="{INK}" stroke-width="3" fill="none" stroke-linecap="round"/>'
    b += coin(1146, 606, 24) + text(1146, 652, "+1 золотая", 15, INK)
    # desktop-only exit
    b += round_btn(50, 670, 24, "x", dim=True)
    return svg_doc(b)


def s02_levels_map() -> str:
    b = full_bg(VALLEY_IMG.format("addition"))
    b += '<rect width="1280" height="720" fill="url(#dimTop)"/>'
    pts = [(150, 650), (265, 628), (380, 640), (500, 620), (620, 610), (735, 585), (845, 548),
           (770, 482), (650, 462), (525, 450), (400, 432), (292, 398),
           (380, 336), (500, 318), (620, 304), (740, 290), (880, 232)]
    d = catmull(pts)
    b += f'<path d="{d}" fill="none" stroke="{RIM}" stroke-width="22" stroke-linecap="round" opacity=".85" filter="url(#rough)"/>'
    b += f'<path d="{d}" fill="none" stroke="#9B7A4E" stroke-width="4" stroke-dasharray="4 14" stroke-linecap="round"/>'
    current = 7
    for i, (x, y) in enumerate(pts, start=1):
        if i == 17:
            continue
        done = i < current
        locked = i > current
        r = 27 if i != current else 34
        fill = PAPER_HI if not locked else "#E9E4D8"
        if i == current:
            b += f'<circle cx="{x}" cy="{y}" r="{r + 16}" fill="none" stroke="#fff" stroke-width="5" opacity=".8"/>'
            b += f'<circle cx="{x}" cy="{y}" r="{r + 28}" fill="none" stroke="#fff" stroke-width="3" opacity=".45"/>'
            fill = "url(#ctaGreen)"
        b += f'<g filter="url(#shadow)"><circle cx="{x}" cy="{y}" r="{r + 5}" fill="{RIM}"/></g>'
        b += f'<g filter="url(#rough)"><circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{INK if not locked else "#8E8A80"}" stroke-width="3"/></g>'
        if i == current:
            b += outlined(x, y + 11, str(i), 32, "#fff", GREEN_DARK, 6)
        else:
            b += text(x, y + 9, str(i), 25, INK if not locked else "#8E8A80")
        if done:
            b += stamp(x + 24, y - 26, ["sun", "flower", "cat"][i % 3], 48, -10)
            nst = 3 if i % 3 else 2
            for k in range(3):
                b += star(x - 18 + k * 18, y + r + 12, 8, k < nst)
        if locked:
            b += icon("lock", x + 20, y - 20, 12, "#8E8A80")
    # current marker
    x, y = pts[current - 1]
    b += plane(x + 40, y - 112, 130, hue="hueGreen")
    b += chip_label(x + 105, y - 124, "ТЫ ЗДЕСЬ", 16)
    # exam node
    ex, ey = pts[-1]
    b += f'<g filter="url(#shadow)"><circle cx="{ex}" cy="{ey}" r="52" fill="{RIM}"/></g>'
    b += f'<g filter="url(#rough)"><circle cx="{ex}" cy="{ey}" r="46" fill="#E5DAF3" stroke="#7B55B5" stroke-width="4"/></g>'
    b += f'<path d="M{ex - 34} {ey - 8} L{ex} {ey - 26} L{ex + 34} {ey - 8} L{ex} {ey + 8} Z" fill="{INK}"/><path d="M{ex - 18} {ey} v16 q18 10 36 0 v-16" fill="{INK}"/>'
    b += f'<path d="M{ex + 30} {ey - 9} v22" stroke="{ACCENT}" stroke-width="3"/><circle cx="{ex + 30}" cy="{ey + 14}" r="4" fill="{ACCENT}"/>'
    b += chip_label(ex, ey + 70, "Экзамен", 18)
    b += image(TROPHY.format("addition"), ex + 60, ey - 70, 80, 80, 'filter="url(#graphite)"', "xMidYMid meet")
    # header
    b += torn_banner(640, 52, 460, 78)
    b += title(640, 70, "Долина сложения", 42, VALLEY["addition"][1], False)
    b += chip(540, 102, 200, 40, text(600, 129, "6 / 17", 20) + star(668, 122, 10) + text(700, 129, "16", 20))
    # valley switch
    b += round_btn(1216, 360, 30, "next", "Вычитание")
    b += round_btn(64, 360, 30, "prev", dim=True)
    b += round_btn(60, 664, 32, "back")
    return svg_doc(b)


def s03_battle() -> str:
    b = battle_world()
    b += plane(70, LANES[1] - 44, 240, hue="hueGreen")
    for i, x in enumerate([350, 420, 490]):
        b += f'<circle cx="{x}" cy="{LANES[1] + 4}" r="{7 - i}" fill="#fff" stroke="{INK}" stroke-width="1.5"/>'
    for (y, x, f, n) in zip(LANES, [1030, 1090, 1000, 1120], [0, 2, 6, 3], [54, 56, 48, 63]):
        b += balloon(x, y - 6, f, n, 118)
    # pop feedback from previous hit
    b += confetti(300, 190, 70, 14, 3)
    b += outlined(300, 200, "+1", 38, "#8CC063", INK, 6)
    b += hud([("7", "#4A86C0"), (" ", ""), ("×", "#8A62B8"), (" ", ""), ("8", "#E08A3C"), (" ", ""), ("=", INK), (" ", ""), ("?", HEART)])
    return svg_doc(b)


def s04_battle_mistake() -> str:
    b = battle_world()
    b += f'<rect width="1280" height="720" fill="{CREAM}" opacity=".18"/>'
    b += plane(70, LANES[0] - 44, 240, hue="hueGreen")
    # wrong balloon bursting into ink
    b += ink_blot(1030, LANES[0] - 6, 52)
    b += outlined(1030, LANES[0] + 10, "54", 44, "#fff", INK, 6)
    b += f'<path d="M1080 {LANES[0] - 60} l30 -30 m0 30 l-30 -30" stroke="{LOSE}" stroke-width="7" stroke-linecap="round"/>'
    # correct balloon highlighted
    cx, cy = 1090, LANES[1] - 6
    b += f'<circle cx="{cx}" cy="{cy}" r="96" fill="{ACCENT}" opacity=".28" filter="url(#soft)"/>'
    b += f'<circle cx="{cx}" cy="{cy}" r="84" fill="none" stroke="{ACCENT}" stroke-width="6" stroke-dasharray="14 10"/>'
    b += balloon(cx, cy, 2, 56, 124)
    for sx, sy, r in [(1000, cy - 70, 14), (1180, cy - 50, 11), (1175, cy + 60, 9)]:
        b += sparkle(sx, sy, r)
    b += f'<g filter="url(#sticker)"><circle cx="{cx + 62}" cy="{cy - 58}" r="22" fill="#8CC063" stroke="{INK}" stroke-width="3"/></g>' + icon("check", cx + 62, cy - 58, 14, "#fff")
    b += balloon(1000, LANES[2] - 6, 6, 48, 118, .35) + balloon(1120, LANES[3] - 6, 3, 63, 118, .35)
    # hud: answer revealed in banner
    b += hud([("7", "#4A86C0"), (" ", ""), ("×", "#8A62B8"), (" ", ""), ("8", "#E08A3C"), (" ", ""), ("=", INK), (" ", ""), ("5", WIN), ("6", WIN)],
             hearts=(True, False, False), combo=False)
    b += heart(1148, 58, 20, True, cracked=True)
    # mascot tip
    b += nulik(170, 600, 1.0, "think")
    b += bubble(260, 470, 420, 92, ["7 × 8 = 56.", "Я запомню — повторим ещё!"], (230, 560), 24)
    return svg_doc(b)


def s05_exam_boss() -> str:
    b = full_bg(VALLEY_IMG.format("multiplication"))
    b += '<rect width="1280" height="720" fill="url(#dimTop)"/>'
    for y in [150, 287, 424, 561, 698]:
        b += f'<g filter="url(#rough)"><rect x="-10" y="{y - 3}" width="1300" height="6" rx="3" fill="#fff" opacity=".45"/></g>'
    # airship
    ax, ay = 1040, 262
    b += '<g filter="url(#stickerBig)">'
    b += f'<path d="M{ax + 190} {ay - 20} l44 -48 l8 56 Z M{ax + 190} {ay + 20} l44 48 l8 -56 Z" fill="#C9A77A" stroke="{INK}" stroke-width="3"/>'
    b += f'<ellipse cx="{ax}" cy="{ay}" rx="200" ry="92" fill="#E7D3AE" stroke="{INK}" stroke-width="3.5"/>'
    b += "</g>"
    b += f'<ellipse cx="{ax}" cy="{ay}" rx="200" ry="92" fill="url(#hatch)"/>'
    for k in range(-3, 4):
        b += f'<path d="M{ax + k * 52} {ay - 90 + abs(k) * 7} Q{ax + k * 62} {ay} {ax + k * 52} {ay + 90 - abs(k) * 7}" fill="none" stroke="{INK}" stroke-width="1.6" opacity=".5"/>'
    # armor plates on the hull
    for k in range(10):
        px = ax - 160 + k * 32
        on = k >= 4
        b += f'<rect x="{px}" y="{ay - 20}" width="26" height="36" rx="6" fill="{"#8FA4B8" if on else "none"}" stroke="{INK}" stroke-width="{2.5 if on else 1.5}" stroke-dasharray="{"0" if on else "5 4"}" opacity="{1 if on else .5}"/>'
    b += f'<g filter="url(#sticker)"><rect x="{ax - 100}" y="{ay + 100}" width="200" height="56" rx="10" fill="#B98E5A" stroke="{INK}" stroke-width="3"/></g>'
    b += f'<path d="M{ax - 70} {ay + 100} L{ax - 100} {ay + 76} M{ax + 70} {ay + 100} L{ax + 100} {ay + 76}" stroke="{INK}" stroke-width="2.5"/>'
    b += text(ax, ay + 138, "ЭКЗАМЕН", 26, "#FFF6DD")
    # tethered balloons
    for (y, f, n) in zip(LANES, [1, 4, 7, 11], [84, 72, 96, 74]):
        bx = 690 + (y % 3) * 24
        b += f'<path d="M{bx + 30} {y + 44} Q{bx + 150} {y + 30} {ax - 60} {ay + 128}" fill="none" stroke="#A88A5C" stroke-width="2.5" opacity=".8"/>'
        b += balloon(bx, y - 6, f, n, 112)
    b += plane(60, LANES[2] - 44, 240, hue="hueRed")
    for i, x in enumerate([340, 410]):
        b += f'<circle cx="{x}" cy="{LANES[2] + 4}" r="{7 - i}" fill="#fff" stroke="{INK}" stroke-width="1.5"/>'
    b += hud([("1", "#4A86C0"), ("2", "#4A86C0"), (" ", ""), ("×", "#8A62B8"), (" ", ""), ("7", "#E08A3C"), (" ", ""), ("=", INK), (" ", ""), ("?", HEART)],
             score="6 / 10", combo=False, progress=None, banner_w=560)
    b += chip(470, 116, 340, 40, text(640, 143, "Броня дирижабля: 6 / 10", 20))
    return svg_doc(b)


def s06_post_win() -> str:
    b = full_bg(VALLEY_IMG.format("addition"))
    b += f'<rect width="1280" height="720" fill="{INK}" opacity=".12"/>'
    b += confetti(640, 90, 420, 40, 7)
    b += card(330, 96, 620, 520, 34, PAPER_HI)
    b += title(640, 178, "Победный полёт!", 58, WIN)
    b += text(640, 232, "12 / 12  ·  Долина сложения, уровень 7", 24, INK)
    for i, (n, r) in enumerate([("sun", -9), ("flower", 5), ("cat", 11)]):
        x = 470 + i * 170
        b += f'<g opacity=".5">{ink_blot(x + 36, 330 + 38, 10, i + 20)}</g>'
        b += stamp(x, 330, n, 142, r)
    b += chip(372, 432, 170, 56, coin(404, 460, 18) + text(470, 470, "+2", 28))
    b += chip(556, 432, 210, 56, stamp(590, 460, "cat", 36) + text(684, 469, "Серия 4 / 5", 22))
    b += chip(780, 432, 150, 56, icon("clock", 808, 460, 20) + text(872, 469, "0:58", 24))
    b += chip_label(855, 422, "рекорд!", 15)
    # sticky note: tricky facts
    b += f'<g transform="rotate(5 1070 380)"><g filter="url(#shadow)"><rect x="960" y="290" width="220" height="190" fill="#F8E27A" stroke="{INK}" stroke-width="2"/></g>'
    b += tape(1070, 292, 100, 26, -4)
    b += text(1070, 336, "Трудные примеры", 20, INK)
    b += text(1070, 376, "8 + 7 = 15", 26, INK)
    b += text(1070, 414, "9 + 6 = 15", 26, INK)
    b += text(1070, 456, "▶ потренировать", 18, WIN) + "</g>"
    b += nulik(190, 520, 1.35, "cheer")
    b += round_btn(520, 614, 36, "back") + round_btn(624, 614, 36, "restart")
    b += f'<g filter="url(#shadow)"><circle cx="752" cy="610" r="52" fill="{RIM}"/></g>'
    b += f'<g filter="url(#rough)"><circle cx="752" cy="610" r="46" fill="url(#ctaGreen)" stroke="{INK}" stroke-width="3.5"/></g>'
    b += icon("next", 752, 610, 30, "#fff")
    return svg_doc(b)


def s07_post_lose() -> str:
    b = full_bg(VALLEY_IMG.format("subtraction"))
    b += f'<rect width="1280" height="720" fill="{INK}" opacity=".16"/>'
    b += card(330, 96, 620, 520, 34, PAPER_HI)
    b += title(640, 178, "Почти получилось!", 54, WARM)
    b += text(640, 232, "8 / 12 — ещё 4 примера до победы", 24, INK)
    b += progress_strip(430, 262, 400, 12, 8, marker=True)
    for i in range(3):
        b += stamp(480 + i * 160, 372, "empty", 110)
    b += text(640, 378, "штампы ждут тебя", 18, INK_SOFT)
    b += chip(420, 450, 440, 50, text(640, 483, "Твой лучший результат: 9 / 12", 22))
    b += f'<g transform="rotate(-4 1080 380)"><g filter="url(#shadow)"><rect x="970" y="280" width="220" height="210" fill="#BFE1F2" stroke="{INK}" stroke-width="2"/></g>'
    b += tape(1080, 282, 100, 26, 5)
    b += text(1080, 326, "Запомним:", 20, INK)
    b += text(1080, 368, "13 − 5 = 8", 26, WIN)
    b += text(1080, 406, "12 − 7 = 5", 26, WIN)
    b += text(1080, 444, "15 − 9 = 6", 26, WIN) + "</g>"
    b += nulik(186, 520, 1.3, "happy")
    b += bubble(64, 250, 260, 110, ["Ты уже лучше,", "чем вчера!"], (180, 420), 23)
    b += round_btn(470, 616, 36, "back")
    b += pill(560, 578, 280, 76, "Ещё раз", "restart", True, 32)
    return svg_doc(b)


def s08_profile() -> str:
    b = full_bg(BG_HANGAR)
    b += f'<rect width="1280" height="720" fill="{CREAM}" opacity=".35"/>'
    b += title(640, 70, "Пилоты", 52, INK)
    # pilot licence
    b += f'<g transform="rotate(-1.5 400 370)">'
    b += card(80, 110, 640, 500, 26, PAPER_HI)
    b += f'<rect x="86" y="116" width="628" height="58" rx="20" fill="#4A86C0"/><rect x="86" y="150" width="628" height="24" fill="#4A86C0"/>'
    b += text(400, 154, "УДОСТОВЕРЕНИЕ ПИЛОТА № 1", 24, "#fff")
    b += f'<g filter="url(#shadowS)"><rect x="118" y="198" width="190" height="220" fill="#fff" stroke="{INK}" stroke-width="2"/></g>'
    b += f'<rect x="130" y="210" width="166" height="170" fill="#CFE4F2"/>'
    b += nulik(213, 318, .95, "happy")
    b += tape(213, 200, 90, 24, -6)
    b += text(213, 406, "фото", 16, INK_SOFT)
    b += text(340, 230, "Имя", 17, INK_SOFT, "start") + text(340, 266, "Маша", 36, INK, "start")
    b += round_btn(640, 250, 22, "edit")
    b += text(340, 306, "Возраст", 17, INK_SOFT, "start") + text(340, 338, "8 лет · Долины: обычные", 22, INK, "start")
    b += text(340, 378, "Звание", 17, INK_SOFT, "start")
    b += chip(340, 388, 210, 42, icon("star", 366, 409, 18) + text(460, 417, "Штурман", 22))
    b += chip(120, 440, 130, 50, coin(150, 465, 16) + text(206, 474, "7", 26))
    b += chip(262, 440, 130, 50, star(292, 465, 16) + text(348, 474, "34", 26))
    b += chip(404, 440, 150, 50, icon("trophy", 432, 465, 22) + text(498, 474, "1 / 5", 24))
    # equipped plane strip
    b += f'<g filter="url(#rough)">{rrect(120, 508, 560, 84, 18, "#EEF5E6", INK, 2.5)}</g>'
    b += plane(134, 518, 170, hue="hueGreen")
    b += text(330, 545, "Зелёный стриж", 24, INK, "start")
    b += text(330, 575, "Сменить в ангаре →", 19, WIN, "start")
    b += stamp(640, 540, "star", 92, 14, .9)
    b += "</g>"
    # slots
    slots = [("Маша", "hueGreen", True), ("Петя", "hueRed", False), (None, None, False), (None, None, False)]
    for i, (name, hue, sel) in enumerate(slots):
        x = 790 + (i % 2) * 215
        y = 120 + (i // 2) * 250
        rot = [-3, 2, 1.5, -2][i]
        b += f'<g transform="rotate({rot} {x + 95} {y + 110})">'
        if name:
            b += f'<g filter="url(#shadow)"><rect x="{x}" y="{y}" width="190" height="220" fill="#fff" stroke="{INK}" stroke-width="2"/></g>'
            b += f'<rect x="{x + 12}" y="{y + 12}" width="166" height="150" fill="{"#CFE4F2" if sel else "#F6D9C9"}"/>'
            b += nulik(x + 95, y + 100, .7, "happy" if sel else "think")
            b += text(x + 95, y + 198, name, 26, INK)
            b += tape(x + 95, y + 2, 80, 22, rot * 2)
            if sel:
                b += f'<g filter="url(#sticker)"><circle cx="{x + 172}" cy="{y + 18}" r="22" fill="#8CC063" stroke="{INK}" stroke-width="3"/></g>' + icon("check", x + 172, y + 18, 14, "#fff")
        else:
            b += f'<rect x="{x}" y="{y}" width="190" height="220" rx="8" fill="{PAPER_HI}" opacity=".7" stroke="{INK_SOFT}" stroke-width="3" stroke-dasharray="12 9"/>'
            if i == 2:
                b += icon("plus", x + 95, y + 96, 40, INK_SOFT) + text(x + 95, y + 176, "Новый пилот", 21, INK_SOFT)
        b += "</g>"
    b += round_btn(60, 664, 32, "back")
    return svg_doc(b)


def s09_hangar() -> str:
    b = full_bg(BG_HANGAR)
    b += f'<ellipse cx="560" cy="470" rx="380" ry="190" fill="#FFF6DD" opacity=".55" filter="url(#soft)"/>'
    b += title(640, 70, "Ангар", 54, INK)
    b += chip(1080, 26, 150, 52, coin(1112, 52, 18) + text(1176, 62, "7", 28))
    # stage
    b += f'<ellipse cx="520" cy="440" rx="250" ry="46" fill="#C7A576" stroke="{INK}" stroke-width="3" filter="url(#shadow)"/>'
    b += f'<ellipse cx="520" cy="432" rx="232" ry="36" fill="#DEC293" stroke="{INK}" stroke-width="2" opacity=".9"/>'
    b += f'<ellipse cx="520" cy="430" rx="150" ry="16" fill="{INK}" opacity=".18"/>'
    b += plane(290, 240, 460, hue="hueGreen")
    for sx, sy in [(300, 230), (760, 260), (720, 400)]:
        b += sparkle(sx, sy, 12)
    b += torn_banner(520, 510, 330, 62)
    b += text(520, 522, "Зелёный стриж", 32, INK)
    b += pill(390, 556, 260, 70, "Купить · 5", None, True, 30)
    b += coin(628, 591, 14)
    b += text(520, 648, "или сдай экзамен «Вычитание»", 18, INK_SOFT)
    # stats card
    b += card(860, 130, 360, 330, 24, PAPER_HI, rot=1.5)
    b += text(1040, 176, "Характеристики", 24, INK)
    rows = [("Скорость", 4), ("Разворот", 3)]
    for i, (n, v) in enumerate(rows):
        y = 222 + i * 52
        b += text(890, y, n, 21, INK, "start")
        for k in range(5):
            b += f'<g filter="url(#rough)"><rect x="{1010 + k * 36}" y="{y - 22}" width="28" height="26" rx="6" fill="{"#8CC063" if k < v else "#EFE6D2"}" stroke="{INK}" stroke-width="2"/></g>'
    b += text(890, 340, "Взрыв", 21, INK, "start")
    b += chip(1010, 312, 170, 40, text(1095, 339, "1 полоса", 20), fill="#FBE3C5")
    b += text(890, 400, "Подсказка", 21, INK, "start")
    b += chip(1010, 372, 170, 40, text(1095, 399, "нет", 20, INK_SOFT))
    b += text(1040, 440, "у Красного — есть", 16, INK_SOFT)
    # thumbnails
    thumbs = [("hue", None, "свой", True), ("hue", None, "свой", True), ("hueGreen", "5", "", False),
              ("hueRed", "10", "", False), ("hueGold", "20", "", False)]
    names = ["Стартовый", "Быстрый", "Зелёный", "Красный", "Золотой"]
    for i, (hue, price, own, owned) in enumerate(thumbs):
        x, y = 870 + (i % 3) * 120 - (0 if i < 3 else -60), 490 + (i // 3) * 110
        sel = i == 2
        b += f'<g filter="url(#shadowS)"><g filter="url(#rough)">{rrect(x, y, 108, 96, 16, "#EEF5E6" if sel else PAPER_HI, "#6FAE4A" if sel else INK, 4 if sel else 2.5)}</g></g>'
        locked = i >= 3
        b += plane(x + 10, y + 16, 88, row=[1, 0, 0, 2, 0][i], hue=hue if hue != "hue" else None, graphite=locked,
                   op=1 if not locked else .9)
        if i == 0:
            b += f'<g opacity=".0"></g>'
        if owned:
            b += f'<g filter="url(#sticker)"><circle cx="{x + 94}" cy="{y + 14}" r="13" fill="#8CC063" stroke="{INK}" stroke-width="2"/></g>' + icon("check", x + 94, y + 14, 8, "#fff")
        if price and i != 2:
            b += icon("lock", x + 94, y + 16, 12)
        b += text(x + 54, y + 84, names[i], 15, INK)
    b += round_btn(60, 664, 32, "back")
    return svg_doc(b)


def s10_pause_settings() -> str:
    b = battle_world()
    b += plane(70, LANES[1] - 44, 240, hue="hueGreen")
    for (y, x, f, n) in zip(LANES, [1030, 1090, 1000, 1120], [0, 2, 6, 3], [54, 56, 48, 63]):
        b += balloon(x, y - 6, f, n, 118)
    b += hud([("7", "#4A86C0"), (" ", ""), ("×", "#8A62B8"), (" ", ""), ("8", "#E08A3C"), (" ", ""), ("=", INK), (" ", ""), ("?", HEART)], combo=False)
    b += f'<rect width="1280" height="720" fill="{INK}" opacity=".5"/>'
    b += card(250, 84, 780, 560, 30, PAPER_HI)
    for i in range(11):
        x = 300 + i * 68
        b += f'<circle cx="{x}" cy="106" r="9" fill="#D8C9A6" stroke="{INK}" stroke-width="1.5"/><path d="M{x} 74 q-12 16 0 32" fill="none" stroke="#8E949C" stroke-width="5" stroke-linecap="round"/>'
    b += title(640, 176, "Пауза", 54, INK)
    b += pill(300, 222, 330, 84, "Продолжить", "play", True, 32)
    b += pill(300, 330, 330, 76, "Заново", "restart", False, 28)
    b += pill(300, 428, 330, 76, "В меню", "home", False, 28)
    # toggles
    tg = [("music", "Музыка", True), ("sound", "Звуки", True), ("vibrate", "Вибрация", False)]
    for i, (ic, n, on) in enumerate(tg):
        x = 690 + i * 105
        b += f'<g filter="url(#shadowS)"><g filter="url(#rough)">{rrect(x, 222, 90, 90, 20, "#EEF5E6" if on else "#E9E4D8", INK, 2.5)}</g></g>'
        b += icon(ic, x + 45, 262, 26, INK if on else "#8E8A80")
        if on:
            b += f'<g filter="url(#sticker)"><circle cx="{x + 82}" cy="230" r="14" fill="#8CC063" stroke="{INK}" stroke-width="2"/></g>' + icon("check", x + 82, 230, 8, "#fff")
        else:
            b += f'<path d="M{x + 18} {238} L{x + 72} {292}" stroke="{LOSE}" stroke-width="5" stroke-linecap="round"/>'
        b += text(x + 45, 336, n, 18, INK)
    b += text(845, 390, "Управление", 22, INK)
    for i, (n, ic, sel) in enumerate([("Пальцем", "hand", True), ("Кнопками", "arrows_ud", False)]):
        x = 690 + i * 160
        b += f'<g filter="url(#shadowS)"><g filter="url(#rough)">{rrect(x, 408, 146, 110, 20, "#EEF5E6" if sel else PAPER_HI, "#6FAE4A" if sel else INK, 4 if sel else 2.5)}</g></g>'
        b += icon(ic, x + 73, 452, 30)
        b += text(x + 73, 504, n, 19, INK)
    b += text(640, 596, "Музыка/звук/вибрация — только тут и в Настройках, из HUD боя убраны", 17, INK_SOFT)
    return svg_doc(b)


def s11_tutorial() -> str:
    b = battle_world()
    py = LANES[2]
    b += plane(70, py - 44, 240)
    for (y, x, f, n) in zip(LANES, [1040, 1070, 1020, 1100], [0, 2, 6, 3], [4, 5, 6, 3]):
        b += balloon(x, y - 6, f, n, 118)
    b += hud([("2", "#4A86C0"), (" ", ""), ("+", "#8A62B8"), (" ", ""), ("3", "#E08A3C"), (" ", ""), ("=", INK), (" ", ""), ("?", HEART)],
             score="0 / 3", hearts=(True, True, True), combo=False, progress=(3, 0))
    # spotlight
    b += (f'<mask id="spot"><rect width="1280" height="720" fill="#fff"/>'
          f'<g filter="url(#soft)"><ellipse cx="190" cy="{py}" rx="170" ry="110" fill="#000"/>'
          f'<circle cx="1070" cy="{LANES[1] - 6}" r="98" fill="#000"/><rect x="380" y="10" width="520" height="104" rx="30" fill="#000"/></g></mask>'
          f'<rect width="1280" height="720" fill="{INK}" opacity=".55" mask="url(#spot)"/>')
    b += f'<path d="M330 {py - 30} C560 {py - 90} 820 {LANES[1] + 40} 960 {LANES[1]}" fill="none" stroke="#fff" stroke-width="6" stroke-dasharray="16 12" stroke-linecap="round"/>'
    b += f'<path d="M944 {LANES[1] - 16} L972 {LANES[1] - 1} L946 {LANES[1] + 18}" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
    # hand gesture
    b += f'<path d="M190 {py - 150} V{py - 80} M170 {py - 130} l20 -20 l20 20" stroke="#fff" stroke-width="5" fill="none" stroke-linecap="round"/>'
    b += '<g filter="url(#shadow)">' + icon("hand", 250, py + 40, 70) + "</g>"
    # coach
    b += nulik(600, 606, 1.0, "point")
    b += bubble(390, 394, 460, 116, ["Веди самолёт к шарику", "с правильным ответом", "и стреляй!"], (590, 530), 25)
    b += chip(700, 640, 470, 44, text(935, 669, "Клавиатура: ↑ ↓ — лететь, Пробел — выстрел", 18))
    b += chip(40, 640, 150, 44, text(115, 669, "Шаг 1 / 3", 20))
    return svg_doc(b)


SCREENS = {
    "00_style_board": s00_style_board,
    "01_menu": s01_menu,
    "02_levels_map": s02_levels_map,
    "03_battle": s03_battle,
    "04_battle_mistake": s04_battle_mistake,
    "05_exam_boss": s05_exam_boss,
    "06_post_battle_win": s06_post_win,
    "07_post_battle_lose": s07_post_lose,
    "08_profile": s08_profile,
    "09_hangar": s09_hangar,
    "10_pause_settings": s10_pause_settings,
    "11_first_battle_tutorial": s11_tutorial,
}


def find_chrome() -> str:
    for c in CHROME_CANDIDATES:
        if pathlib.Path(c).exists() or shutil.which(c):
            return c
    sys.exit("Chrome/Edge not found")


def render(name: str, svg: str, chrome: str, tmp: pathlib.Path) -> pathlib.Path:
    html = tmp / f"{name}.html"
    html.write_text(html_doc(svg), encoding="utf-8")
    out = HERE / f"{name}.png"
    subprocess.run([
        chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
        f"--force-device-scale-factor={SCALE}", "--window-size=1280,720", "--virtual-time-budget=4000",
        f"--screenshot={out}", html.as_uri(),
    ], check=True, capture_output=True, timeout=120)
    return out


def contact_sheet(paths: list[pathlib.Path]) -> None:
    from PIL import Image, ImageDraw

    tw, th, pad, cols = 480, 270, 16, 3
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + pad + 28) + pad), CREAM)
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGB").resize((tw, th), Image.LANCZOS)
        x = pad + (i % cols) * (tw + pad)
        y = pad + (i // cols) * (th + pad + 28)
        sheet.paste(im, (x, y + 24))
        d.text((x, y + 4), p.stem, fill=INK)
    sheet.save(HERE / "_overview.png", optimize=True)


def main() -> None:
    names = sys.argv[1:] or list(SCREENS)
    chrome = find_chrome()
    with tempfile.TemporaryDirectory() as t:
        tmp = pathlib.Path(t)
        for n in names:
            print("render", n)
            render(n, SCREENS[n](), chrome, tmp)
    contact_sheet([HERE / f"{n}.png" for n in SCREENS if (HERE / f"{n}.png").exists()])


if __name__ == "__main__":
    main()
