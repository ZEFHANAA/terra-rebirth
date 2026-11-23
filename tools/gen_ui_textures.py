"""Membuat tekstur 9-patch bergaya pixel untuk UI Terra Rebirth.

Setiap wilayah punya tema sendiri: bingkai, pita kepala panel, dan kertas soal
memakai bahan serta warna yang berbeda supaya panel terasa bagian dari peta itu
(kayu hutan, besi pabrik, batu candi, kayu apung danau, obsidian The Source).

Semua gambar digambar pada skala 4x supaya tepinya tetap tegas saat direntangkan.
Jalankan: python3 tools/gen_ui_textures.py
"""
import random

from PIL import Image, ImageDraw

OUT = "assets/ui"
S = 4  # skala pixel


def new(size):
    img = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def chamfer(d, box, px, fill):
    x0, y0, x1, y1 = box
    if px <= 0:
        d.rectangle(box, fill=fill)
        return
    d.rectangle([x0 + px, y0, x1 - px, y1], fill=fill)
    d.rectangle([x0, y0 + px, x1, y1 - px], fill=fill)


def grain(d, box, color, count, rnd, horizontal=True, length=(2, 5)):
    """Goresan bahan: garis pendek 1 px mengikuti arah papan."""
    x0, y0, x1, y1 = box
    for _ in range(count):
        if horizontal:
            y = rnd.randrange(y0, y1)
            x = rnd.randrange(x0, max(x0 + 1, x1 - length[1] * S))
            ln = rnd.randrange(length[0], length[1]) * S
            d.rectangle([x, y, min(x + ln, x1), y + S - 1], fill=color)
        else:
            x = rnd.randrange(x0, x1)
            y = rnd.randrange(y0, max(y0 + 1, y1 - length[1] * S))
            ln = rnd.randrange(length[0], length[1]) * S
            d.rectangle([x, y, x + S - 1, min(y + ln, y1)], fill=color)


