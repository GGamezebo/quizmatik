"""Synthesize MusicController themes (stereo OGG): win / lose / battle / exam / boss.

Battle (G major 124), exam (E minor 132), boss (D minor 150) — pure loops (loop_offset 0).

Win  — D major, 120 BPM: brass fanfare intro (2 bars) → loop on the Canon
       progression D A Bm F#m G D G A (lead + glockenspiel, plucked arp,
       string pad, bass, drums).
Lose — A minor, 80 BPM: gentle descending piano intro (2 bars) → warm, hopeful
       loop Am F C G F C Dm E (piano, music box, pad, soft brushes).

Each file = intro + loop. The loop's reverb tail is folded onto the loop start
so it repeats seamlessly; the `.ogg.import` `loop_offset` must equal the intro
length printed by this script (seconds).

Needs numpy + scipy; OGG via ffmpeg on PATH or imageio-ffmpeg.
"""
from __future__ import annotations

import math
import os
import shutil
import subprocess
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC_DIR = os.path.join(ROOT, "src", "features", "music")
TAIL_SEC = 4.0

rng = np.random.default_rng(20261003)

_PC = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5,
	"F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name: str) -> int:
	return 12 * (int(name[-1]) + 1) + _PC[name[:-1]]


def hz(m: float) -> float:
	return 440.0 * 2.0 ** ((m - 69.0) / 12.0)


def _t(seconds: float) -> np.ndarray:
	return np.arange(int(seconds * SR)) / SR


def _sos(kind: str, freq, order: int = 2):
	return signal.butter(order, freq, btype=kind, fs=SR, output="sos")


_HP_HAT = _sos("highpass", 7000)
_HP_SHAKER = _sos("highpass", 4500)
_HP_CRASH = _sos("highpass", 3500)
_BP_SNARE = _sos("bandpass", (900, 7000))
_BP_CLAP = _sos("bandpass", (900, 2800))
_BP_RIM = _sos("bandpass", (1500, 5000))
_LP_IR = _sos("lowpass", 5500)
_HP_MASTER = _sos("highpass", 28)


# --- instruments (mono, peak ~1) ------------------------------------------------

def additive(f: float, dur: float, *, rolloff: float, attack: float, release: float,
		vibrato: float = 0.0, detune: float = 0.0, bright_env: bool = True,
		max_k: int = 24) -> np.ndarray:
	"""Brass / lead / pad: harmonic stack with brightness swell + vibrato."""
	total = dur + release
	t = _t(total)
	amp = np.interp(t, [0, attack, attack + 0.12, max(dur, attack + 0.13), total],
		[0, 1, 0.85, 0.8, 0])
	if bright_env:
		br = np.interp(t, [0, attack * 0.7 + 0.01, attack + 0.35, total], [0.35, 1.0, 0.75, 0.6])
	else:
		br = np.full_like(t, 0.7)
	vib_ramp = np.clip((t - 0.25) / 0.4, 0, 1)
	out = np.zeros_like(t)
	voices = (1.0,) if detune == 0 else (1.0 - detune, 1.0 + detune)
	for dv in voices:
		inst = f * dv * (1.0 + vibrato * vib_ramp * np.sin(2 * np.pi * 5.3 * t + dv * 7))
		phase = 2 * np.pi * np.cumsum(inst) / SR + rng.uniform(0, 6.28)
		for k in range(1, max_k + 1):
			if f * k > 15000:
				break
			a_k = np.exp(-(k - 1) * rolloff / (br + 0.05)) / k
			out += a_k * np.sin(k * phase)
	out *= amp
	return out / (np.max(np.abs(out)) + 1e-9)


def struck(f: float, dur: float, *, vel: float = 1.0, decay: float = 1.5,
		decay_k: float = 0.7, rolloff: float = 1.4, inharm: float = 0.0003,
		ring: float = 1.2, n_partials: int = 14, hammer: float = 0.15) -> np.ndarray:
	"""Piano / pluck: decaying partials (higher ones faster), damped after `dur`."""
	total = dur + ring
	t = _t(total)
	out = np.zeros_like(t)
	for string_detune in (0.9993, 1.0007):
		for k in range(1, n_partials + 1):
			fk = f * k * math.sqrt(1 + inharm * k * k) * string_detune
			if fk > 16000:
				break
			a_k = (1.0 / k ** rolloff) * (0.55 + 0.45 * vel ** (k * 0.3))
			out += a_k * np.exp(-t * (decay + decay_k * k)) * np.sin(2 * np.pi * fk * t + k)
	damp = np.where(t < dur, 1.0, np.exp(-(t - dur) * 7.0))
	out *= damp
	if hammer > 0:
		n = min(len(t), int(0.02 * SR))
		click = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * 300)
		out[:n] += signal.sosfilt(_sos("lowpass", min(f * 6, 9000)), click) * hammer
	out *= np.interp(t, [0, 0.003, total], [0, 1, 1])
	return out / (np.max(np.abs(out)) + 1e-9)


def epiano(f: float, dur: float, vel: float = 1.0) -> np.ndarray:
	total = dur + 1.0
	t = _t(total)
	idx = 1.6 * vel * np.exp(-t * 5.0) + 0.25
	car = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * t))
	tine = np.sin(2 * np.pi * f * 7.0 * t) * np.exp(-t * 25.0) * 0.12 * vel
	amp = np.exp(-t * 1.4) * np.where(t < dur, 1.0, np.exp(-(t - dur) * 6.0))
	out = (car + tine) * amp * np.interp(t, [0, 0.002, total], [0, 1, 1])
	return out / (np.max(np.abs(out)) + 1e-9)


