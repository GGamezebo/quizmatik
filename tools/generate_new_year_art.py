"""Deterministic New Year art kit; run from any directory (Pillow, numpy, Godot CLI).

Keeps the existing answer atlas, boss anchors and BackgroundBase contracts.
Only writes New Year art; `banner` rebuilds the gift/banner kit with the menu CTA frame.
"""
from pathlib import Path
import random
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
EVENT = 'src/common/events/new_year'
INK = '#354556'


def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n'


def write(path, content):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding='utf-8')


def snowflake(x=32, y=32, size=24, color='white'):
    arms = ''.join(f'<path transform="rotate({a} {x} {y})" d="M{x} {y} v{-size} m0 {size*.28} l{-size*.23} {-size*.2} m{size*.23} {size*.2} l{size*.23} {-size*.2}"/>' for a in range(0, 360, 60))
    return f'<g fill="none" stroke="{color}" stroke-width="{size*.12}" stroke-linecap="round">{arms}</g>'


def tree(x, y, scale=1, decorated=False):
    lights = ''
    if decorated:
        for px, py, c in [(0, 30, '#e7bd69'), (-18, 62, '#d77b79'), (15, 76, '#f2d49a'), (-28, 105, '#f4cf78'), (26, 116, '#d77b79')]:
            lights += f'<circle cx="{px}" cy="{py}" r="4.5" fill="{c}" stroke="#fff5df" stroke-width="1.5"/>'
        lights += '<path d="M0 -12 L4 -3 L14 -3 L6 3 L9 13 L0 7 L-9 13 L-6 3 L-14 -3 L-4 -3Z" fill="#edcc80" stroke="#fff3cf" stroke-width="2"/>'
    return f'<g transform="translate({x} {y}) scale({scale})"><path d="M-6 125 H6 V153 H-6Z" fill="#927866"/><path d="M0 0 L-28 52 H-17 L-44 94 H-30 L-59 139 Q0 148 59 139 L30 94 H44 L17 52 H28Z" fill="#527e78" stroke="#3f6565" stroke-width="2" stroke-linejoin="round"/><path d="M0 0 L-28 52 Q0 40 28 52Z M-17 52 L-44 94 Q0 80 44 94 L17 52 Q0 63 -17 52Z M-30 94 L-59 139 Q0 122 59 139 L30 94 Q0 106 -30 94Z" fill="#e6efdf" opacity=".85"/>{lights}</g>'


def background():
    rng = random.Random(20261225)
    body = '<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#66859d"/><stop offset=".65" stop-color="#b8ced1"/><stop offset="1" stop-color="#f1e9d8"/></linearGradient><pattern id="grain" width="17" height="19" patternUnits="userSpaceOnUse"><path d="M2 9l5 -2 M11 16l3 -1" stroke="#fff9e9" stroke-width=".7" opacity=".17"/></pattern></defs><path fill="url(#sky)" d="M0 0H1080V720H0Z"/>'
    body += '<circle cx="650" cy="147" r="61" fill="#f6edce" opacity=".85"/><circle cx="635" cy="130" r="8" fill="#e3d9be" opacity=".5"/>'
    for _ in range(115):
        x, y = rng.randrange(1080), rng.randrange(520)
        body += f'<circle cx="{x}" cy="{y}" r="{rng.choice([1, 1.5, 2.3])}" fill="#fff7e2" opacity=".7"/>'
    body += '<path d="M0 492 Q150 440 300 485 T600 480 T900 483 T1200 485 V720H0Z" fill="#aac5c3"/><path d="M0 557 Q210 489 430 549 T820 533 T1080 552 V720H0Z" fill="#e0e6d9"/>'
    for x, y, s in [(10, 418, .7), (110, 452, .5), (224, 431, .65), (875, 420, .75), (974, 450, .6), (1060, 417, .72)]:
        body += tree(x, y, s)
    # Village and one decorated tree are central, so mirroring has quiet edges.
    for x, y, scale, color in [(360, 480, .75, '#a97976'), (700, 500, .68, '#8196a0'), (795, 505, .5, '#b69b7d')]:
        body += f'<g transform="translate({x} {y}) scale({scale})"><path d="M-66 0H66V94H-66Z" fill="{color}" stroke="#586774" stroke-width="3"/><path d="M-84 8 L0 -65 L84 8Z" fill="#f6f0df" stroke="#768f98" stroke-width="3"/><path d="M-45 27h26v30h-26z M19 27h26v30H19Z" fill="#f6d78d" stroke="#f5ecdb" stroke-width="4"/><path d="M-7 54H9V94H-7Z" fill="#5a6a73"/></g>'
    body += tree(548, 367, 1.5, True)
    body += '<path d="M0 631 Q235 577 400 628 Q630 680 809 618 Q940 600 1080 633V720H0Z" fill="#f6f0e3"/><path d="M0 648 Q220 599 395 646 M718 658 Q901 618 1080 649" fill="none" stroke="#b3c8cb" stroke-width="3" opacity=".7"/>'
    body += '<path fill="url(#grain)" d="M0 0H1080V720H0Z"/>'
    write('src/ui/backgrounds/new_year/bg_winter_village.svg', svg(1080, 720, body))


