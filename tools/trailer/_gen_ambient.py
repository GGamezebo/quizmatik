"""Trip-hop bed for the «в цвет» ad. Dusty break, minor keys, a line that keeps climbing.

    python tools/trailer/_gen_ambient.py
Writes bin/trailer/ambient_bed.ogg (~34 s, one pass). Not game music.
Original — the mood is the reference, not any existing song.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import generate_music as g  # noqa: E402

OUT = Path(__file__).resolve().parents[2] / "bin" / "trailer" / "ambient_bed.ogg"

# 100 BPM: the pocket is in by the color splash, and the line keeps rising through the boss.
BPM = 100.0
BARS = 14


def keys(f: float, d: float) -> np.ndarray:
    return g.epiano(f, d, 0.85)


def muffled(sig: np.ndarray, cutoff: float) -> np.ndarray:
    return g.signal.sosfilt(g._sos("lowpass", cutoff), sig)


def crackle(seconds: float) -> np.ndarray:
    n = int(seconds * g.SR)
    dust = g.rng.standard_normal(n)
    dust = g.signal.sosfilt(g._sos("bandpass", (1800, 7000)), dust)
    pops = (g.rng.random(n) > 0.9993).astype(np.float64) * g.rng.standard_normal(n)
    pops = g.signal.sosfilt(g._sos("highpass", 2200), pops)
    return dust * 0.35 + pops * 3.0


def main() -> None:
    beat = 60.0 / BPM
    bars_sec = BARS * 4 * beat
    lm = g.Mix(bars_sec + 3.2, BPM)
    # Dm Bb F C — the loop turns over, then opens on the way to the title.
    prog = [
        ("D", True), ("D", True), ("A#", False), ("F", False),
        ("D", True), ("G", True), ("A#", False), ("C", False),
        ("D", True), ("A#", False), ("F", False), ("C", False),
        ("A#", False), ("D", True),
    ]
    melody = [
        [("D4", 0.5), ("F4", 0.5), ("A4", 1.0), ("F4", 0.5), ("D4", 1.5)],
        [("A4", 0.5), ("F4", 0.5), ("E4", 1.0), ("D4", 2.0)],
        [("F4", 0.5), ("A#4", 0.5), ("D5", 1.0), ("C5", 0.5), ("A#4", 1.5)],
        [("A4", 0.5), ("C5", 0.5), ("F5", 1.0), ("C5", 0.5), ("A4", 1.5)],
        [("D4", 0.5), ("F4", 0.5), ("A4", 1.0), ("C5", 0.5), ("A4", 1.5)],
        [("G4", 0.5), ("A#4", 0.5), ("D5", 1.0), ("A#4", 0.5), ("G4", 1.5)],
        [("A#4", 0.5), ("D5", 0.5), ("F5", 1.0), ("D5", 0.5), ("A#4", 1.5)],
        [("C5", 1.0), ("D5", 0.5), ("E5", 0.5), ("G5", 1.0), ("E5", 1.0)],
        [("A4", 0.5), ("F4", 0.5), ("D4", 1.0), ("F4", 0.5), ("A4", 1.5)],
        [("D5", 1.0), ("A#4", 1.0), ("F4", 2.0)],
        [("C5", 0.5), ("A4", 0.5), ("F4", 1.0), ("A4", 0.5), ("C5", 1.5)],
        [("E5", 1.0), ("D5", 1.0), ("C5", 2.0)],
        [("D5", 1.5), ("A#4", 0.5), ("F4", 2.0)],
        [("A4", 1.0), ("F4", 1.0), ("D4", 2.0)],
    ]
    # Full pocket almost immediately; the boss bars push a little harder, the title lands.
    energy = [0.72, 1.0, 1.0, 1.05, 1.08, 1.12, 1.18, 1.22, 1.16, 1.1, 1.08, 1.05, 1.0, 0.85]

    lm.add(crackle(bars_sec), 0.0, 0.14, pan=0.2, send=0.02)

    for bar, (root, minor) in enumerate(prog):
        e = energy[bar]
        b, voicing, _arp = g.chord(root, minor)
        for m in voicing:
            lm.add(g._pad(g.hz(m), 4 * beat + 0.8), lm.sec(bar), 0.16 * e, pan=-0.25, send=0.7)
        if bar >= 4:
            for m in voicing:
                lm.add(g._pad(g.hz(m + 12), 4 * beat + 0.5), lm.sec(bar), 0.045 * e, pan=0.35, send=0.75)
        g.place_melody(lm, bar, melody[bar], keys, gain=0.38 * min(e, 1.1), pan=0.12, send=0.42)
        if bar >= 6:
            g.place_melody(lm, bar, g._octave_up(melody[bar]), lambda f, d: g.epiano(f, d, 0.6), gain=0.14, pan=-0.3, send=0.35)
        # Low rhodes on the downbeat — the note you lean into.
        lm.add(g.epiano(g.hz(voicing[0]), beat * 1.2, 0.7), lm.sec(bar), 0.11 * e, pan=-0.2, send=0.28)

        lm.add(g.bass(g.hz(b), 0.95 * beat), lm.sec(bar, 0), 0.5 * e, send=0.04)
        lm.add(g.bass(g.hz(b + 7), 0.4 * beat), lm.sec(bar, 1.5), 0.26 * e, send=0.03)
        lm.add(g.bass(g.hz(b), 0.7 * beat), lm.sec(bar, 2.0), 0.38 * e, send=0.04)
        if bar >= 2:
            lm.add(g.bass(g.hz(b + 12), 0.28 * beat), lm.sec(bar, 3.5), 0.2 * e, send=0.02)

        lm.add(g.kick(False), lm.sec(bar, 0), 0.5 * e, send=0.04)
        lm.add(g.kick(True), lm.sec(bar, 1.75), 0.22 * e, send=0.02)
        lm.add(g.kick(False), lm.sec(bar, 2.5), 0.34 * e, send=0.03)
        if bar >= 4:
            lm.add(g.kick(True), lm.sec(bar, 3.5), 0.18 * e, send=0.02)
        sn = muffled(g.snare(), 3800)
        lm.add(sn, lm.sec(bar, 1), 0.3 * e, pan=0.08, send=0.18)
        lm.add(sn, lm.sec(bar, 3), 0.3 * e, pan=0.08, send=0.18)
        if bar >= 2:
            lm.add(sn, lm.sec(bar, 0.75), 0.08 * e, pan=0.05, send=0.1)
            lm.add(sn, lm.sec(bar, 2.75), 0.1 * e, pan=0.05, send=0.1)
        hat = muffled(g.hat(False), 5500)
        for i in range(8):
            swing = 0.045 if i % 2 else 0.0
            lm.add(hat, lm.sec(bar, i * 0.5 + swing), 0.045 * e if i % 2 else 0.03 * e, pan=0.35, send=0.08)
        if bar >= 2 and bar % 2 == 0:
            lm.add(muffled(g.hat(True), 6000), lm.sec(bar, 3.5), 0.07 * e, pan=0.4, send=0.2)

    if bars_sec > 2.2:
        lm.add(g.swell(2.0), lm.sec(6) - 1.9, 0.1, pan=0.15, send=0.35)

    audio = lm.render(t60=2.2, wet_ratio=0.4)
    audio = g.signal.sosfilt(g._HP_MASTER, audio, axis=1)
    n = int(bars_sec * g.SR)
    audio = audio[:, :n]
    rms = float(np.sqrt(np.mean(audio ** 2)) + 1e-9)
    audio *= 0.17 / rms
    audio = np.tanh(audio * 1.2) / 1.2
    audio *= 0.89 / (np.max(np.abs(audio)) + 1e-9)
    fade_in = int(0.18 * g.SR)
    fade_out = int(1.3 * g.SR)
    audio[:, :fade_in] *= np.linspace(0.0, 1.0, fade_in)
    audio[:, -fade_out:] *= np.linspace(1.0, 0.0, fade_out)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    g.write_ogg(str(OUT), audio, quality=6)


if __name__ == "__main__":
    main()
