"""Ganti sprite properti peta dengan aset paket 'Top-Down Simple Summer'.

Sprite properti digambar terpisah oleh scripts/world.gd (di atas PNG peta) dan
diurutkan menurut posisi kaki, jadi mengganti PNG-nya saja sudah cukup:
ukuran di layar tetap diatur oleh tinggi pada assets/maps/*.props.json.

Jalankan:  PACK=/tmp/gdz/PNG python3 tools/swap_props.py [--dry]
"""
import os
import sys
from PIL import Image

PACK = os.environ.get("PACK", "/tmp/gdz/PNG")
OUT = os.environ.get("OUT", "assets/sprites/props")
DRY = "--dry" in sys.argv

# nama sprite tujuan -> (berkas di paket, tinggi kanvas baru)
MAP = {
    "tree_big": ("Prop - Tree Large.png", 644),
    "bush": ("Prop - Bushes Large.png", 429),
    "rubble": ("Prop - Rock 03.png", 220),
    "crate": ("Prop - Wooden Barrel.png", 150),
    "crates": ("Prop - Wooden Cart.png", 260),
    "pillar": ("Prop - Watchtower Short.png", 300),
    "house": ("Prop - House.png", 300),
    "flag": ("Prop - Flag.png", 190),
    "banner_red": ("Prop - Red Banner.png", 170),
    "banner_blue": ("Prop - Blue Banner.png", 170),
    "fence_h": ("Prop - Wooden Fence Horizontal.png", 96),
    "fence_v": ("Prop - Wooden Fence Vertical.png", 96),
    "campfire": ("Prop - Campfire.png", 110),
}


def trim(im):
    bb = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    return im.crop(bb) if bb else im


def convert(src_name, target_h):
    src = os.path.join(PACK, "Top-Down Simple Summer_" + src_name)
    if not os.path.exists(src):
        # sebagian berkas memakai huruf kecil pada kata 'prop'
        alt = os.path.join(PACK, "Top-Down Simple Summer_" + src_name.replace("Prop", "prop"))
        src = alt if os.path.exists(alt) else src
    im = trim(Image.open(src).convert("RGBA"))
    sc = target_h / im.height
    w = max(1, int(round(im.width * sc)))
    return im.resize((w, target_h), Image.LANCZOS)


for name, (src_name, th) in MAP.items():
    art = convert(src_name, th)
    canvas_w = max(art.width + 8, int(round(th * 0.80)))
    canvas = Image.new("RGBA", (canvas_w, th), (0, 0, 0, 0))
    x = (canvas_w - art.width) // 2
    canvas.paste(art, (x, th - art.height), art)
    dst = os.path.join(OUT, name + ".png")
    print(f"{name}: {src_name} -> {canvas.size} (layar ±proporsi tetap)")
    if not DRY:
        canvas.save(dst)
