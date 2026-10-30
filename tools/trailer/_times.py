import json
from pathlib import Path

sc = json.loads(Path("tools/trailer/scenarios/color_ru.json").read_text(encoding="utf-8"))
X = sc["xfade"]
segs = sc["segments"]
durs = [(s["to"] - s["from"]) / s.get("speed", 1) for s in segs]
offset = 0.0
print("0.00", segs[0]["id"], round(durs[0], 2))
for i in range(1, len(segs)):
    xd = float(segs[i].get("xfade", X))
    offset += durs[i - 1] - xd
    print(round(offset, 2), segs[i]["id"], round(durs[i], 2))
print("total", round(sum(durs) - sum(float(segs[i].get("xfade", X)) for i in range(1, len(segs))), 2))
