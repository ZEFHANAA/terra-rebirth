#!/usr/bin/env python3
"""Membuat aset properti low-poly (PNG) untuk peta Pabrik, Candi, dan The Source.

Gaya mengikuti aset yang sudah ada: bidang datar tanpa tekstur, cahaya lembut
dari kiri-atas, latar transparan, dan alas objek tepat di dasar gambar supaya
bisa ditempel di posisi kaki (world.gd memakai offset -tinggi/2).

Jalankan:  python3 tools/gen_props.py
Hasil:     assets/sprites/props/*.png
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

SS = 3  # supersampling
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "props")

# ---------------------------------------------------------------- proyeksi
COS30 = math.cos(math.radians(30.0))
SIN30 = math.sin(math.radians(30.0))
LIGHT = (-0.45, -0.62, 0.65)


def norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / l for c in v)


LIGHT = norm(LIGHT)


def project(p):
    """(x, y, z) dunia -> (sx, sy) layar, y ke bawah, z ke atas."""
    x, y, z = p
    return ((x - y) * COS30, (x + y) * SIN30 - z)


def depth(p):
    return (p[0] + p[1]) * COS30 + p[2] * SIN30


def shade(n, base):
    d = max(0.0, n[0] * LIGHT[0] + n[1] * LIGHT[1] + n[2] * LIGHT[2])
    k = 0.46 + 0.62 * d
    return tuple(min(255, int(c * k)) for c in base)


# ---------------------------------------------------------------- primitif
def box(cx, cy, cz, sx, sy, sz, color, top=None):
    """Balok dengan pusat (cx,cy,cz) dan ukuran penuh (sx,sy,sz)."""
    hx, hy, hz = sx / 2.0, sy / 2.0, sz / 2.0
    v = [
        (cx - hx, cy - hy, cz - hz), (cx + hx, cy - hy, cz - hz),
        (cx + hx, cy + hy, cz - hz), (cx - hx, cy + hy, cz - hz),
        (cx - hx, cy - hy, cz + hz), (cx + hx, cy - hy, cz + hz),
        (cx + hx, cy + hy, cz + hz), (cx - hx, cy + hy, cz + hz),
    ]
    faces = [
        ((0, 1, 2, 3), (0, 0, -1), color),
        ((4, 5, 6, 7), (0, 0, 1), top or color),
        ((0, 1, 5, 4), (0, -1, 0), color),
        ((2, 3, 7, 6), (0, 1, 0), color),
        ((1, 2, 6, 5), (1, 0, 0), color),
        ((3, 0, 4, 7), (-1, 0, 0), color),
    ]
    return [(v, faces)]


def cyl(cx, cy, z0, z1, r, color, top=None, seg=16):
    """Tabung tegak (sumbu z) dari z0 ke z1."""
    v = []
    for i in range(seg):
        a = 2.0 * math.pi * i / seg
        v.append((cx + r * math.cos(a), cy + r * math.sin(a), z0))
    for i in range(seg):
        a = 2.0 * math.pi * i / seg
        v.append((cx + r * math.cos(a), cy + r * math.sin(a), z1))
    faces = []
    for i in range(seg):
        j = (i + 1) % seg
        a = 2.0 * math.pi * (i + 0.5) / seg
        n = (math.cos(a), math.sin(a), 0.0)
        faces.append(((i, j, seg + j, seg + i), n, color))
    faces.append((tuple(range(seg, 2 * seg)), (0, 0, 1), top or color))
    faces.append((tuple(range(seg - 1, -1, -1)), (0, 0, -1), color))
    return [(v, faces)]


def pipe_x(cx, cy, cz, length, r, color, seg=12):
    """Pipa mendatar sepanjang sumbu x."""
    v = []
    for i in range(seg):
        a = 2.0 * math.pi * i / seg
        v.append((cx - length / 2, cy + r * math.cos(a), cz + r * math.sin(a)))
    for i in range(seg):
        a = 2.0 * math.pi * i / seg
        v.append((cx + length / 2, cy + r * math.cos(a), cz + r * math.sin(a)))
    faces = []
    for i in range(seg):
        j = (i + 1) % seg
        a = 2.0 * math.pi * (i + 0.5) / seg
        faces.append(((i, j, seg + j, seg + i), (0.0, math.cos(a), math.sin(a)), color))
    return [(v, faces)]


# ---------------------------------------------------------------- render
def render(parts, pad=8):
    verts = []
    polys = []
    for v, faces in parts:
        base = len(verts)
        verts.extend(v)
        for idx, n, col in faces:
            polys.append(([base + i for i in idx], n, col))

    proj = [project(p) for p in verts]
    xs = [p[0] for p in proj]
    ys = [p[1] for p in proj]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    w = int(math.ceil((maxx - minx + pad * 2) * SS))
    h = int(math.ceil((maxy - miny + pad * 2) * SS))
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)

    def to_px(i):
        p = proj[i]
        return ((p[0] - minx + pad) * SS, (p[1] - miny + pad) * SS)

    order = []
    for idx, n, col in polys:
        d = sum(depth(verts[i]) for i in idx) / len(idx)
        order.append((d, idx, n, col))
    order.sort(key=lambda t: t[0])

    for d, idx, n, col in order:
        # buang sisi yang menghadap menjauh (normal . arah pandang)
        if n[0] * 1.0 + n[1] * 1.0 + n[2] * 0.9 <= 0.02:
            continue
        pts = [to_px(i) for i in idx]
        dr.polygon(pts, fill=shade(n, col) + (255,))

    img = img.resize((max(1, w // SS), max(1, h // SS)), Image.LANCZOS)
    return img


def shadow(img, spread=0.55, alpha=70):
    """Bayangan lembut di alas objek."""
    w, h = img.size
    lay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    rx = int(w * spread * 0.5)
    ry = max(6, int(rx * 0.32))
    d.ellipse([w // 2 - rx, h - ry * 2, w // 2 + rx, h - 2], fill=(20, 26, 34, alpha))
    lay = lay.filter(ImageFilter.GaussianBlur(max(3, w // 40)))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(lay)
    out.alpha_composite(img)
    return out


EDGE = (38, 36, 34)


def posterize(img, step=14):
    """Kurangi jumlah warna supaya terbaca sebagai gambar datar, bukan render 3D."""
    r, g, b, a = img.split()
    f = lambda ch: ch.point(lambda v: min(255, int(round(v / step)) * step))
    return Image.merge("RGBA", (f(r), f(g), f(b), a))


def outline(img, width=2, color=EDGE):
    """Garis tepi gelap di sekeliling siluet (gaya aset paket kartun)."""
    a = img.split()[3]
    mask = a.point(lambda v: 255 if v > 60 else 0)
    grown = mask.filter(ImageFilter.MaxFilter(width * 2 + 1))
    lay = Image.new("RGBA", img.size, color + (255,))
    lay.putalpha(grown)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(lay)
    out.alpha_composite(img)
    return out


def save(name, parts):
    img = render(parts)
    img = posterize(img)
    img = outline(img)
    img = shadow(img, spread=0.5, alpha=64)
    img.save(os.path.join(OUT, name + ".png"))
    print("  ", name, img.size)


# ---------------------------------------------------------------- aset
STEEL = (96, 118, 138)
STEEL_D = (68, 86, 104)
STEEL_L = (150, 170, 188)
RUST = (188, 108, 62)
ORANGE = (232, 150, 52)
CYAN = (96, 214, 226)
DARK = (44, 54, 66)
STONE = (208, 190, 154)
STONE_D = (168, 150, 118)
STONE_L = (230, 216, 184)
MOSS = (116, 142, 98)
WOOD = (150, 108, 70)


def prop_tank():
    p = []
    p += cyl(0, 0, 0, 26, 26, STEEL_D, STEEL)          # dudukan
    p += cyl(0, 0, 22, 96, 40, STEEL, STEEL_L)          # badan tangki
    p += cyl(0, 0, 96, 108, 40, RUST, RUST)             # cincin atas
    p += cyl(0, 0, 108, 118, 18, STEEL_D, STEEL)        # tutup
    p += box(0, -40, 60, 6, 6, 74, RUST)                # pipa tegak di sisi
    return p


def prop_chimney():
    p = []
    p += box(0, 0, 6, 62, 62, 12, STONE_D)              # alas
    p += cyl(0, 0, 12, 190, 24, RUST, STONE)            # cerobong
    p += cyl(0, 0, 150, 162, 26, STONE_D, STONE)        # ring
    p += cyl(0, 0, 190, 198, 26, DARK, DARK)            # mulut
    return p


def prop_machine():
    p = []
    p += box(0, 0, 8, 74, 54, 16, STEEL_D, STEEL)       # kaki
    p += box(0, 0, 40, 66, 46, 50, STEEL, STEEL_L)      # badan
    p += box(0, -24, 44, 40, 6, 26, DARK, DARK)         # panel gelap
    p += box(10, -24, 30, 12, 4, 8, ORANGE, ORANGE)     # lampu
    p += box(0, 0, 68, 30, 30, 8, RUST, RUST)           # cerobong kecil
    return p


def prop_conveyor():
    p = []
    p += box(0, 0, 14, 150, 34, 10, STEEL_D, STEEL)     # rangka
    for i in range(5):
        p += cyl(-58 + i * 29, 0, 18, 22, 12, DARK, STEEL_L, seg=12)
    p += box(0, 0, 26, 150, 10, 4, RUST)                # rel
    return p


def prop_crate():
    p = []
    p += box(0, 0, 18, 46, 46, 36, WOOD, (176, 132, 90))
    p += box(0, 0, 37, 48, 8, 4, (110, 78, 50))         # papan atas
    p += box(0, 0, 18, 6, 48, 36, (110, 78, 50))        # ikatan
    return p


def prop_crates():
    p = []
    p += box(-14, 8, 15, 40, 40, 30, WOOD, (176, 132, 90))
    p += box(26, -6, 15, 34, 34, 30, (134, 96, 62), (160, 118, 80))
    p += box(4, 2, 45, 30, 30, 26, (162, 118, 78), (186, 140, 96))
    return p


def prop_pipe():
    p = []
    p += box(0, 0, 10, 26, 26, 20, STEEL_D, STEEL)      # penopang
    p += pipe_x(0, 0, 40, 170, 13, STEEL_L)
    p += box(-52, 0, 40, 10, 34, 34, RUST)              # flens
    p += box(52, 0, 40, 10, 34, 34, RUST)
    return p


def prop_pillar():
    p = []
    p += box(0, 0, 6, 54, 54, 12, STONE_D, STONE)       # alas
    p += box(0, 0, 24, 34, 34, 24, STONE, STONE_L)      # kaki
    p += box(0, 0, 96, 26, 26, 122, STONE, STONE_L)     # batang
    p += box(0, 0, 160, 40, 40, 14, STONE_D, STONE)     # kepala
    p += box(0, 0, 170, 30, 30, 8, STONE, STONE_L)
    return p


def prop_pillar_broken():
    p = []
    p += box(0, 0, 6, 54, 54, 12, STONE_D, STONE)       # alas
    p += box(0, 0, 30, 32, 32, 40, STONE, STONE_L)      # pangkal batang
    p += box(4, -3, 54, 26, 26, 12, STONE, STONE_L)     # patahan 1
    p += box(-6, 4, 62, 16, 16, 10, STONE_D, STONE)     # patahan 2
    p += box(9, 6, 66, 9, 9, 8, STONE_D, STONE)         # serpihan
    p += box(-26, 16, 8, 18, 16, 14, STONE, STONE_L)    # puing kiri
    p += box(24, -12, 7, 14, 18, 12, STONE_D, STONE)    # puing kanan
    p += box(2, 0, 16, 34, 34, 6, MOSS, MOSS)           # lumut
    return p


def prop_relief():
    p = []
    p += box(0, 0, 8, 122, 32, 16, STONE_D, STONE)      # dasar
    p += box(0, 0, 64, 116, 26, 96, STONE, STONE_L)     # dinding
    # bingkai ukiran yang menonjol
    p += box(0, -14, 116, 96, 4, 6, STONE_L, STONE_L)
    p += box(0, -14, 24, 96, 4, 6, STONE_L, STONE_L)
    p += box(-46, -14, 70, 6, 4, 92, STONE_L, STONE_L)
    p += box(46, -14, 70, 6, 4, 92, STONE_L, STONE_L)
    # panel dalam + tiga blok relief
    p += box(0, -12, 70, 84, 3, 84, STONE_D, STONE_D)
    p += box(0, -14, 88, 30, 4, 26, STONE, STONE_L)
    p += box(-24, -14, 62, 20, 4, 18, STONE, STONE_L)
    p += box(24, -14, 58, 18, 4, 16, STONE, STONE_L)
    p += box(0, 12, 30, 40, 6, 10, MOSS, MOSS)          # lumut di kaki
    return p


def prop_rubble():
    p = []
    p += box(0, 0, 10, 40, 34, 20, STONE_D, STONE)
    p += box(-20, 8, 7, 22, 20, 14, STONE, STONE_L)
    p += box(18, -6, 8, 18, 24, 16, STONE_D, STONE)
    return p


def prop_server():
    p = []
    p += box(0, 0, 6, 64, 50, 12, STEEL_D, STEEL)               # alas
    p += box(0, 0, 76, 56, 42, 128, (78, 92, 110), (98, 114, 132))  # badan rak
    # rak: garis pemisah + lampu status
    for i in range(4):
        z = 30 + i * 28
        p += box(0, -22, z, 46, 4, 4, (52, 64, 78), (60, 74, 90))
        p += box(-14, -24, z + 8, 8, 4, 6, CYAN, CYAN)
        p += box(2, -24, z + 8, 8, 4, 6, ORANGE, ORANGE)
        p += box(16, -24, z + 8, 6, 4, 6, CYAN, CYAN)
    p += box(0, 0, 144, 50, 36, 8, STEEL, STEEL_L)              # atap
    p += box(0, 0, 156, 16, 16, 14, DARK, STEEL_D)              # ventilasi
    return p


def prop_terminal():
    p = []
    p += box(0, 0, 12, 56, 40, 24, DARK, (60, 72, 86))
    p += box(0, -6, 44, 44, 6, 34, (30, 40, 52), (44, 56, 70))   # layar
    p += box(0, -9, 44, 30, 2, 20, CYAN, CYAN)                    # isi layar
    p += box(0, 6, 30, 30, 10, 4, STEEL_D, STEEL)
    return p


def prop_pylon():
    p = []
    p += box(0, 0, 6, 34, 34, 12, DARK, (60, 72, 86))
    p += box(0, 0, 60, 16, 16, 100, STEEL_D, STEEL)
    p += box(0, 0, 120, 46, 12, 8, STEEL, STEEL_L)
    p += box(0, 0, 140, 10, 10, 32, STEEL, STEEL_L)
    p += box(0, 0, 158, 10, 10, 8, CYAN, CYAN)
    return p


def prop_core():
    """Monolit inti: batu tua dengan inti bercahaya (landmark The Source)."""
    p = []
    p += box(0, 0, 10, 150, 150, 20, STONE_D, STONE)      # landasan
    p += box(0, 0, 26, 120, 120, 14, STONE, STONE_L)      # tangga
    p += box(-46, -46, 96, 26, 26, 150, STONE_D, STONE)   # tiang sudut
    p += box(46, -46, 96, 26, 26, 150, STONE_D, STONE)
    p += box(-46, 46, 96, 26, 26, 150, STONE_D, STONE)
    p += box(46, 46, 96, 26, 26, 150, STONE_D, STONE)
    p += box(0, 0, 110, 62, 62, 170, (46, 58, 74), (62, 78, 96))   # badan inti
    p += box(0, -32, 120, 34, 6, 96, CYAN, CYAN)                    # celah cahaya
    p += box(0, 0, 200, 54, 54, 16, STEEL_D, STEEL)                 # mahkota
    p += box(0, 0, 216, 20, 20, 22, CYAN, CYAN)                     # kristal
    return p


def prop_hall():
    """Aula pabrik: bangunan besar dengan atap gigi gergaji dan cerobong."""
    p = []
    p += box(0, 0, 10, 210, 140, 20, STEEL_D, STEEL)          # lantai
    p += box(0, 0, 70, 200, 130, 100, (104, 118, 134), (128, 142, 158))  # dinding
    # atap gigi gergaji
    for i in range(4):
        x = -75 + i * 50
        p += box(x, 0, 128, 46, 130, 16, (78, 90, 106), (96, 108, 124))
        p += box(x, -60, 138, 46, 10, 12, (56, 66, 80))
    p += box(0, -66, 40, 44, 6, 60, DARK, DARK)               # pintu
    p += box(0, -66, 96, 30, 4, 18, ORANGE, ORANGE)           # lampu pintu
    p += cyl(72, 40, 120, 230, 18, RUST, STONE)               # cerobong
    p += cyl(72, 40, 230, 238, 20, DARK, DARK)
    p += box(-80, 50, 124, 30, 30, 12, STEEL, STEEL_L)        # ventilasi
    return p


def main():
    os.makedirs(OUT, exist_ok=True)
    print("membuat aset properti:")
    save("tank", prop_tank())
    save("chimney", prop_chimney())
    save("machine", prop_machine())
    save("conveyor", prop_conveyor())
    save("crate", prop_crate())
    save("crates", prop_crates())
    save("pipe", prop_pipe())
    save("pillar", prop_pillar())
    save("pillar_broken", prop_pillar_broken())
    save("relief", prop_relief())
    save("rubble", prop_rubble())
    save("server", prop_server())
    save("terminal", prop_terminal())
    save("pylon", prop_pylon())
    save("core", prop_core())
    save("hall", prop_hall())
    print("selesai.")


if __name__ == "__main__":
    main()