def bell(f: float, *, music_box: bool = False) -> np.ndarray:
	"""Glockenspiel (inharmonic) or music box (near-harmonic tine)."""
	t = _t(2.5 if music_box else 2.0)
	if music_box:
		parts = ((1.0, 1.0, 2.2), (2.0, 0.12, 5.0), (4.07, 0.18, 9.0), (6.8, 0.06, 18.0))
	else:
		parts = ((1.0, 1.0, 2.6), (2.76, 0.45, 7.0), (5.40, 0.22, 13.0), (8.93, 0.10, 24.0))
	out = np.zeros_like(t)
	for ratio, amp, dec in parts:
		if f * ratio < 18000:
			out += amp * np.exp(-t * dec) * np.sin(2 * np.pi * f * ratio * t)
	out *= np.interp(t, [0, 0.0015, t[-1]], [0, 1, 1])
	return out / (np.max(np.abs(out)) + 1e-9)


def bass(f: float, dur: float, *, soft: bool = False) -> np.ndarray:
	total = dur + 0.12
	t = _t(total)
	br = np.exp(-t * (6.0 if not soft else 3.0))
	out = np.zeros_like(t)
	for k in range(1, 9):
		a_k = (1.0 / k) * (br * 0.8 + 0.2) ** (k - 1) * (0.5 if soft and k > 2 else 1.0)
		out += a_k * np.sin(2 * np.pi * f * k * t)
	amp = np.interp(t, [0, 0.006 if not soft else 0.03, 0.15, max(dur, 0.16), total],
		[0, 1, 0.75, 0.65, 0])
	out = np.tanh(out * amp * 1.6)
	return out / (np.max(np.abs(out)) + 1e-9)


def kick(soft: bool = False) -> np.ndarray:
	t = _t(0.45)
	freq = 48 + 110 * np.exp(-t * 28)
	body = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t * (7.0 if not soft else 9.0))
	click = rng.standard_normal(len(t)) * np.exp(-t * 400) * (0.25 if not soft else 0.08)
	out = np.tanh((body + click) * 1.4)
	return out / np.max(np.abs(out))


def snare() -> np.ndarray:
	t = _t(0.35)
	tone = (np.sin(2 * np.pi * 185 * t) + 0.5 * np.sin(2 * np.pi * 330 * t)) * np.exp(-t * 28)
	nz = signal.sosfilt(_BP_SNARE, rng.standard_normal(len(t))) * np.exp(-t * 17)
	out = tone * 0.45 + nz * 1.6
	return out / np.max(np.abs(out))


def clap() -> np.ndarray:
	t = _t(0.3)
	nz = signal.sosfilt(_BP_CLAP, rng.standard_normal(len(t)))
	env = np.zeros_like(t)
	for d in (0.0, 0.011, 0.023):
		env += np.where(t >= d, np.exp(-(t - d) * 90), 0)
	env += np.where(t >= 0.03, np.exp(-(t - 0.03) * 14), 0) * 0.7
	out = nz * env
	return out / np.max(np.abs(out))


def hat(open_: bool = False) -> np.ndarray:
	t = _t(0.45 if open_ else 0.08)
	out = signal.sosfilt(_HP_HAT, rng.standard_normal(len(t))) * np.exp(-t * (9 if open_ else 70))
	return out / np.max(np.abs(out))


def shaker() -> np.ndarray:
	t = _t(0.14)
	env = np.interp(t, [0, 0.025, 0.14], [0, 1, 0]) ** 2
	out = signal.sosfilt(_HP_SHAKER, rng.standard_normal(len(t))) * env
	return out / np.max(np.abs(out))


def rim() -> np.ndarray:
	t = _t(0.12)
	out = np.sin(2 * np.pi * 820 * t) * np.exp(-t * 70) * 0.6
	out += signal.sosfilt(_BP_RIM, rng.standard_normal(len(t))) * np.exp(-t * 110)
	return out / np.max(np.abs(out))


def crash(seconds: float = 3.5) -> np.ndarray:
	t = _t(seconds)
	nz = signal.sosfilt(_HP_CRASH, rng.standard_normal(len(t)))
	shimmer = sum(np.sin(2 * np.pi * fr * t + p) for fr, p in ((5230, 0), (6810, 1), (8430, 2))) * 0.05
	out = (nz + shimmer) * np.exp(-t * 1.3) * np.interp(t, [0, 0.004, seconds], [0, 1, 1])
	return out / np.max(np.abs(out))


def swell(seconds: float) -> np.ndarray:
	"""Reverse-cymbal riser."""
	return crash(seconds)[::-1].copy()


def timpani(f: float) -> np.ndarray:
	t = _t(1.6)
	fr = f * (1 + 0.04 * np.exp(-t * 20))
	ph = 2 * np.pi * np.cumsum(fr) / SR
	out = (np.sin(ph) + 0.5 * np.sin(1.5 * ph) * np.exp(-t * 3) + 0.3 * np.sin(1.98 * ph) * np.exp(-t * 4))
	out *= np.exp(-t * 2.6)
	n = int(0.015 * SR)
	out[:n] += rng.standard_normal(n) * np.exp(-np.arange(n) / SR * 250) * 0.4
	return out / np.max(np.abs(out))


# --- mixing ----------------------------------------------------------------------

