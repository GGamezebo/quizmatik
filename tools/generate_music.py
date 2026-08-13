"""Synthesize energetic post-battle music matching Quizmatik background vibe.

Background profile (~100 BPM, punchy mid/bass, dense rhythm). Win/lose themes
keep the same arcade bounce; win = bright major, lose = minor but still peppy.
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC_DIR = os.path.join(ROOT, "src", "features", "music")

BPM = 100.0
BEAT = 60.0 / BPM
BAR = BEAT * 4.0  # 4/4 arcade groove
LOOP_BARS = 8
DURATION = BAR * LOOP_BARS


def _clamp(x: float, lo: float = -1.0, hi: float = 1.0) -> float:
	return lo if x < lo else hi if x > hi else x


def write_wav(path: str, samples: list[float]) -> None:
	if not samples:
		raise ValueError("empty samples")
	xfade = min(int(0.03 * SR), len(samples) // 10)
	for i in range(xfade):
		t = i / xfade
		samples[i] = samples[i] * t + samples[len(samples) - xfade + i] * (1.0 - t)
	samples = samples[:-xfade] if xfade else samples
	peak = max(abs(s) for s in samples) or 1.0
	gain = 0.82 / peak
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


def lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


def env_adsr(t: float, a: float, d: float, s: float, r: float, hold: float) -> float:
	if t < 0:
		return 0.0
	if t < a:
		return t / a if a > 0 else 1.0
	if t < a + d:
		return lerp(1.0, s, (t - a) / d if d > 0 else 1.0)
	if t < a + d + hold:
		return s
	u = t - (a + d + hold)
	if u < r:
		return s * (1.0 - u / r) if r > 0 else 0.0
	return 0.0


def square(freq: float, t: float, duty: float = 0.5) -> float:
	phase = (freq * t) % 1.0
	return 1.0 if phase < duty else -1.0


def saw(freq: float, t: float) -> float:
	phase = (freq * t) % 1.0
	return 2.0 * phase - 1.0


def tri(freq: float, t: float) -> float:
	phase = (freq * t) % 1.0
	return 1.0 - 4.0 * abs(phase - 0.5)


def sine(freq: float, t: float) -> float:
	return math.sin(2.0 * math.pi * freq * t)


def noise() -> float:
	return random.random() * 2.0 - 1.0


def lowpass(state: float, x: float, alpha: float) -> float:
	return state + alpha * (x - state)


def kick(t: float) -> float:
	if t < 0 or t > 0.22:
		return 0.0
	freq = lerp(140.0, 48.0, min(t / 0.08, 1.0))
	body = sine(freq, t) * math.exp(-t * 14.0)
	click = noise() * math.exp(-t * 80.0) * 0.35
	return body * 1.1 + click


def snare(t: float) -> float:
	if t < 0 or t > 0.28:
		return 0.0
	body = sine(180.0, t) * math.exp(-t * 22.0) * 0.35
	noise_body = noise() * math.exp(-t * 16.0)
	return body + noise_body * 0.85


def hat(t: float, open_: bool = False) -> float:
	dur = 0.12 if open_ else 0.045
	if t < 0 or t > dur:
		return 0.0
	decay = 18.0 if open_ else 55.0
	return noise() * math.exp(-t * decay) * (0.28 if open_ else 0.18)


def clap(t: float) -> float:
	if t < 0 or t > 0.2:
		return 0.0
	# layered noise bursts
	s = 0.0
	for delay in (0.0, 0.012, 0.024):
		u = t - delay
		if u >= 0:
			s += noise() * math.exp(-u * 40.0)
	return s * 0.45


def bass_note(freq: float, t: float, length: float = 0.35) -> float:
	if t < 0 or t > length:
		return 0.0
	e = env_adsr(t, 0.008, 0.08, 0.55, 0.08, max(length - 0.17, 0.05))
	# slightly overdriven square-ish bass
	wave = sine(freq, t) * 0.7 + square(freq, t, 0.4) * 0.25 + sine(freq * 2.0, t) * 0.08
	return wave * e


def lead_note(freq: float, t: float, length: float = 0.28, bright: bool = True) -> float:
	if t < 0 or t > length + 0.05:
		return 0.0
	e = env_adsr(t, 0.006, 0.05, 0.65, 0.07, max(length - 0.12, 0.04))
	if bright:
		wave = square(freq, t, 0.45) * 0.45 + saw(freq, t) * 0.25 + tri(freq * 2.0, t) * 0.15
	else:
		wave = tri(freq, t) * 0.55 + square(freq, t, 0.35) * 0.25 + sine(freq, t) * 0.2
	# soft pitch scoop for bounce
	scoop = 1.0 + 0.015 * math.exp(-t * 30.0)
	wave2 = square(freq * scoop, t, 0.45) * 0.15 if bright else 0.0
	return (wave + wave2) * e


def arpeggio_note(freq: float, t: float) -> float:
	if t < 0 or t > 0.18:
		return 0.0
	e = math.exp(-t * 14.0) * min(t / 0.004, 1.0)
	return (tri(freq, t) * 0.6 + square(freq, t, 0.5) * 0.25) * e


def expand(pattern: list[tuple[float, float, float]], bars: int, phrase: int) -> list[tuple[float, float, float]]:
	"""pattern entries: (bar_in_phrase, beat, freq)."""
	out: list[tuple[float, float, float]] = []
	for bar in range(bars):
		local = bar % phrase
		for bar_i, beat, freq in pattern:
			if int(bar_i) != local:
				continue
			out.append((bar * BAR + beat * BEAT, freq, 1.0))
	return out


def render_groove(
	*,
	bass_pat: list[tuple[float, float, float]],
	lead_pat: list[tuple[float, float, float]],
	arp_pat: list[tuple[float, float, float]],
	bright: bool,
) -> list[float]:
	random.seed(7 if bright else 13)
	n = int(DURATION * SR)
	out = [0.0] * n
	bass_notes = expand(bass_pat, LOOP_BARS, 4)
	lead_notes = expand(lead_pat, LOOP_BARS, 8)
	arp_notes = expand(arp_pat, LOOP_BARS, 4)

	lp = 0.0
	for i in range(n):
		t = i / SR
		beat_pos = (t / BEAT) % 4.0
		bar_beat = beat_pos  # 0..4 within bar
		# drums every bar
		s = 0.0
		# kick on 1 and 3 (+ occasional 16th bounce)
		kick_t = (t % BAR)
		for kt in (0.0, 2.0 * BEAT, 1.5 * BEAT if int(t / BAR) % 2 == 1 else -1.0):
			if kt >= 0:
				s += kick(kick_t - kt) * 0.95
		# snare/clap on 2 and 4
		s += snare(kick_t - 1.0 * BEAT) * 0.72
		s += clap(kick_t - 3.0 * BEAT) * 0.55
		# hats 8th notes
		eighth = (t % (BEAT * 0.5))
		open_hat = abs((t % BAR) - 1.5 * BEAT) < 0.02
		s += hat(eighth, open_=open_hat) * (0.9 if bright else 0.75)

		# bass
		for start, freq, _ in bass_notes:
			local = t - start
			if 0.0 <= local < 0.5:
				s += bass_note(freq, local, 0.42) * 0.55

		# lead
		for start, freq, _ in lead_notes:
			local = t - start
			if 0.0 <= local < 0.55:
				s += lead_note(freq, local, 0.32 if bright else 0.36, bright=bright) * (
					0.38 if bright else 0.34
				)

		# arp sparkle
		for start, freq, _ in arp_notes:
			local = t - start
			if 0.0 <= local < 0.2:
				s += arpeggio_note(freq, local) * (0.18 if bright else 0.12)

		# sidechain-ish duck under kick
		kick_prox = min((t % BEAT), BEAT - (t % BEAT))
		duck = 0.82 + 0.18 * min(kick_prox / 0.06, 1.0)
		s *= duck

		# mild saturation
		s = math.tanh(s * 1.35)

		# gentle tone balance toward midrange (match bg)
		lp = lowpass(lp, s, 0.35)
		s = s * 0.55 + lp * 0.45

		edge = min(t / 0.2, (DURATION - t) / 0.25, 1.0)
		out[i] = s * edge

	return out


def win_theme() -> list[float]:
	# C major bounce — same pep as bg, triumphant hooks
	# C2=65.41 C3=130.81 D3=146.83 E3=164.81 G3=196 A3=220
	bass = [
		(0, 0.0, 130.81),
		(0, 1.0, 130.81),
		(0, 2.0, 130.81),
		(0, 3.0, 196.00),
		(1, 0.0, 146.83),
		(1, 1.0, 146.83),
		(1, 2.0, 146.83),
		(1, 3.0, 220.00),
		(2, 0.0, 164.81),
		(2, 1.0, 164.81),
		(2, 2.0, 196.00),
		(2, 3.0, 220.00),
		(3, 0.0, 130.81),
		(3, 1.0, 196.00),
		(3, 2.0, 130.81),
		(3, 3.0, 261.63),
	]
	lead = [
		(0, 0.0, 523.25),
		(0, 0.5, 587.33),
		(0, 1.0, 659.25),
		(0, 2.0, 783.99),
		(0, 3.0, 659.25),
		(1, 0.0, 698.46),
		(1, 1.0, 659.25),
		(1, 2.0, 587.33),
		(1, 3.0, 523.25),
		(2, 0.0, 659.25),
		(2, 0.5, 698.46),
		(2, 1.0, 783.99),
		(2, 2.0, 880.00),
		(2, 3.0, 783.99),
		(3, 0.0, 1046.5),
		(3, 2.0, 783.99),
		(3, 3.0, 659.25),
		(4, 0.0, 523.25),
		(4, 1.0, 659.25),
		(4, 2.0, 783.99),
		(4, 3.0, 659.25),
		(5, 0.0, 587.33),
		(5, 1.0, 523.25),
		(5, 2.0, 587.33),
		(5, 3.0, 659.25),
		(6, 0.0, 698.46),
		(6, 1.0, 783.99),
		(6, 2.0, 880.00),
		(6, 3.0, 783.99),
		(7, 0.0, 1046.5),
		(7, 1.0, 880.00),
		(7, 2.0, 783.99),
		(7, 3.0, 1046.5),
	]
	arp = [
		(0, 0.0, 523.25),
		(0, 0.5, 659.25),
		(0, 1.0, 783.99),
		(0, 1.5, 1046.5),
		(0, 2.0, 523.25),
		(0, 2.5, 659.25),
		(0, 3.0, 783.99),
		(0, 3.5, 1046.5),
		(1, 0.0, 587.33),
		(1, 0.5, 698.46),
		(1, 1.0, 880.00),
		(1, 1.5, 1174.7),
		(1, 2.0, 587.33),
		(1, 2.5, 698.46),
		(1, 3.0, 880.00),
		(1, 3.5, 1174.7),
		(2, 0.0, 659.25),
		(2, 0.5, 783.99),
		(2, 1.0, 987.77),
		(2, 1.5, 1318.5),
		(2, 2.0, 659.25),
		(2, 2.5, 783.99),
		(2, 3.0, 987.77),
		(2, 3.5, 1318.5),
		(3, 0.0, 523.25),
		(3, 0.5, 659.25),
		(3, 1.0, 783.99),
		(3, 1.5, 1046.5),
		(3, 2.0, 523.25),
		(3, 2.5, 783.99),
		(3, 3.0, 1046.5),
		(3, 3.5, 1318.5),
	]
	return render_groove(bass_pat=bass, lead_pat=lead, arp_pat=arp, bright=True)


def lose_theme() -> list[float]:
	# A minor — same groove engine, descending hooks, still bouncey
	bass = [
		(0, 0.0, 110.00),
		(0, 1.0, 110.00),
		(0, 2.0, 110.00),
		(0, 3.0, 164.81),
		(1, 0.0, 98.00),
		(1, 1.0, 98.00),
		(1, 2.0, 98.00),
		(1, 3.0, 146.83),
		(2, 0.0, 87.31),
		(2, 1.0, 87.31),
		(2, 2.0, 87.31),
		(2, 3.0, 130.81),
		(3, 0.0, 82.41),
		(3, 1.0, 82.41),
		(3, 2.0, 98.00),
		(3, 3.0, 110.00),
	]
	lead = [
		(0, 0.0, 440.00),
		(0, 1.0, 392.00),
		(0, 2.0, 349.23),
		(0, 3.0, 329.63),
		(1, 0.0, 392.00),
		(1, 1.0, 349.23),
		(1, 2.0, 329.63),
		(1, 3.0, 293.66),
		(2, 0.0, 349.23),
		(2, 1.0, 329.63),
		(2, 2.0, 293.66),
		(2, 3.0, 261.63),
		(3, 0.0, 246.94),
		(3, 2.0, 220.00),
		(3, 3.0, 196.00),
		(4, 0.0, 440.00),
		(4, 0.5, 392.00),
		(4, 1.0, 349.23),
		(4, 2.0, 329.63),
		(4, 3.0, 349.23),
		(5, 0.0, 392.00),
		(5, 1.0, 349.23),
		(5, 2.0, 293.66),
		(5, 3.0, 261.63),
		(6, 0.0, 329.63),
		(6, 1.0, 293.66),
		(6, 2.0, 261.63),
		(6, 3.0, 246.94),
		(7, 0.0, 220.00),
		(7, 1.0, 196.00),
		(7, 2.0, 220.00),
		(7, 3.0, 164.81),
	]
	arp = [
		(0, 0.0, 440.00),
		(0, 0.5, 523.25),
		(0, 1.0, 659.25),
		(0, 1.5, 523.25),
		(0, 2.0, 440.00),
		(0, 2.5, 523.25),
		(0, 3.0, 659.25),
		(0, 3.5, 523.25),
		(1, 0.0, 392.00),
		(1, 0.5, 493.88),
		(1, 1.0, 587.33),
		(1, 1.5, 493.88),
		(1, 2.0, 392.00),
		(1, 2.5, 493.88),
		(1, 3.0, 587.33),
		(1, 3.5, 493.88),
		(2, 0.0, 349.23),
		(2, 0.5, 440.00),
		(2, 1.0, 523.25),
		(2, 1.5, 440.00),
		(2, 2.0, 349.23),
		(2, 2.5, 440.00),
		(2, 3.0, 523.25),
		(2, 3.5, 440.00),
		(3, 0.0, 329.63),
		(3, 0.5, 392.00),
		(3, 1.0, 493.88),
		(3, 1.5, 392.00),
		(3, 2.0, 329.63),
		(3, 2.5, 392.00),
		(3, 3.0, 440.00),
		(3, 3.5, 329.63),
	]
	return render_groove(bass_pat=bass, lead_pat=lead, arp_pat=arp, bright=False)


def main() -> None:
	write_wav(os.path.join(MUSIC_DIR, "win_music.wav"), win_theme())
	write_wav(os.path.join(MUSIC_DIR, "lose_music.wav"), lose_theme())


if __name__ == "__main__":
	main()
