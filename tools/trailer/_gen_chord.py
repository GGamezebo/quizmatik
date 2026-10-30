"""One-shot end chord for the ad trailer. Writes bin/trailer/end_chord.wav."""
import math
import struct
import wave
from pathlib import Path

sr = 48000
dur = 1.2
n = int(sr * dur)
notes = (523.25, 659.25, 783.99, 1046.50)
samples = []
for i in range(n):
    t = i / sr
    env = min(1.0, t / 0.012) * math.exp(-2.6 * t)
    s = 0.0
    for f in notes:
        s += math.sin(2 * math.pi * f * t) * 0.22
        s += math.sin(2 * math.pi * f * 2 * t) * 0.05
    samples.append(max(-1.0, min(1.0, s * env)))

out = Path(__file__).resolve().parents[2] / "bin" / "trailer" / "end_chord.wav"
out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sr)
    w.writeframes(b"".join(struct.pack("<h", int(s * 28000)) for s in samples))
print(out)
