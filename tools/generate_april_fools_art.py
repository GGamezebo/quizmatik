"""April Fools boss/gift kit and watercolor menu banner. Pillow/numpy + Godot CLI; only writes April art. Background and atlas PNGs are curated ImageGen assets.

python tools/generate_april_fools_art.py [banner]
"""
from pathlib import Path
import subprocess
import sys
from generate_new_year_art import svg, write

ROOT = Path(__file__).resolve().parents[1]
EVENT = 'src/common/events/april_fools'
INK = '#354556'
COLORS = ['#d46e66', '#d99a60', '#d9bd68', '#87ad69', '#62a48a', '#66b2af', '#6b9dbb', '#758ec0', '#9586b7', '#b186b6', '#cd85a1', '#cf8b7e', '#b6ab88', '#7bb7ba', '#a58ebf']


def eyes(x, y, scale=1):
    return f'<g transform="translate({x} {y}) scale({scale})" stroke="{INK}" stroke-width="2"><ellipse cx="-10" cy="0" rx="9" ry="11" fill="#fff8e8"/><ellipse cx="10" cy="-3" rx="9" ry="11" fill="#fff8e8"/><circle cx="-7" cy="3" r="4" fill="{INK}"/><circle cx="7" cy="-3" r="4" fill="{INK}"/></g>'


def moustache(x, y, scale=1, color=INK):
    return f'<path transform="translate({x} {y}) scale({scale})" d="M0 0C-8 -17 -18 8 -33 -6C-31 16 -8 17 0 6C8 17 31 16 33 -6C18 8 8 -17 0 0Z" fill="{color}"/>'


def umbrella(x, y, scale=1):
    return f'<g transform="translate({x} {y}) scale({scale})" stroke="{INK}" stroke-width="3" stroke-linejoin="round"><path d="M-55 0Q0 -77 55 0Q35 -12 20 0Q0 -13 -20 0Q-35 -12 -55 0Z" fill="#d1848e"/><path d="M-20 0Q0 -70 20 0Q0 -13 -20 0" fill="#ecd298"/><path d="M0 -44V38Q0 57 17 45" fill="none" stroke-linecap="round"/></g>'



def boss():
    body = (ROOT / 'src/features/boss/art/airship_body.svg').read_text(encoding='utf-8')
    for a, b in {'#8C97AD':'#B09ABD', '#66718A':'#927C9E', '#46506A':'#786780', '#B5BFD1':'#E0CADD', '#C65A4C':'#D4AE6B', '#B44F43':'#C39758'}.items():
        body = body.replace(a, b)
    # Glasses, unmistakable red nose and moustache; preserve all boss anchors.
    decor = '<g fill="none" stroke="#354556" stroke-width="6"><circle cx="84" cy="108" r="22"/><circle cx="126" cy="104" r="22"/><path d="M105 104h1 M61 103L45 95"/></g><circle cx="61" cy="130" r="19" fill="#cc706b" stroke="#fff1da" stroke-width="4"/><circle cx="56" cy="124" r="5" fill="#f5b6a3"/>'
    decor += moustache(97, 147, .95)
    decor += '<path d="M157 51L173 9L204 35L233 6L252 40L288 20L279 57Z" fill="#d3af6f" stroke="#fff6df" stroke-width="8" stroke-linejoin="round"/><path d="M157 51L173 9L204 35L233 6L252 40L288 20L279 57Z" fill="#d3af6f" stroke="#354556" stroke-width="3"/><path d="M204 35L233 6L252 40L231 53Z" fill="#c8888d"/>'
    for x, y in [(173, 9), (233, 6), (288, 20)]:
        decor += f'<circle cx="{x}" cy="{y}" r="6" fill="#fff0cf" stroke="#354556" stroke-width="2"/>'
    decor += '<path d="M330 80l17 25l-17 25l-17 -25Z M375 120l17 25l-17 25l-17 -25Z" fill="#eed8a5" stroke="#7c6988" stroke-width="2"/>'
    body = body.replace('</svg>', decor + '</svg>')
    write('src/features/boss/art/april_fools_airship_body.svg', body)
    for name, color, shade in [('mint', '#8eb6a8', '#719b90'), ('peach', '#d0a28b', '#b78672')]:
        write(f'src/features/boss/art/variants/april_fools_{name}.svg', body.replace('#B09ABD', color).replace('#927C9E', shade))
    plate = '<path d="M14 16Q50 4 86 16L90 58Q50 70 10 58Z" fill="#d4b674" stroke="#fff6df" stroke-width="12"/><path d="M14 16Q50 4 86 16L90 58Q50 70 10 58Z" fill="#d4b674" stroke="#354556" stroke-width="3"/>' + eyes(50, 31, .7) + moustache(50, 47, .6)
    write('src/features/boss/art/april_fools_armor_plate.svg', svg(100, 76, plate))


