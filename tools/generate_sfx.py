"""Synthesize short PCM WAV SFX for Quizmatik (notebook / arcade)."""
from __future__ import annotations

import math
import os
import random
import struct
import wave

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "src", "features", "sfx")
PLANE_DIR = os.path.join(ROOT, "src", "features", "plane")


def _clamp(x: float, lo: float = -1.0, hi: float = 1.0) -> float:
	return lo if x < lo else hi if x > hi else x


def write_wav(path: str, samples: list[float]) -> None:
	if not samples:
		raise ValueError("empty samples")
	# fade last 64 samples to kill clicks
	fade = min(64, len(samples) // 8)
	for i in range(fade):
		samples[-1 - i] *= i / fade
	peak = max(abs(s) for s in samples) or 1.0
	gain = 0.89 / peak
	os.makedirs(os.path.dirname(path), exist_ok=True)
	with wave.open(path, "w") as wav:
		wav.setnchannels(1)
		wav.setsampwidth(2)
		wav.setframerate(SR)
		frames = b"".join(
			struct.pack("<h", int(_clamp(s * gain) * 32767.0)) for s in samples
		)
		wav.writeframes(frames)
	print(f"wrote {os.path.relpath(path, ROOT)} ({len(samples) / SR:.3f}s)")


def env_exp(i: int, n: int, attack: float, decay_tau: float) -> float:
	t = i / SR
	dur = n / SR
	a = min(attack, dur * 0.35)
	if t < a:
		return t / a if a > 0 else 1.0
	return math.exp(-(t - a) / decay_tau)


def env_lin(i: int, n: int, attack: float, release: float) -> float:
	t = i / SR
	dur = n / SR
	a = min(attack, dur * 0.4)
	r = min(release, dur - a)
	if t < a:
		return t / a if a > 0 else 1.0
	if t > dur - r and r > 0:
		return max(0.0, (dur - t) / r)
	return 1.0


def noise() -> float:
	return random.random() * 2.0 - 1.0


def lowpass(prev: float, x: float, alpha: float) -> float:
	return prev + alpha * (x - prev)


def tone(freq: float, t: float, harmonics: tuple[tuple[float, float], ...] = ((1, 1.0), (2, 0.28), (3, 0.1))) -> float:
	s = 0.0
	w = 0.0
	for h, amp in harmonics:
		s += amp * math.sin(2.0 * math.pi * freq * h * t)
		w += amp
	return s / w if w else 0.0


def render(seconds: float, fn) -> list[float]:
	n = max(1, int(seconds * SR))
	out = [0.0] * n
	for i in range(n):
		out[i] = fn(i, n, i / SR)
	return out


def mix(*tracks: list[float]) -> list[float]:
	n = max(len(t) for t in tracks)
	out = [0.0] * n
	for track in tracks:
		for i, s in enumerate(track):
			out[i] += s
	return out


def ui_click() -> list[float]:
	random.seed(11)

	def fn(i, n, t):
		tap = tone(190.0, t) * env_exp(i, n, 0.002, 0.018)
		wood = tone(540.0, t, ((1, 1.0), (2, 0.4))) * env_exp(i, n, 0.001, 0.012)
		chiff = noise() * env_exp(i, n, 0.0005, 0.008)
		return tap * 0.55 + wood * 0.35 + chiff * 0.22

	return render(0.07, fn)


def shoot() -> list[float]:
	random.seed(23)
	lp = 0.0

	def fn(i, n, t):
		nonlocal lp
		freq = 1600.0 * math.exp(-t * 14.0) + 180.0
		body = math.sin(2.0 * math.pi * freq * t)
		burst = noise()
		lp = lowpass(lp, burst, 0.35)
		whoosh = lp * env_exp(i, n, 0.004, 0.07)
		flick = noise() * env_exp(i, n, 0.0004, 0.012)
		thump = math.sin(2.0 * math.pi * 90.0 * t) * env_exp(i, n, 0.002, 0.05)
		return body * 0.22 * env_exp(i, n, 0.003, 0.08) + whoosh * 0.55 + flick * 0.28 + thump * 0.35

	return render(0.18, fn)


def pop() -> list[float]:
	random.seed(41)
	lp = 0.0

	def fn(i, n, t):
		nonlocal lp
		nse = noise()
		lp = lowpass(lp, nse, 0.55)
		burst = (nse * 0.65 + lp * 0.35) * env_exp(i, n, 0.0008, 0.04)
		thump = math.sin(2.0 * math.pi * 140.0 * t) * env_exp(i, n, 0.001, 0.07)
		ring = math.sin(2.0 * math.pi * 420.0 * t) * env_exp(i, n, 0.002, 0.09)
		return burst * 0.7 + thump * 0.45 + ring * 0.25

	return render(0.22, fn)


def correct() -> list[float]:
	def note(freq: float, start: float, dur: float, amp: float) -> list[float]:
		n = int((start + dur) * SR)

		def fn(i, _n, t):
			local = t - start
			if local < 0 or local > dur:
				return 0.0
			e = env_exp(int(local * SR), int(dur * SR), 0.006, 0.12)
			chiff = noise() * math.exp(-local * 40.0) * 0.12
			return amp * (tone(freq, local) * e + chiff)

		return render(start + dur, fn)

	return mix(note(523.25, 0.0, 0.22, 0.7), note(659.25, 0.07, 0.28, 0.85))


def mistake() -> list[float]:
	def fn(i, n, t):
		freq = 320.0 - 140.0 * (t / max(n / SR, 0.001))
		buzz = tone(freq, t, ((1, 1.0), (2, 0.6), (3, 0.25)))
		rough = 0.15 * math.sin(2.0 * math.pi * 40.0 * t)
		return (buzz + rough) * env_exp(i, n, 0.008, 0.16)

	return render(0.32, fn)


def win() -> list[float]:
	notes = [
		(523.25, 0.00, 0.28, 0.55),
		(659.25, 0.16, 0.28, 0.62),
		(783.99, 0.32, 0.32, 0.7),
		(1046.5, 0.52, 0.72, 0.85),
	]
	tracks: list[list[float]] = []
	for freq, start, dur, amp in notes:

		def fn(i, n, t, f=freq, s0=start, d=dur, a=amp):
			local = t - s0
			if local < 0 or local > d:
				return 0.0
			e = env_exp(int(local * SR), int(d * SR), 0.01, 0.22)
			sparkle = math.sin(2.0 * math.pi * f * 2.0 * local) * 0.18 * e
			return a * (tone(f, local) * e + sparkle)

		tracks.append(render(start + dur, fn))
	return mix(*tracks)


def lose() -> list[float]:
	notes = [
		(392.00, 0.00, 0.32, 0.7),
		(311.13, 0.22, 0.34, 0.65),
		(261.63, 0.46, 0.38, 0.6),
		(196.00, 0.72, 0.48, 0.7),
	]
	tracks: list[list[float]] = []
	for freq, start, dur, amp in notes:

		def fn(i, n, t, f=freq, s0=start, d=dur, a=amp):
			local = t - s0
			if local < 0 or local > d:
				return 0.0
			e = env_exp(int(local * SR), int(d * SR), 0.012, 0.2)
			return a * tone(f, local, ((1, 1.0), (2, 0.2))) * e

		tracks.append(render(start + dur, fn))
	return mix(*tracks)


def battle_start() -> list[float]:
	random.seed(7)
	lp = 0.0

	def fn(i, n, t):
		nonlocal lp
		lp = lowpass(lp, noise(), 0.18)
		freq = 220.0 + 520.0 * (t / max(n / SR, 0.001))
		sweep = math.sin(2.0 * math.pi * freq * t) * env_lin(i, n, 0.04, 0.18)
		air = lp * env_lin(i, n, 0.03, 0.22)
		return sweep * 0.45 + air * 0.55

	return render(0.55, fn)


def go() -> list[float]:
	def fn(i, n, t):
		ping = tone(783.99, t) * env_exp(i, n, 0.004, 0.14)
		octv = tone(1567.98, t, ((1, 1.0),)) * env_exp(i, n, 0.003, 0.08)
		return ping * 0.75 + octv * 0.28

	return render(0.28, fn)


def crash() -> list[float]:
	random.seed(99)
	lp = 0.0
	lp2 = 0.0

	def fn(i, n, t):
		nonlocal lp, lp2
		nse = noise()
		lp = lowpass(lp, nse, 0.22)
		lp2 = lowpass(lp2, lp, 0.08)
		boom = math.sin(2.0 * math.pi * (70.0 + 40.0 * math.exp(-t * 8.0)) * t)
		crackle = nse * env_exp(i, n, 0.002, 0.09)
		body = (lp * 0.45 + lp2 * 0.55) * env_exp(i, n, 0.004, 0.22)
		return boom * 0.4 * env_exp(i, n, 0.003, 0.18) + body * 0.7 + crackle * 0.35

	return render(0.55, fn)


def victory_whoosh() -> list[float]:
	random.seed(3)
	lp = 0.0

	def fn(i, n, t):
		nonlocal lp
		u = t / max(n / SR, 0.001)
		lp = lowpass(lp, noise(), 0.12 + 0.25 * u)
		freq = 180.0 * (1.0 + 3.4 * u * u)
		engine = math.sin(2.0 * math.pi * freq * t) * env_lin(i, n, 0.05, 0.2)
		air = lp * env_lin(i, n, 0.06, 0.18)
		doppler = math.sin(2.0 * math.pi * (400.0 + 900.0 * u) * t) * 0.12 * env_lin(i, n, 0.08, 0.25)
		return engine * 0.35 + air * 0.7 + doppler

	return render(0.95, fn)


def main() -> None:
	random.seed(1)
	pairs = [
		(os.path.join(SFX_DIR, "ui_click.wav"), ui_click),
		(os.path.join(SFX_DIR, "shoot.wav"), shoot),
		(os.path.join(SFX_DIR, "pop.wav"), pop),
		(os.path.join(SFX_DIR, "correct.wav"), correct),
		(os.path.join(SFX_DIR, "mistake.wav"), mistake),
		(os.path.join(SFX_DIR, "win.wav"), win),
		(os.path.join(SFX_DIR, "lose.wav"), lose),
		(os.path.join(SFX_DIR, "battle_start.wav"), battle_start),
		(os.path.join(SFX_DIR, "go.wav"), go),
		(os.path.join(PLANE_DIR, "crash.wav"), crash),
		(os.path.join(PLANE_DIR, "victory_whoosh.wav"), victory_whoosh),
	]
	for path, fn in pairs:
		write_wav(path, fn())


if __name__ == "__main__":
	main()
