"""Render pratinjau satu peta penuh (tanah + properti) untuk dokumentasi.

Meniru cara scripts/world.gd menggambar: PNG peta sebagai latar, lalu setiap
entri <map>.props.json ditempel sebagai sprite dengan titik kaki di (x, y).

Pakai:  python3 tools/map_preview.py [outdir]
"""
import json
import os
import sys
from PIL import Image

MAPS = ["kota", "hutan", "pabrik", "candi", "danau", "source"]
OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/preview"
os.makedirs(OUT, exist_ok=True)

for mid in MAPS:
    base = Image.open("assets/maps/%s.png" % mid).convert("RGBA")
    props = json.load(open("assets/maps/%s.props.json" % mid))
    props.sort(key=lambda it: float(it["y"]))
    for it in props:
        name = str(it.get("n", "tree_big"))
        path = "assets/sprites/props/%s.png" % name
        if not os.path.exists(path):
            continue
        tex = Image.open(path).convert("RGBA")
        h = int(round(float(it.get("h", 120.0))))
        sc = h / tex.height
        w = max(1, int(round(tex.width * sc)))
        spr = tex.resize((w, h), Image.LANCZOS)
        x = int(round(float(it.get("x", 0)) - w / 2))
        y = int(round(float(it.get("y", 0)) - h))
        base.alpha_composite(spr, (x, y)) if (x >= 0 and y >= 0 and
                                             x + w <= base.width and y + h <= base.height) \
            else base.paste(spr, (x, y), spr)
    out = os.path.join(OUT, "%s.png" % mid)
    base.convert("RGB").save(out, quality=90)
    print(mid, base.size, "->", out)