class Mix:
	def __init__(self, seconds: float, bpm: float, offset_beats: float = 0.0) -> None:
		self.n = int(seconds * SR)
		self.dry = np.zeros((2, self.n))
		self.wet = np.zeros(self.n)
		self.beat = 60.0 / bpm
		self.offset_beats = offset_beats

	def sec(self, bar: float, beat: float = 0.0) -> float:
		return (self.offset_beats + bar * 4 + beat) * self.beat

	def add(self, sig: np.ndarray, at_sec: float, gain: float, pan: float = 0.0,
			send: float = 0.2) -> None:
		i0 = int(round(at_sec * SR))
		if i0 >= self.n or i0 < 0:
			return
		s = sig[: self.n - i0] * gain
		ang = (pan + 1.0) * math.pi / 4.0
		self.dry[0, i0:i0 + len(s)] += s * math.cos(ang) * math.sqrt(2)
		self.dry[1, i0:i0 + len(s)] += s * math.sin(ang) * math.sqrt(2)
		self.wet[i0:i0 + len(s)] += s * send

	def render(self, *, t60: float, wet_ratio: float) -> np.ndarray:
		ir_len = int(min(t60 * 1.1, 4.0) * SR)
		t = np.arange(ir_len) / SR
		env = 10.0 ** (-3.0 * t / t60)
		ir = rng.standard_normal((2, ir_len)) * env
		ir = signal.sosfilt(_LP_IR, ir, axis=1)
		pre = int(0.018 * SR)
		ir[:, :pre] = 0
		ir /= np.sqrt(np.sum(ir ** 2, axis=1, keepdims=True))
		rev = np.stack([signal.fftconvolve(self.wet, ir[c])[: self.n] for c in range(2)])
		dry_rms = np.sqrt(np.mean(self.dry ** 2)) + 1e-9
		rev_rms = np.sqrt(np.mean(rev ** 2)) + 1e-9
		return self.dry + rev * (dry_rms / rev_rms) * wet_ratio


def finalize(intro: np.ndarray, loop: np.ndarray, intro_sec: float, loop_sec: float) -> np.ndarray:
	"""Intro (cut at loop start) + circular loop (own tail folded onto its start)."""
	n_i = int(round(intro_sec * SR))
	n_l = int(round(loop_sec * SR))
	body = loop[:, :n_l].copy()
	tail = loop[:, n_l:]
	body[:, : tail.shape[1]] += tail[:, :n_l]
	body = signal.sosfilt(_HP_MASTER, np.concatenate([body, body], axis=1), axis=1)[:, n_l:]  # circular
	head = signal.sosfilt(_HP_MASTER, intro[:, :n_i], axis=1) if n_i else np.zeros((2, 0))
	fade = min(int(0.012 * SR), n_i)  # intro ringing is cut under the loop downbeat
	if fade:
		head[:, -fade:] *= np.linspace(1, 0, fade)
	gain = 0.22 / (np.sqrt(np.mean(body ** 2)) + 1e-9)
	out = np.concatenate([head, body], axis=1) * gain
	out = np.tanh(out * 1.1) / 1.1  # gentle glue / soft limiting (memoryless → loop stays seamless)
	out *= 0.89 / np.max(np.abs(out))
	if n_i:  # pure loops (no intro) stay untouched so the seam is clean
		fade = int(0.004 * SR)
		out[:, :fade] *= np.linspace(0, 1, fade)
	return out


def loop_only(lm: "Mix", loop_sec: float, *, t60: float, wet_ratio: float) -> tuple[np.ndarray, float]:
	"""Whole file loops (loop_offset 0)."""
	body = lm.render(t60=t60, wet_ratio=wet_ratio)
	return finalize(np.zeros((2, 0)), body, 0.0, loop_sec), 0.0