def gifts():
    symbols = {
        'fish': '<path d="M12 32Q32 5 50 32Q32 59 12 32L2 19V45Z" fill="white"/><circle cx="39" cy="27" r="3" fill="#000"/>',
        'face': '<circle cx="32" cy="32" r="28" fill="none" stroke="white" stroke-width="4"/><circle cx="23" cy="24" r="5" fill="white"/><circle cx="42" cy="21" r="5" fill="white"/><path d="M16 38Q32 62 49 36" fill="none" stroke="white" stroke-width="5" stroke-linecap="round"/>',
        'pie': '<path d="M7 39Q32 64 57 39Z" fill="white"/><path d="M7 36Q2 24 16 24Q12 12 27 16Q34 1 42 18Q59 15 55 29Q67 36 57 39H7Z" fill="white"/>',
        'duck': '<path d="M8 35Q20 47 31 32Q27 7 43 8Q61 8 54 28L63 32L53 36Q55 58 28 58Q4 57 8 35Z" fill="white"/><circle cx="46" cy="19" r="3" fill="black"/>',
        'confetti': '<path d="M7 4h10v13H7Z M38 8l12 6l-5 10l-12 -6Z M19 35l9 -6l7 11l-9 6Z M45 43h12v11H45Z M3 52l8 -5l4 8l-8 5Z" fill="white"/>',
        'diamond': '<path d="M32 4L51 32L32 60L13 32Z" fill="white"/>',
    }
    for name, shape in symbols.items():
        write(f'{EVENT}/{name}.svg', svg(64, 64, shape))
    # Existing paper box silhouette; jack-in-the-box face replaces the winter emblem.
    for opened in [False, True]:
        text = (ROOT / f'src/common/events/new_year/box_{"open" if opened else "closed"}.svg').read_text(encoding='utf-8')
        # Drop snowflake groups; replace them with silly eyes on the front.
        import re
        text = re.sub(r'<g fill="none" stroke="#[^"]+" stroke-width="[^"]+" stroke-linecap="round">.*?</g>', '', text)
        text = text.replace('#578d7b', '#a28ab5').replace('#b86866', '#759d9c').replace('#cd7f77', '#99c0b5')
        text = text.replace('</svg>', eyes(111, 108, .65) + moustache(110, 126, .4) + '</svg>')
        if opened:
            text = text.replace('</svg>', '<path d="M80 80l-9 -7l13 -7l-12 -7" fill="none" stroke="#dfbb74" stroke-width="3"/>' + '</svg>')
        write(f'{EVENT}/box_{"open" if opened else "closed"}.svg', text)


def banner():
    import numpy as np
    from PIL import Image
    from generate_halloween_art import cta_frame
    raw = ROOT / 'bin/april_banner_art.png'
    raw.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['godot_console', '--headless', '--path', str(ROOT), '--log-file', str(ROOT / 'bin/april_banner_render.log'), '--script', 'tools/pack_april_watercolor.gd', '--', 'banner'], check=True, shell=sys.platform == 'win32')
    art = np.asarray(Image.open(raw).convert('RGB'), dtype=float) / 255
    frame, inside = cta_frame(1344, 320, 2)
    rgb = frame[..., :3] * (1-inside[..., None]) + art * inside[..., None]
    Image.fromarray((np.dstack([rgb, frame[..., 3]]) * 255).astype(np.uint8)).save(ROOT / EVENT / 'banner.png')


if __name__ == '__main__':
    if 'banner' not in sys.argv[1:]:
        boss()
        gifts()
    banner()
    print('April Fools paper-sticker art generated.')