def atlas():
    # Same 5x3 palette order as the balloon/pumpkin sheets; central number area stays clear.
    colors = ['#d46e66', '#d99a60', '#d9bd68', '#87ad69', '#62a48a', '#66b2af', '#6b9dbb', '#758ec0', '#9586b7', '#b186b6', '#cd85a1', '#cf8b7e', '#b6ab88', '#7bb7ba', '#a58ebf']
    body = ''
    for i, c in enumerate(colors):
        x, y = i % 5 * 256, i // 5 * 240
        body += f'<g transform="translate({x} {y})"><path d="M118 30 C100 8 154 8 138 30" fill="none" stroke="#fff9e8" stroke-width="10"/><path d="M118 30 C100 8 154 8 138 30" fill="none" stroke="#6b6c6c" stroke-width="3"/><circle cx="128" cy="132" r="88" fill="{c}" stroke="#fff9ec" stroke-width="10"/><circle cx="128" cy="132" r="83" fill="none" stroke="{INK}" stroke-width="2.5"/><path d="M111 32H145V51H111Z" fill="#dbbd79" stroke="{INK}" stroke-width="3"/><path d="M74 95 Q87 69 108 65" fill="none" stroke="#fff5db" stroke-width="7" stroke-linecap="round" opacity=".75"/><path d="M65 172 Q128 216 191 172" fill="none" stroke="#fff2d5" stroke-width="4" stroke-dasharray="4 7"/>'
        for sx in [78, 128, 178]:
            body += snowflake(sx, 185 if sx == 128 else 173, 8, '#fff2d5')
        body += '</g>'
    write('src/features/answer/ornaments_atlas.svg', svg(1280, 720, body))


def boss():
    source = (ROOT / 'src/features/boss/art/airship_body.svg').read_text(encoding='utf-8')
    source = source.replace('Boss airship (nose left', 'New Year airship (nose left')
    for old, new in {'#8C97AD':'#6D9C91', '#66718A':'#507D77', '#46506A':'#416B67', '#B5BFD1':'#C3D9C6', '#DCE2EC':'#F5EBD5', '#C65A4C':'#BC6B68', '#B44F43':'#A95D60'}.items():
        source = source.replace(old, new)
    decor = '<path d="M60 65 Q86 17 136 25 L170 48 Q134 35 120 61Z" fill="#bb6464" stroke="white" stroke-width="10" stroke-linejoin="round"/><path d="M60 65 Q86 17 136 25 L170 48 Q134 35 120 61Z" fill="#bb6464" stroke="#354556" stroke-width="3"/><path d="M58 65Q90 50 126 58" stroke="#fff4dc" stroke-width="16" stroke-linecap="round"/><circle cx="170" cy="48" r="10" fill="#fff4dc" stroke="#354556" stroke-width="2"/>'
    decor += '<path d="M170 94 Q263 133 404 93" fill="none" stroke="#355c56" stroke-width="4"/>'
    for x, y, c in [(186, 102, '#e5c77e'), (228, 111, '#d77e77'), (271, 114, '#f5dd9e'), (315, 111, '#d77e77'), (361, 104, '#e5c77e')]:
        decor += f'<circle cx="{x}" cy="{y}" r="6" fill="{c}" stroke="#fff4dc" stroke-width="2"/>'
    decor += snowflake(285, 157, 24, '#f6eed7')
    decor += '<path d="M174 267H300Q315 268 319 258" fill="none" stroke="#dcc080" stroke-width="6" stroke-linecap="round"/>'
    source = source.replace('</svg>', decor + '</svg>')
    write('src/features/boss/art/new_year_airship_body.svg', source)
    for name, hull, shade in [('ice', '#85a9bd', '#68869c'), ('berry', '#b87c8f', '#966476')]:
        write(f'src/features/boss/art/variants/new_year_{name}.svg', source.replace('#6D9C91', hull).replace('#507D77', shade))
    plate = '<path d="M14 16Q50 4 86 16L90 58Q50 70 10 58Z" fill="#7c9fa9" stroke="#fff8e7" stroke-width="12"/><path d="M14 16Q50 4 86 16L90 58Q50 70 10 58Z" fill="#7c9fa9" stroke="#354556" stroke-width="3"/>' + snowflake(50, 37, 22, '#fff1d5')
    for x, y in [(20, 22), (80, 22), (18, 54), (82, 54)]:
        plate += f'<circle cx="{x}" cy="{y}" r="3" fill="#dfbc75"/>'
    write('src/features/boss/art/new_year_armor_plate.svg', svg(100, 76, plate))