def write_ogg(path: str, audio: np.ndarray, quality: int = 5) -> None:
	ffmpeg = shutil.which("ffmpeg")
	if not ffmpeg:
		try:
			import imageio_ffmpeg

			ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
		except Exception as exc:  # noqa: BLE001
			raise RuntimeError("ffmpeg not found (PATH or imageio-ffmpeg)") from exc
	fd, wav_tmp = tempfile.mkstemp(suffix=".wav")
	os.close(fd)
	try:
		pcm = (np.clip(audio.T, -1, 1) * 32767).astype("<i2")
		with wave.open(wav_tmp, "w") as wav:
			wav.setnchannels(2)
			wav.setsampwidth(2)
			wav.setframerate(SR)
			wav.writeframes(pcm.tobytes())
		subprocess.run([ffmpeg, "-y", "-hide_banner", "-loglevel", "error", "-i", wav_tmp,
			"-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
	finally:
		os.remove(wav_tmp)
	print(f"wrote {os.path.relpath(path, ROOT)} ({audio.shape[1] / SR:.2f}s, "
		f"{os.path.getsize(path)} bytes)")


# --- harmony helpers -------------------------------------------------------------

def chord(root: str, minor: bool) -> tuple[int, list[int], list[int]]:
	"""(bass midi, pad voicing near A3..B4, arp tones)."""
	pc = _PC[root]
	b = 36 + (pc - 36) % 12  # C2..B2
	pcs = [pc, (pc + (3 if minor else 4)) % 12, (pc + 7) % 12]
	pad = sorted(55 + (p - 55) % 12 for p in pcs)
	r = b + 12
	arp = [r, r + 7, r + 12, r + 12 + (3 if minor else 4), r + 19]
	return b, pad, arp


def place_melody(mix: Mix, bar0: int, notes: list[tuple[str, float]], fn, **add_kw) -> None:
	beat = 0.0
	for name, length in notes:
		if name != "-":
			mix.add(fn(hz(midi(name)), length * mix.beat), mix.sec(bar0, beat), **add_kw)
		beat += length


# --- WIN -------------------------------------------------------------------------

def win_theme() -> tuple[np.ndarray, float]:
	bpm = 120.0
	intro_bars, loop_bars = 2, 8
	beat = 60.0 / bpm
	loop_start = intro_bars * 4 * beat
	loop_end = (intro_bars + loop_bars) * 4 * beat
	im = Mix(loop_start + TAIL_SEC, bpm, offset_beats=intro_bars * 4)  # intro: bar -2 at t=0
	lm = Mix(loop_end - loop_start + TAIL_SEC, bpm)  # loop: bar 0 at t=0

	def brass(f, d):
		return additive(f, d, rolloff=0.28, attack=0.035, release=0.25, vibrato=0.005, detune=0.0025)

	def brass_section(f, d):
		return additive(f, d, rolloff=0.45, attack=0.05, release=0.3, detune=0.003, max_k=14)

	def lead(f, d):
		return additive(f, d, rolloff=0.6, attack=0.02, release=0.18, vibrato=0.006, detune=0.002, max_k=12)

	def pad(f, d):
		return additive(f, d, rolloff=0.9, attack=0.35, release=0.9, vibrato=0.003, detune=0.004,
			bright_env=False, max_k=10)

	def pluck(f, d):
		return struck(f, d, decay=3.0, decay_k=1.2, rolloff=1.1, ring=0.4, hammer=0.0, inharm=0.0)

	# Intro: bars -2, -1 — fanfare on D, then G → A with a riser into the loop.
	tri = 1.0 / 3.0
	place_melody(im, -2, [("A4", tri), ("A4", tri), ("A4", tri), ("D5", 1.5), ("C#5", 0.5), ("D5", 1.0)],
		brass, gain=0.55, pan=0.05, send=0.3)
	place_melody(im, -1, [("E5", 0.5), ("F#5", 0.5), ("A5", 3.0)], brass, gain=0.55, pan=0.05, send=0.32)
	for bar, start, length, root in ((-2, 1.0, 3.0, "D"), (-1, 0.0, 2.0, "G"), (-1, 2.0, 2.0, "A")):
		_, voicing, _ = chord(root, False)
		for m in voicing:
			im.add(brass_section(hz(m), length * beat), im.sec(bar, start), 0.16, pan=-0.25, send=0.35)
		b, _, _ = chord(root, False)
		im.add(bass(hz(b), length * beat), im.sec(bar, start), 0.45, send=0.05)
	for i in range(3):
		im.add(timpani(hz(midi("A2"))), im.sec(-2, i * tri), 0.45, pan=-0.1, send=0.25)
	im.add(timpani(hz(midi("D2"))), im.sec(-2, 1.0), 0.6, pan=-0.1, send=0.25)
	im.add(crash(), im.sec(-2, 1.0), 0.22, pan=0.3, send=0.2)
	for i in range(16):  # snare roll crescendo in the last bar
		im.add(snare(), im.sec(-1, i * 0.25), 0.08 + 0.22 * (i / 15) ** 2, pan=0.1, send=0.2)
	sw = swell(2 * beat)
	im.add(sw, im.sec(0) - len(sw) / SR, 0.18, pan=-0.2, send=0.1)

	# Loop: Canon progression.
	prog = [("D", False), ("A", False), ("B", True), ("F#", True),
		("G", False), ("D", False), ("G", False), ("A", False)]
	melody = [
		[("F#5", 1), ("A5", 0.5), ("F#5", 0.5), ("D5", 1), ("E5", 0.5), ("F#5", 0.5)],
		[("E5", 1.5), ("C#5", 0.5), ("A4", 1), ("C#5", 0.5), ("E5", 0.5)],
		[("D5", 1), ("F#5", 0.5), ("D5", 0.5), ("B4", 1), ("C#5", 0.5), ("D5", 0.5)],
		[("C#5", 1.5), ("A4", 0.5), ("C#5", 1), ("E5", 1)],
		[("B5", 1), ("A5", 0.5), ("G5", 0.5), ("F#5", 1), ("G5", 0.5), ("A5", 0.5)],
		[("F#5", 1.5), ("D5", 0.5), ("A5", 2)],
		[("G5", 0.5), ("F#5", 0.5), ("E5", 0.5), ("D5", 0.5), ("B4", 1), ("D5", 1)],
		[("C#5", 1), ("E5", 1), ("A5", 1.5), ("-", 0.5)],
	]
	arp_pat = [0, 1, 2, 3, 4, 3, 2, 1]
	for bar, ((root, minor), mel) in enumerate(zip(prog, melody)):
		b, voicing, arp = chord(root, minor)
		full = bar >= 4
		for m in voicing:
			lm.add(pad(hz(m), 4 * beat), lm.sec(bar), 0.10 if not full else 0.13, pan=-0.35, send=0.5)
		place_melody(lm, bar, mel, lead, gain=0.40, pan=0.12, send=0.28)
		if full:
			place_melody(lm, bar, [(n[:-1] + str(int(n[-1]) + 1) if n != "-" else n, d) for n, d in mel],
				lambda f, d: bell(f), gain=0.17, pan=0.35, send=0.35)
			for st in (1.5, 3.5):  # brass offbeat stabs
				for m in voicing:
					lm.add(brass_section(hz(m + 12), 0.22), lm.sec(bar, st), 0.07, pan=-0.2, send=0.3)
		for i, idx in enumerate(arp_pat):
			lm.add(pluck(hz(arp[idx]), 0.45 * beat), lm.sec(bar, i * 0.5),
				0.15 if i % 2 == 0 else 0.11, pan=-0.45 + 0.1 * (i % 3), send=0.25)
		for i, (st, oct_) in enumerate(((0, 0), (1, 12), (1.5, 0), (2, 0), (2.5, 12), (3, 0), (3.5, 7))):
			lm.add(bass(hz(b + oct_), 0.42 * beat), lm.sec(bar, st), 0.40 if oct_ == 0 else 0.28, send=0.04)
		# drums
		for st in (0, 2, 2.5):
			lm.add(kick(), lm.sec(bar, st), 0.75 if st != 2.5 else 0.5, send=0.04)
		for st in (1, 3):
			lm.add(snare(), lm.sec(bar, st), 0.30, pan=0.05, send=0.22)
			lm.add(clap(), lm.sec(bar, st), 0.16, pan=-0.05, send=0.25)
		for i in range(8):
			if i == 7:
				lm.add(hat(True), lm.sec(bar, 3.5), 0.10, pan=0.3, send=0.1)
			else:
				lm.add(hat(), lm.sec(bar, i * 0.5), 0.10 if i % 2 else 0.06, pan=0.3, send=0.05)
		if full:
			for i in range(16):
				lm.add(shaker(), lm.sec(bar, i * 0.25), 0.05 if i % 2 else 0.03, pan=-0.4, send=0.08)
		if bar in (0, 4):
			lm.add(crash(), lm.sec(bar), 0.18, pan=0.35, send=0.2)

	intro = im.render(t60=1.8, wet_ratio=0.38)
	body = lm.render(t60=1.8, wet_ratio=0.38)
	return finalize(intro, body, loop_start, loop_end - loop_start), loop_start


# --- LOSE ------------------------------------------------------------------------

def lose_theme() -> tuple[np.ndarray, float]:
	bpm = 80.0
	intro_bars, loop_bars = 2, 8
	beat = 60.0 / bpm
	loop_start = intro_bars * 4 * beat
	loop_end = (intro_bars + loop_bars) * 4 * beat
	im = Mix(loop_start + TAIL_SEC, bpm, offset_beats=intro_bars * 4)  # intro: bar -2 at t=0
	lm = Mix(loop_end - loop_start + TAIL_SEC, bpm)  # loop: bar 0 at t=0

	def piano(f, d, vel=0.8):
		return struck(f, d, vel=vel, decay=0.9, decay_k=0.55, rolloff=1.5, ring=1.8, hammer=0.08)

	def soft_piano(f, d):
		return piano(f, d, 0.45)

	def pad(f, d):
		return additive(f, d, rolloff=1.2, attack=0.7, release=1.4, vibrato=0.0025, detune=0.004,
			bright_env=False, max_k=8)

	def music_box(f, d):
		return bell(f, music_box=True)

	# Intro: soft descending sigh over Am, then F → E.
	place_melody(im, -2, [("E5", 1), ("D5", 1), ("C5", 1), ("B4", 1)], piano, gain=0.42, pan=0.1, send=0.45)
	place_melody(im, -1, [("A4", 2), ("G#4", 2)], piano, gain=0.42, pan=0.1, send=0.5)
	for bar, start, length, root, minor in ((-2, 0, 4, "A", True), (-1, 0, 2, "F", False), (-1, 2, 2, "E", False)):
		b, voicing, _ = chord(root, minor)
		for m in voicing:
			im.add(pad(hz(m), length * beat), im.sec(bar, start), 0.11, pan=-0.3, send=0.6)
		im.add(bass(hz(b), length * beat, soft=True), im.sec(bar, start), 0.32, send=0.08)

	# Loop: Am F C G F C Dm E — bittersweet but hopeful ("try again!").
	prog = [("A", True), ("F", False), ("C", False), ("G", False),
		("F", False), ("C", False), ("D", True), ("E", False)]
	melody = [
		[("E5", 1.5), ("D5", 0.5), ("C5", 1), ("A4", 1)],
		[("C5", 1.5), ("A4", 0.5), ("F4", 1), ("A4", 1)],
		[("G4", 1.5), ("C5", 0.5), ("E5", 2)],
		[("D5", 2), ("B4", 1), ("D5", 1)],
		[("C5", 1), ("A4", 0.5), ("C5", 0.5), ("F5", 1.5), ("E5", 0.5)],
		[("E5", 1.5), ("D5", 0.5), ("C5", 2)],
		[("A4", 1), ("D5", 1), ("F5", 1), ("E5", 0.5), ("D5", 0.5)],
		[("B4", 2), ("G#4", 1), ("B4", 1)],
	]
	arp_pat = [0, 1, 2, 3, 2, 1, 2, 1]
	for bar, ((root, minor), mel) in enumerate(zip(prog, melody)):
		b, voicing, arp = chord(root, minor)
		full = bar >= 4
		for m in voicing:
			lm.add(pad(hz(m), 4 * beat), lm.sec(bar), 0.10, pan=-0.3, send=0.6)
		place_melody(lm, bar, mel, piano, gain=0.40, pan=0.1, send=0.42)
		if full:
			place_melody(lm, bar, [(n[:-1] + str(int(n[-1]) + 1), d) for n, d in mel],
				music_box, gain=0.13, pan=0.4, send=0.5)
		for i, idx in enumerate(arp_pat):
			lm.add(soft_piano(hz(arp[idx] - 12 if idx >= 3 else arp[idx]), 0.5 * beat),
				lm.sec(bar, i * 0.5), 0.17 if i % 2 == 0 else 0.13, pan=-0.25, send=0.4)
		lm.add(bass(hz(b), 2.6 * beat, soft=True), lm.sec(bar), 0.34, send=0.06)
		lm.add(bass(hz(b), 0.9 * beat, soft=True), lm.sec(bar, 3), 0.22, send=0.06)
		# soft brushes: shaker throughout, kick + rim in the second half
		for i in range(8):
			lm.add(shaker(), lm.sec(bar, i * 0.5), 0.05 if i % 2 else 0.035, pan=0.35, send=0.15)
		if full or bar in (2, 3):
			for st in (0, 2.5):
				lm.add(kick(soft=True), lm.sec(bar, st), 0.42 if st == 0 else 0.3, send=0.05)
			for st in (1, 3):
				lm.add(rim(), lm.sec(bar, st), 0.10, pan=-0.1, send=0.3)

	intro = im.render(t60=2.6, wet_ratio=0.5)
	body = lm.render(t60=2.6, wet_ratio=0.5)
	return finalize(intro, body, loop_start, loop_end - loop_start), loop_start


# --- shared battle-loop parts ------------------------------------------------------

def _string_stab(f, d):
	return additive(f, d, rolloff=0.5, attack=0.008, release=0.09, detune=0.004, max_k=16)


def _brass(f, d):
	return additive(f, d, rolloff=0.28, attack=0.03, release=0.22, vibrato=0.005, detune=0.0025)


def _horn(f, d):
	return additive(f, d, rolloff=0.55, attack=0.06, release=0.3, vibrato=0.004, detune=0.003, max_k=14)


def _pad(f, d):
	return additive(f, d, rolloff=0.9, attack=0.3, release=0.8, vibrato=0.003, detune=0.004,
		bright_env=False, max_k=10)


def _pluck(f, d):
	return struck(f, d, decay=3.0, decay_k=1.2, rolloff=1.1, ring=0.4, hammer=0.0, inharm=0.0)


def _octave_up(notes: list[tuple[str, float]]) -> list[tuple[str, float]]:
	return [(n if n == "-" else n[:-1] + str(int(n[-1]) + 1), d) for n, d in notes]


def _drum_bar(m: Mix, bar: int, *, kicks, snares, kick_gain=0.7, snare_gain=0.3, clap_gain=0.14,
		hat_gain=0.09, sixteenth_hats=False, open_hat=True, shaker_gain=0.0) -> None:
	for st in kicks:
		m.add(kick(), m.sec(bar, st), kick_gain if st % 1 == 0 else kick_gain * 0.7, send=0.04)
	for st in snares:
		m.add(snare(), m.sec(bar, st), snare_gain, pan=0.05, send=0.22)
		if clap_gain:
			m.add(clap(), m.sec(bar, st), clap_gain, pan=-0.05, send=0.25)
	step = 0.25 if sixteenth_hats else 0.5
	for i in range(int(4 / step)):
		st = i * step
		if open_hat and st == 3.5:
			m.add(hat(True), m.sec(bar, st), hat_gain * 1.1, pan=0.3, send=0.1)
		elif not (open_hat and st == 3.75):
			accent = (st % 1) == 0.5
			m.add(hat(), m.sec(bar, st), hat_gain if accent else hat_gain * 0.6, pan=0.3, send=0.05)
	if shaker_gain:
		for i in range(16):
			m.add(shaker(), m.sec(bar, i * 0.25), shaker_gain if i % 2 else shaker_gain * 0.6, pan=-0.4, send=0.08)


def _tom_fill(m: Mix, bar: int, start_beat: float, notes: list[str], gain: float = 0.4) -> None:
	for i, name in enumerate(notes):
		m.add(timpani(hz(midi(name))), m.sec(bar, start_beat + i * 0.25), gain, pan=-0.3 + 0.1 * i, send=0.2)


# --- BATTLE ------------------------------------------------------------------------

def battle_theme() -> tuple[np.ndarray, float]:
	"""G major, 124 BPM, 16 bars: groove (A) → melody (B). Leaves room to think."""
	bpm = 124.0
	beat = 60.0 / bpm
	bars = 16
	lm = Mix(bars * 4 * beat + TAIL_SEC, bpm)
	prog = [("G", False), ("D", False), ("E", True), ("C", False),
		("G", False), ("D", False), ("C", False), ("D", False)] * 2
	melody = [
		[("B4", 0.5), ("D5", 0.5), ("G5", 1), ("F#5", 0.5), ("E5", 0.5), ("D5", 1)],
		[("A4", 1), ("D5", 0.5), ("E5", 0.5), ("F#5", 1.5), ("-", 0.5)],
		[("G5", 1), ("E5", 0.5), ("B4", 0.5), ("E5", 1), ("G5", 0.5), ("F#5", 0.5)],
		[("E5", 1.5), ("D5", 0.5), ("C5", 1), ("-", 1)],
		[("D5", 0.5), ("G5", 0.5), ("B5", 1), ("A5", 0.5), ("G5", 0.5), ("D5", 1)],
		[("F#5", 1), ("A5", 1), ("D5", 1.5), ("-", 0.5)],
		[("E5", 0.5), ("G5", 0.5), ("C6", 1), ("B5", 0.5), ("A5", 0.5), ("G5", 1)],
		[("A5", 1.5), ("F#5", 0.5), ("D5", 1), ("-", 1)],
	]
	# A section: sparse glockenspiel call-and-answer.
	motif = [[("D6", 0.5), ("B5", 0.5), ("-", 3)], [("-", 2), ("A5", 0.5), ("F#5", 0.5), ("-", 1)]]

	def lead(f, d):
		return additive(f, d, rolloff=0.55, attack=0.02, release=0.18, vibrato=0.006, detune=0.002, max_k=12)

	arp_pat = [0, 1, 2, 3, 4, 3, 2, 1]
	for bar, (root, minor) in enumerate(prog):
		b, voicing, arp = chord(root, minor)
		b_sec = bar >= 8
		for m in voicing:
			lm.add(_pad(hz(m), 4 * beat), lm.sec(bar), 0.09, pan=-0.35, send=0.5)
		if b_sec:
			place_melody(lm, bar, melody[bar - 8], lead, gain=0.36, pan=0.12, send=0.28)
		elif bar % 4 < 2:
			place_melody(lm, bar, motif[bar % 2], lambda f, d: bell(f), gain=0.14, pan=0.4, send=0.4)
		for i, idx in enumerate(arp_pat):
			lm.add(_pluck(hz(arp[idx]), 0.45 * beat), lm.sec(bar, i * 0.5),
				0.14 if i % 2 == 0 else 0.10, pan=-0.45 + 0.1 * (i % 3), send=0.25)
		for st, oct_ in ((0, 0), (0.75, 0), (1.5, 12), (2, 0), (2.75, 0), (3.5, 7)):
			lm.add(bass(hz(b + oct_), 0.4 * beat), lm.sec(bar, st), 0.40 if oct_ == 0 else 0.28, send=0.04)
		for st in (0.5, 2.5):  # light offbeat string chops
			for m in voicing:
				lm.add(_string_stab(hz(m + 12), 0.18), lm.sec(bar, st), 0.05, pan=-0.15, send=0.25)
		_drum_bar(lm, bar, kicks=(0, 1.5, 2, 2.75) if b_sec else (0, 2, 2.75), snares=(1, 3),
			shaker_gain=0.04 if b_sec else 0.0)
		if bar in (0, 8):
			lm.add(crash(), lm.sec(bar), 0.16, pan=0.35, send=0.2)
		if bar in (7, 15):
			_tom_fill(lm, bar, 3.0, ["A3", "F#3", "D3", "A2"], gain=0.28)
	return loop_only(lm, bars * 4 * beat, t60=1.6, wet_ratio=0.32)


# --- EXAM --------------------------------------------------------------------------

def exam_theme() -> tuple[np.ndarray, float]:
	"""E minor, 132 BPM, 16 bars: string ostinato + timpani → brass theme. Serious but heroic."""
	bpm = 132.0
	beat = 60.0 / bpm
	bars = 16
	lm = Mix(bars * 4 * beat + TAIL_SEC, bpm)
	prog = [("E", True), ("C", False), ("A", True), ("B", False)] * 2 + [
		("C", False), ("D", False), ("B", True), ("E", True),
		("C", False), ("D", False), ("B", False), ("B", False)]
	horn = [
		[("E4", 1.5), ("B3", 0.5), ("E4", 2)], [("G4", 1.5), ("E4", 0.5), ("C5", 2)],
		[("A4", 1), ("C5", 1), ("E5", 2)], [("D#5", 2), ("B4", 2)],
	]
	melody = [
		[("E5", 1.5), ("D5", 0.5), ("C5", 1), ("B4", 0.5), ("C5", 0.5)],
		[("D5", 1.5), ("C5", 0.5), ("A4", 2)],
		[("B4", 1), ("D5", 1), ("F#5", 1.5), ("E5", 0.5)],
		[("E5", 2), ("B4", 1), ("E5", 1)],
		[("G5", 1.5), ("F#5", 0.5), ("E5", 1), ("G5", 1)],
		[("A5", 1.5), ("G5", 0.5), ("F#5", 2)],
		[("D#5", 1), ("F#5", 1), ("B5", 2)],
		[("A5", 1), ("F#5", 1), ("D#5", 1), ("B4", 1)],
	]
	for bar, (root, minor) in enumerate(prog):
		b, voicing, _ = chord(root, minor)
		b_sec = bar >= 8
		for m in voicing:
			lm.add(_pad(hz(m), 4 * beat), lm.sec(bar), 0.10 if b_sec else 0.08, pan=-0.3, send=0.5)
		r = b + 24  # 16th string ostinato
		pat = [0, 0, 7, 0, 12, 0, 7, 0, 0, 0, 7, 0, 12, 7, 3 if minor else 4, 0]
		for i, iv in enumerate(pat):
			lm.add(_string_stab(hz(r + iv), 0.11), lm.sec(bar, i * 0.25),
				0.10 if i % 4 == 0 else 0.065, pan=-0.4 if i % 2 else -0.2, send=0.22)
		if b_sec:
			place_melody(lm, bar, melody[bar - 8], _brass, gain=0.42, pan=0.1, send=0.32)
		elif bar >= 4:
			place_melody(lm, bar, horn[bar - 4], _horn, gain=0.34, pan=0.15, send=0.35)
		for st in (0, 1.5, 2, 3, 3.5):
			lm.add(bass(hz(b), 0.35 * beat), lm.sec(bar, st), 0.40, send=0.04)
		lm.add(timpani(hz(b + 12)), lm.sec(bar), 0.45 if bar % 4 == 0 else 0.30, pan=-0.1, send=0.3)
		if bar % 2 == 1:
			lm.add(timpani(hz(b + 12)), lm.sec(bar, 3.5), 0.22, pan=-0.1, send=0.3)
		_drum_bar(lm, bar, kicks=(0, 1, 2, 3) if b_sec else (0, 2, 2.5), snares=(1, 3),
			clap_gain=0.0, snare_gain=0.26, hat_gain=0.07, sixteenth_hats=b_sec, open_hat=False)
		if bar in (0, 8, 12):
			lm.add(crash(), lm.sec(bar), 0.17, pan=0.35, send=0.2)
		if bar == 15:
			for i in range(8):  # snare roll into the loop start
				lm.add(snare(), lm.sec(bar, 2 + i * 0.25), 0.1 + 0.18 * i / 7, pan=0.1, send=0.2)
	return loop_only(lm, bars * 4 * beat, t60=2.0, wet_ratio=0.36)


# --- BOSS --------------------------------------------------------------------------

def boss_theme() -> tuple[np.ndarray, float]:
	"""D minor, 150 BPM, 16 bars: galloping bass + brass stabs → heroic brass melody."""
	bpm = 150.0
	beat = 60.0 / bpm
	bars = 16
	lm = Mix(bars * 4 * beat + TAIL_SEC, bpm)
	prog = [("D", True), ("D", True), ("A#", False), ("C", False),
		("D", True), ("D", True), ("A#", False), ("A", False),
		("G", True), ("G", True), ("D", True), ("D", True),
		("A#", False), ("C", False), ("A", False), ("A", False)]
	melody = [
		[("D5", 1), ("A#4", 0.5), ("G4", 0.5), ("D5", 1), ("F5", 1)],
		[("G5", 1.5), ("F5", 0.5), ("D5", 2)],
		[("F5", 1), ("E5", 0.5), ("D5", 0.5), ("A4", 1), ("D5", 1)],
		[("A5", 2), ("F5", 1), ("D5", 1)],
		[("F5", 1.5), ("D5", 0.5), ("A#4", 1), ("D5", 1)],
		[("E5", 1.5), ("G5", 0.5), ("C6", 2)],
		[("C#6", 1.5), ("A5", 0.5), ("E5", 1), ("C#5", 1)],
		[("A5", 2), ("E5", 1), ("C#5", 1)],
	]

	def heavy_bass(f, d):
		return np.tanh(bass(f, d) * 2.2)

	for bar, (root, minor) in enumerate(prog):
		b, voicing, _ = chord(root, minor)
		b_sec = bar >= 8
		for m in voicing:
			lm.add(_pad(hz(m), 4 * beat), lm.sec(bar), 0.09, pan=-0.3, send=0.5)
		for i in range(8):  # driving 8ths with octave pops
			oct_ = 12 if i in (3, 6) else 0
			lm.add(heavy_bass(hz(b + oct_), 0.42 * beat), lm.sec(bar, i * 0.5),
				0.36 if i % 2 == 0 else 0.30, send=0.03)
		for st in ((0, 0.75, 1.5, 3, 3.5) if not b_sec else (0, 1.5, 3)):  # syncopated brass stabs
			for m in voicing:
				lm.add(_brass(hz(m), 0.16), lm.sec(bar, st), 0.09 if not b_sec else 0.06, pan=-0.2, send=0.3)
		r = b + 24  # 16th string ostinato
		pat = [0, 12, 7, 12, 3 if minor else 4, 12, 7, 12] * 2
		for i, iv in enumerate(pat):
			lm.add(_string_stab(hz(r + iv), 0.09), lm.sec(bar, i * 0.25),
				0.08 if i % 4 == 0 else 0.05, pan=0.35, send=0.22)
		if b_sec:
			place_melody(lm, bar, melody[bar - 8], _brass, gain=0.42, pan=0.05, send=0.3)
			place_melody(lm, bar, _octave_up(melody[bar - 8]), lambda f, d: bell(f), gain=0.10, pan=0.4, send=0.35)
		lm.add(timpani(hz(b + 12)), lm.sec(bar), 0.5 if bar % 2 == 0 else 0.35, pan=-0.1, send=0.3)
		_drum_bar(lm, bar, kicks=(0, 1, 2, 2.5, 3), snares=(1, 3), kick_gain=0.72, snare_gain=0.32,
			clap_gain=0.12, hat_gain=0.08, sixteenth_hats=True, open_hat=False)
		if bar in (0, 4, 8, 12):
			lm.add(crash(), lm.sec(bar), 0.2, pan=0.35, send=0.2)
		if bar in (7, 15):
			_tom_fill(lm, bar, 2.0, ["A3", "A3", "F3", "F3", "D3", "D3", "A2", "A2"], gain=0.32)
	return loop_only(lm, bars * 4 * beat, t60=1.5, wet_ratio=0.3)


def main() -> None:
	themes = (
		("win_music.ogg", win_theme, 5),
		("lose_music.ogg", lose_theme, 5),
		("battle_music.ogg", battle_theme, 4),
		("exam_music.ogg", exam_theme, 4),
		("boss_music.ogg", boss_theme, 4),
	)
	for name, fn, quality in themes:
		audio, loop_offset = fn()
		write_ogg(os.path.join(MUSIC_DIR, name), audio, quality)
		print(f"  loop_offset={loop_offset:g} (set in {name}.import)")


if __name__ == "__main__":
	main()