def nail(d, x, y, size=3, head=(201, 162, 74, 255), shine=(238, 206, 130, 255),
         ring=(38, 26, 14, 255)):
    """Paku/rivet kecil: lingkar gelap + kepala logam."""
    x, y = x * S, y * S
    d.rectangle([x, y, x + size * S - 1, y + size * S - 1], fill=ring)
    d.rectangle([x + S // 2, y + S // 2, x + size * S - 1 - S // 2, y + size * S - 1 - S // 2],
                fill=head)
    d.rectangle([x + S // 2, y + S // 2, x + S, y + S], fill=shine)


# ---------------------------------------------------------------- palet wilayah
# base/light/dark/edge = warna bahan bingkai, accent = warna khas wilayah.
THEMES = {
    "kota": {
        "outer": (10, 18, 13), "shadow": (58, 39, 22), "base": (92, 64, 38),
        "light": (128, 94, 55), "dark": (46, 31, 17), "inner": (16, 28, 20),
        "accent": (58, 92, 48), "accent2": (74, 112, 58), "style": "wood",
        "paper": (232, 216, 176), "paper_in": (238, 224, 188), "paper_edge": (206, 186, 142),
        "paper_line": (70, 48, 27), "paper_style": "paper",
    },
    "hutan": {
        "outer": (8, 20, 12), "shadow": (36, 58, 30), "base": (58, 88, 44),
        "light": (100, 136, 68), "dark": (30, 50, 24), "inner": (12, 28, 15),
        "accent": (126, 176, 82), "accent2": (92, 140, 60), "style": "wood",
        "paper": (206, 216, 172), "paper_in": (218, 226, 184), "paper_edge": (172, 184, 134),
        "paper_line": (44, 62, 32), "paper_style": "leaf",
    },
    "pabrik": {
        "outer": (14, 15, 17), "shadow": (58, 60, 62), "base": (78, 84, 88),
        "light": (124, 132, 138), "dark": (36, 40, 44), "inner": (18, 21, 24),
        "accent": (168, 92, 44), "accent2": (206, 126, 62), "style": "metal",
        "paper": (204, 210, 214), "paper_in": (214, 220, 224), "paper_edge": (172, 180, 186),
        "paper_line": (46, 52, 58), "paper_style": "metal",
    },
    "candi": {
        "outer": (26, 20, 12), "shadow": (96, 76, 48), "base": (150, 120, 78),
        "light": (192, 162, 108), "dark": (74, 56, 34), "inner": (34, 26, 16),
        "accent": (214, 182, 110), "accent2": (166, 134, 74), "style": "stone",
        "paper": (226, 210, 168), "paper_in": (232, 218, 180), "paper_edge": (196, 178, 138),
        "paper_line": (74, 58, 34), "paper_style": "sand",
    },
    "danau": {
        "outer": (10, 22, 26), "shadow": (30, 64, 72), "base": (46, 90, 98),
        "light": (86, 136, 144), "dark": (22, 46, 52), "inner": (12, 28, 32),
        "accent": (124, 196, 196), "accent2": (86, 158, 160), "style": "wood",
        "paper": (198, 220, 222), "paper_in": (210, 230, 232), "paper_edge": (168, 194, 196),
        "paper_line": (30, 60, 66), "paper_style": "wet",
    },
    "source": {
        "outer": (12, 10, 18), "shadow": (44, 34, 64), "base": (58, 46, 84),
        "light": (100, 84, 134), "dark": (28, 22, 42), "inner": (14, 12, 22),
        "accent": (152, 112, 212), "accent2": (196, 156, 240), "style": "crystal",
        "paper": (212, 204, 232), "paper_in": (222, 214, 238), "paper_edge": (180, 170, 204),
        "paper_line": (44, 32, 66), "paper_style": "crystal",
    },
}


def frame(path, pal):
    rnd = random.Random(11)
    size = 96
    img, d = new(size)
    box = [0, 0, size * S - 1, size * S - 1]
    chamfer(d, box, 2 * S, pal["outer"] + (255,))
    cur = [S, S, box[2] - S, box[3] - S]
    chamfer(d, cur, 2 * S, pal["shadow"] + (255,))
    cur = [cur[0] + 3 * S, cur[1] + 3 * S, cur[2] - 3 * S, cur[3] - 3 * S]
    chamfer(d, cur, 2 * S, pal["base"] + (255,))

    style = pal["style"]
    if style in ("wood", "stone"):
        grain(d, [cur[0], cur[1], cur[2], cur[1] + 3 * S], pal["dark"] + (255,), 90, rnd)
        grain(d, [cur[0], cur[3] - 3 * S, cur[2], cur[3]], pal["dark"] + (255,), 90, rnd)
        grain(d, [cur[0], cur[1], cur[0] + 3 * S, cur[3]], pal["dark"] + (255,), 60, rnd, False)
        grain(d, [cur[2] - 3 * S, cur[1], cur[2], cur[3]], pal["dark"] + (255,), 60, rnd, False)
    elif style == "metal":
        # goresan mendatar tipis + bercak karat
        for _ in range(46):
            y = rnd.randrange(cur[1], cur[3])
            x = rnd.randrange(cur[0], cur[2] - 6 * S)
            d.rectangle([x, y, x + rnd.randrange(3, 10) * S, y + S - 1], fill=pal["dark"] + (255,))
        for _ in range(26):
            x = rnd.randrange(cur[0], cur[2] - 6 * S)
            y = rnd.randrange(cur[1], cur[3] - 4 * S)
            w = rnd.randrange(3, 8) * S
            h = rnd.randrange(1, 4) * S
            d.rectangle([x, y, x + w, y + h], fill=pal["accent"] + (215,))
            d.rectangle([x, y + h - S, x + w, y + h], fill=pal["accent2"] + (235,))
    elif style == "crystal":
        for _ in range(26):
            x = rnd.randrange(cur[0], cur[2] - 8 * S)
            y = rnd.randrange(cur[1], cur[3] - 8 * S)
            ln = rnd.randrange(3, 8) * S
            d.line([x, y, x + ln, y - ln // 2], fill=pal["accent"] + (110,), width=S)
        for _ in range(18):
            x = rnd.randrange(cur[0], cur[2] - S)
            y = rnd.randrange(cur[1], cur[3] - S)
            d.rectangle([x, y, x + S - 1, y + S - 1], fill=pal["accent2"] + (220,))

    # garis terang di sisi atas-kiri, gelap di sisi bawah-kanan
    d.rectangle([cur[0], cur[1], cur[2], cur[1] + S - 1], fill=pal["light"] + (255,))
    d.rectangle([cur[0], cur[1], cur[0] + S - 1, cur[3]], fill=pal["light"] + (255,))
    d.rectangle([cur[0], cur[3] - S, cur[2], cur[3]], fill=pal["dark"] + (255,))
    d.rectangle([cur[2] - S, cur[1], cur[2], cur[3]], fill=pal["dark"] + (255,))

    cur = [cur[0] + 4 * S, cur[1] + 4 * S, cur[2] - 4 * S, cur[3] - 4 * S]
    chamfer(d, cur, 1 * S, pal["inner"] + (255,))

    # hiasan sudut dalam: lumut (kayu/batu), karat (besi), kristal (source)
    spots = [(cur[0] + 6 * S, cur[1] + 6 * S), (cur[2] - 12 * S, cur[1] + 8 * S),
             (cur[0] + 8 * S, cur[3] - 12 * S), (cur[2] - 14 * S, cur[3] - 10 * S)]
    for (mx, my) in spots:
        d.rectangle([mx, my, mx + 3 * S, my + 2 * S], fill=pal["accent"] + (255,))
        d.rectangle([mx + S, my + 2 * S, mx + 2 * S, my + 3 * S], fill=pal["accent2"] + (255,))

    if style in ("wood", "metal"):
        head = (201, 162, 74, 255) if style == "wood" else (176, 182, 188, 255)
        shine = (238, 206, 130, 255) if style == "wood" else (226, 232, 238, 255)
        for (nx, ny) in [(6, 6), (size - 10, 6), (6, size - 10), (size - 10, size - 10)]:
            nail(d, nx, ny, head=head, shine=shine)
    elif style == "stone":
        # takik pahat di tiap sudut
        for (nx, ny) in [(6, 6), (size - 11, 6), (6, size - 11), (size - 11, size - 11)]:
            d.rectangle([nx * S, ny * S, nx * S + 4 * S, ny * S + 4 * S], fill=pal["light"] + (255,))
            d.rectangle([nx * S + S, ny * S + S, nx * S + 3 * S, ny * S + 3 * S], fill=pal["shadow"] + (255,))
    img.save(f"{OUT}/{path}")


def paper(path, pal):
    rnd = random.Random(5)
    size = 64
    img, d = new(size)
    box = [0, 0, size * S - 1, size * S - 1]
    chamfer(d, box, 1 * S, pal["paper_line"] + (255,))
    cur = [S, S, box[2] - S, box[3] - S]
    chamfer(d, cur, 1 * S, pal["paper"] + (255,))
    inner = [cur[0] + S, cur[1] + S, cur[2] - S, cur[3] - S]
    chamfer(d, inner, 1 * S, pal["paper_in"] + (255,))

    # Butir bahan HANYA di cincin tepi. Bagian tengah dibiarkan rata karena
    # 9-patch meregangkan bagian tengah, sehingga butir di sana berubah menjadi
    # garis panjang atau pola berulang yang menutupi huruf.
    ring = 26

    def in_ring(x: int, y: int) -> bool:
        return x < ring or y < ring or x > size * S - ring or y > size * S - ring

    dots = 0
    while dots < 260:
        x = rnd.randrange(inner[0], inner[2] - S)
        y = rnd.randrange(inner[1], inner[3] - S)
        if not in_ring(x, y):
            continue
        dots += 1
        shade = rnd.choice([
            pal["paper"] + (255,), pal["paper_in"] + (255,), pal["paper_edge"] + (255,)
        ])
        d.rectangle([x, y, x + S - 1, y + S - 1], fill=shade)

    style = pal["paper_style"]
    if style == "leaf":
        # urat daun di tepi kertas
        for _ in range(9):
            x = rnd.randrange(inner[0] + 4, inner[2] - 10)
            y = rnd.randrange(inner[1] + 4, inner[3] - 10)
            if not in_ring(x, y):
                continue
            d.line([x, y, x + rnd.randrange(3, 7) * S, y - rnd.randrange(1, 4) * S],
                   fill=pal["paper_edge"] + (255,), width=S)
    elif style == "metal":
        # garis pelat + baut kecil di tepi
        d.rectangle([cur[0] + 2 * S, cur[1] + 2 * S, cur[2] - 2 * S, cur[1] + 2 * S],
                    fill=pal["paper_edge"] + (255,))
        for (nx, ny) in [(4, 4), (size - 7, 4), (4, size - 7), (size - 7, size - 7)]:
            d.rectangle([nx * S, ny * S, nx * S + 2 * S, ny * S + 2 * S],
                        fill=pal["paper_line"] + (170,))
    elif style == "sand":
        # bintik pasir
        for _ in range(90):
            x = rnd.randrange(inner[0], inner[2] - S)
            y = rnd.randrange(inner[1], inner[3] - S)
            if not in_ring(x, y):
                continue
            d.rectangle([x, y, x + S - 1, y + S - 1], fill=pal["paper_edge"] + (200,))
    elif style == "wet":
        # tetes air di tepi kertas
        for _ in range(14):
            x = rnd.randrange(inner[0] + 2, inner[2] - 6)
            y = rnd.randrange(inner[1] + 2, inner[3] - 6)
            if not in_ring(x, y):
                continue
            r = rnd.randrange(1, 3) * S
            d.ellipse([x, y, x + r, y + r], fill=pal["paper_edge"] + (140,))
    elif style == "crystal":
        # serpihan kristal
        for _ in range(16):
            x = rnd.randrange(inner[0] + 2, inner[2] - 8)
            y = rnd.randrange(inner[1] + 2, inner[3] - 8)
            if not in_ring(x, y):
                continue
            ln = rnd.randrange(2, 5) * S
            d.line([x, y, x + ln, y - ln], fill=pal["paper_edge"] + (180,), width=S)

    # tepi bawah-kanan lebih gelap (bayangan kertas)
    d.rectangle([cur[0], cur[3] - S, cur[2], cur[3]], fill=pal["paper_edge"] + (255,))
    d.rectangle([cur[2] - S, cur[1], cur[2], cur[3]], fill=pal["paper_edge"] + (255,))
    img.save(f"{OUT}/{path}")


def plank(path, base, light, dark, edge, accent_line=None):
    rnd = random.Random(len(path))
    size = 48
    img, d = new(size)
    box = [0, 0, size * S - 1, size * S - 1]
    chamfer(d, box, 1 * S, edge)
    cur = [S, S, box[2] - S, box[3] - S]
    chamfer(d, cur, 1 * S, base)
    grain(d, [cur[0], cur[1], cur[2], cur[3]], dark, 60, rnd)
    # tengah papan dibiarkan rata: 9-patch meregangkan bagian ini, serat akan jadi garis panjang
    d.rectangle([18, 18, size * S - 19, size * S - 19], fill=base)
    d.rectangle([cur[0], cur[1], cur[2], cur[1] + S - 1], fill=light)
    d.rectangle([cur[0], cur[3] - S, cur[2], cur[3]], fill=dark)
    if accent_line:
        d.rectangle([cur[0] + 2 * S, cur[1] + 2 * S, cur[2] - 2 * S, cur[1] + 2 * S], fill=accent_line)
    img.save(f"{OUT}/{path}")


def heart(path, fill, shine):
    rows = [
        "..XX..XX..",
        ".XXXXXXXX.",
        "XXXXXXXXXX",
        "XXXXXXXXXX",
        ".XXXXXXXX.",
        "..XXXXXX..",
        "...XXXX...",
        "....XX....",
    ]
    img = Image.new("RGBA", (12 * S, 10 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "X":
                d.rectangle([(x + 1) * S, (y + 1) * S, (x + 2) * S - 1, (y + 2) * S - 1], fill=fill)
    d.rectangle([3 * S, 2 * S, 4 * S - 1, 3 * S - 1], fill=shine)
    img.save(f"{OUT}/{path}")


# ------------------------------------------------------------------- bangun semua
for key, pal in THEMES.items():
    frame(f"frame_{key}.png", pal)
    paper(f"card_{key}.png", pal)
    # pita kepala panel: versi lebih gelap dari bingkai
    ribbon = tuple(max(0, int(c * 0.62)) for c in pal["base"])
    ribbon_light = tuple(max(0, int(c * 0.82)) for c in pal["light"])
    ribbon_dark = tuple(max(0, int(c * 0.48)) for c in pal["dark"])
    plank(f"ribbon_{key}.png", ribbon + (255,), ribbon_light + (255,), ribbon_dark + (255,),
          pal["outer"] + (255,))
    # tombol papan: warna bahan wilayah, dengan versi hover (lebih terang) dan tekan
    base, light, dark, outer = pal["base"], pal["light"], pal["dark"], pal["outer"]
    bright = lambda c, f: tuple(min(255, int(v * f)) for v in c)
    plank(f"btn_{key}.png", base + (255,), light + (255,), dark + (255,), outer + (255,))
    plank(f"btn_{key}_hover.png", bright(base, 1.18) + (255,), bright(light, 1.18) + (255,),
          bright(dark, 1.12) + (255,), pal["accent"] + (255,),
          accent_line=pal["accent2"] + (255,))
    plank(f"btn_{key}_press.png", bright(base, 0.78) + (255,), bright(light, 0.82) + (255,),
          bright(dark, 0.75) + (255,), bright(outer, 0.8) + (255,))

# nama lama tetap ada supaya layar lain (HUD, dialog, peta) tidak perlu diubah
frame("frame_wood.png", THEMES["kota"])
paper("card_parchment.png", THEMES["kota"])

plank("btn_wood.png", (95, 67, 37, 255), (125, 90, 51, 255), (60, 42, 24, 255), (26, 18, 8, 255))
plank("btn_wood_hover.png", (116, 84, 47, 255), (150, 111, 63, 255), (74, 52, 30, 255), (214, 165, 70, 255),
      accent_line=(228, 186, 104, 255))
plank("btn_wood_press.png", (72, 50, 28, 255), (88, 62, 35, 255), (44, 30, 17, 255), (20, 14, 7, 255))
plank("btn_leaf.png", (76, 122, 52, 255), (106, 156, 72, 255), (48, 82, 33, 255), (18, 30, 13, 255))
plank("btn_leaf_hover.png", (94, 146, 62, 255), (128, 180, 86, 255), (60, 98, 40, 255), (24, 40, 17, 255),
      accent_line=(198, 226, 140, 255))
plank("btn_leaf_press.png", (56, 92, 38, 255), (70, 108, 46, 255), (36, 62, 25, 255), (14, 24, 10, 255))
plank("ribbon_wood.png", (62, 44, 26, 255), (86, 61, 36, 255), (40, 28, 16, 255), (18, 12, 6, 255))

heart("heart_full.png", (208, 76, 60, 255), (245, 178, 158, 255))
heart("heart_empty.png", (70, 84, 68, 255), (92, 108, 88, 255))


def leaves_tile():
    """Ubin latar: dedaunan samar untuk layar menu."""
    rnd = random.Random(21)
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x = rnd.randrange(0, 44)
        y = rnd.randrange(0, 44)
        col = (28, 54, 36, 255) if rnd.random() < 0.6 else (22, 42, 30, 255)
        d.rectangle([x, y, x + rnd.randrange(2, 5), y + rnd.randrange(1, 3)], fill=col)
    img.save(f"{OUT}/bg_leaves.png")


leaves_tile()
print("selesai")