def gifts():
    write(f'{EVENT}/snowflake.svg', svg(64, 64, snowflake()))
    write(f'{EVENT}/fir_tree.svg', svg(64, 64, '<path d="M32 4L17 24H24L10 42H22L5 55H27V62H37V55H59L42 42H54L40 24H47Z" fill="white"/>'))
    write(f'{EVENT}/gift.svg', svg(64, 64, '<g fill="white"><path d="M8 29H28V60H8Z M36 29H56V60H36Z M4 19H28V25H4Z M36 19H60V25H36Z"/><path d="M29 22C1 19 12 -6 27 9L32 18L37 9C52 -6 63 19 35 22Z" fill="none" stroke="white" stroke-width="5"/></g>'))
    for opened in [False, True]:
        body = '<ellipse cx="80" cy="143" rx="62" ry="8" fill="#354556" opacity=".15"/><path d="M26 70L80 87L135 69V127L80 146L26 128Z" fill="#578d7b" stroke="#fff4dc" stroke-width="9" stroke-linejoin="round"/><path d="M26 70L80 87L135 69V127L80 146L26 128Z" fill="#578d7b" stroke="#354556" stroke-width="3"/><path d="M80 87V146L92 142V83Z M46 77L59 81V139L46 134Z" fill="#e4c17b"/>'
        lid = '<path d="M22 56L76 38L139 56L80 77Z" fill="#cd7f77" stroke="#354556" stroke-width="3"/><path d="M22 56V72L80 92L139 72V56L80 77Z" fill="#b86866" stroke="#354556" stroke-width="3"/><path d="M46 48L105 68V84L117 79V64L59 44Z" fill="#f0d494"/><path d="M77 46Q41 41 55 24Q70 17 80 43Q83 13 103 25Q115 40 83 47" fill="#e7c37e" stroke="#354556" stroke-width="3"/>'
        if opened:
            body += '<path d="M27 70L80 51L134 70L80 87Z" fill="#284c4a"/>'
            body += f'<g transform="translate(-3 -18) rotate(-14 80 50)">{lid}</g>'
            body += snowflake(81, 68, 16, '#fff1c4')
        else:
            body += lid
        body += snowflake(112, 105, 14, '#fff0d7')
        write(f'{EVENT}/box_{"open" if opened else "closed"}.svg', svg(160, 160, body))
    body = '<path d="M0 0H672V160H0Z" fill="#486b78"/><path d="M0 125Q90 107 160 128T320 130T480 130T672 121V160H0Z" fill="#dae2d6"/>'
    body += tree(84, 32, .65, True)
    for x, y in [(153, 33), (471, 30), (526, 120), (625, 33), (42, 34)]:
        body += snowflake(x, y, 7, '#e6e7d3')
    # No baked text: event title/countdown and gift stack are existing UI nodes.
    write(f'{EVENT}/banner.svg', svg(672, 160, body))


def banner_frame():
    """Use the actual menu CTA texture and its nine-patch margins, like Halloween 2026."""
    import numpy as np
    from PIL import Image
    from generate_halloween_art import cta_frame

    raw = ROOT / 'bin/new_year_banner_art.png'
    raw.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['godot_console', '--headless', '--path', str(ROOT), '--log-file', str(ROOT / 'bin/new_year_banner_render.log'), '--script',
                    'tools/render_svg.gd', '--', f'res://{EVENT}/banner.svg', str(raw), '2'],
                   check=True, shell=sys.platform == 'win32')
    art = np.asarray(Image.open(raw).convert('RGB'), dtype=float) / 255.0
    frame, inside = cta_frame(1344, 320, 2)
    rgb = frame[..., :3] * (1 - inside[..., None]) + art * inside[..., None]
    Image.fromarray((np.dstack([rgb, frame[..., 3]]) * 255).astype(np.uint8)).save(ROOT / EVENT / 'banner.png')


if __name__ == '__main__':
    if 'banner' not in sys.argv[1:]:
        background()
        atlas()
        boss()
    gifts()
    banner_frame()
    print('New Year SVG kit generated.')
