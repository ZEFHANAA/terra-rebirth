"""
Terra Rebirth — generator peta v2 (40x22 tile, 16px).
Layout sama dengan v1 (agar collision & spawn tidak berubah), tetapi penggambaran
dirombak: palet terbatas yang harmonis, kanopi hutan menyatu, bangunan bervariasi,
plaza bertekstur, air beriak, bayangan berarah.

Jalankan: python3 tools/maps_gen.py
"""
from PIL import Image, ImageDraw, ImageFilter
import json, os, random, math

W, H, T = 40, 22, 16
OUT = os.environ.get("MAP_OUT", "assets/maps")
## FLAT=1 -> gaya datar 2D (tampak atas, tanpa perspektif/bayangan); FLAT=0 -> gaya 3/4 lama.
FLAT = os.environ.get("FLAT", "1") == "1"
## UPSCALE=n -> gambar digambar pada grid 16 px lalu diperbesar n kali (n=3 -> 48 px/tile).
UPSCALE = int(os.environ.get("UPSCALE", "3"))
## NOBAKE=1 -> PNG peta tanpa properti (pohon/gedung), karena digambar sebagai
## sprite dari <map>.props.json (dibuat tools/map_props.py).
NOBAKE = os.environ.get("NOBAKE", "1") == "1"
os.makedirs(OUT, exist_ok=True)

# ------------------------------------------------------------------ palet
# Setiap ramp: [gelap, dasar, terang] — dipakai konsisten di semua peta.
PAL = {
    "kota": dict(
        grass=[(52, 88, 58), (68, 108, 70), (88, 132, 82)],
        path=[(128, 112, 88), (166, 148, 118), (190, 172, 142)],
        stone=[(104, 102, 96), (138, 136, 130), (168, 166, 158)],
        wall=[(170, 158, 136), (216, 204, 182), (238, 230, 212)],
        roof=[(104, 52, 44), (158, 82, 66), (196, 118, 94)],
        water=[(40, 96, 132), (60, 122, 160), (94, 158, 190), (196, 224, 236)],
        leaf=[(28, 64, 46), (46, 92, 58), (72, 126, 74)],
        trunk=[(78, 54, 38), (108, 78, 52)],
        accent=[(196, 148, 56), (238, 198, 100)],
        metal=[(96, 100, 106), (132, 138, 144)],
    ),
    "hutan": dict(
        grass=[(28, 58, 40), (40, 78, 50), (56, 100, 62)],
        path=[(74, 58, 42), (96, 76, 54), (118, 96, 70)],
        stone=[(78, 74, 66), (104, 100, 90), (128, 124, 112)],
        wall=[(56, 52, 46), (78, 72, 64), (96, 90, 80)],
        roof=[(44, 38, 32), (66, 56, 46), (88, 76, 62)],
        water=[(30, 78, 90), (46, 100, 112), (70, 130, 140), (180, 216, 222)],
        leaf=[(20, 50, 36), (34, 74, 48), (52, 98, 60)],
        trunk=[(62, 44, 32), (88, 64, 44)],
        accent=[(128, 178, 96), (170, 214, 130)],
        metal=[(84, 88, 84), (112, 116, 110)],
    ),
    "pabrik": dict(
        grass=[(58, 62, 66), (72, 76, 82), (86, 90, 96)],
        path=[(86, 90, 96), (108, 112, 118), (128, 132, 138)],
        stone=[(92, 96, 102), (116, 120, 126), (140, 144, 150)],
        wall=[(78, 84, 92), (100, 106, 114), (122, 128, 136)],
        roof=[(64, 50, 42), (92, 70, 56), (116, 90, 72)],
        water=[(44, 54, 30), (70, 88, 36), (150, 196, 78), (206, 226, 120)],
        leaf=[(56, 62, 56), (74, 82, 74), (92, 100, 92)],
        trunk=[(78, 72, 64), (100, 94, 84)],
        accent=[(198, 128, 58), (232, 164, 82)],
        metal=[(96, 102, 110), (130, 136, 144)],
    ),
    "candi": dict(
        grass=[(128, 112, 84), (148, 132, 100), (168, 152, 118)],
        path=[(140, 128, 104), (168, 156, 128), (190, 178, 150)],
        stone=[(120, 112, 96), (150, 142, 122), (178, 170, 148)],
        wall=[(136, 126, 106), (162, 152, 130), (186, 176, 154)],
        roof=[(96, 82, 64), (124, 106, 84), (150, 130, 104)],
        water=[(40, 96, 104), (58, 118, 126), (82, 146, 152), (186, 220, 222)],
        leaf=[(64, 88, 52), (84, 112, 66), (106, 136, 82)],
        trunk=[(100, 82, 58), (126, 104, 74)],
        accent=[(186, 148, 74), (222, 186, 106)],
        metal=[(110, 104, 92), (140, 134, 120)],
    ),
    "danau": dict(
        grass=[(44, 82, 56), (58, 100, 66), (76, 122, 78)],
        path=[(150, 138, 108), (178, 166, 134), (200, 188, 156)],
        stone=[(104, 100, 92), (134, 130, 120), (162, 158, 146)],
        wall=[(108, 102, 92), (136, 130, 118), (160, 154, 140)],
        roof=[(86, 64, 46), (116, 88, 62), (144, 112, 80)],
        water=[(30, 84, 124), (46, 108, 150), (72, 142, 182), (186, 224, 238)],
        leaf=[(34, 78, 52), (50, 98, 62), (70, 124, 74)],
        trunk=[(96, 74, 52), (122, 96, 68)],
        accent=[(110, 190, 210), (160, 222, 232)],
        metal=[(104, 108, 112), (134, 138, 142)],
    ),
    "source": dict(
        grass=[(32, 28, 40), (44, 38, 54), (58, 50, 68)],
        path=[(58, 52, 68), (76, 68, 86), (94, 84, 104)],
        stone=[(66, 60, 78), (88, 80, 100), (110, 100, 122)],
        wall=[(52, 46, 62), (72, 64, 84), (92, 82, 104)],
        roof=[(40, 34, 48), (58, 50, 66), (76, 66, 84)],
        water=[(150, 62, 34), (206, 92, 48), (244, 164, 78), (255, 214, 150)],
        leaf=[(40, 34, 52), (56, 48, 68), (74, 64, 86)],
        trunk=[(64, 52, 56), (86, 70, 74)],
        accent=[(104, 210, 186), (150, 240, 214)],
        metal=[(76, 72, 86), (104, 98, 114)],
    ),
}

CLASS = {".": "grass", "f": "grass", "T": "canopy", "R": "grass", "C": "grass",
         ",": "path", "S": "stone", "=": "wood", "D": "sand",
         "M": "metal", "W": "water", "X": "toxic", "L": "lava",
         "#": "wall", "B": "wall", "P": "stone", "O": "stone", "N": "grass"}


def c(theme, key, i=1):
    return PAL[theme][key][max(0, min(len(PAL[theme][key]) - 1, i))]


def jit(col, rnd, amt=5):
    return tuple(max(0, min(255, col[i] + rnd.randint(-amt, amt))) for i in range(3))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# ------------------------------------------------------------------ layout
def blank(ch="."):
    return [[ch] * W for _ in range(H)]


def fill(g, x0, y0, x1, y1, ch):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            g[y][x] = ch


def border(g, ch="#"):
    fill(g, 0, 0, W - 1, 0, ch)
    fill(g, 0, H - 1, W - 1, H - 1, ch)
    fill(g, 0, 0, 0, H - 1, ch)
    fill(g, W - 1, 0, W - 1, H - 1, ch)


def scatter(g, ch, n, seed, only="."):
    rnd = random.Random(seed)
    placed = tries = 0
    while placed < n and tries < n * 40:
        tries += 1
        x, y = rnd.randrange(2, W - 2), rnd.randrange(2, H - 2)
        if g[y][x] == only:
            g[y][x] = ch
            placed += 1


def scatter_near(g, ch, n, seed, only=".", near=",", rad=3):
    rnd = random.Random(seed)
    placed = tries = 0
    while placed < n and tries < n * 60:
        tries += 1
        x, y = rnd.randrange(2, W - 2), rnd.randrange(2, H - 2)
        if g[y][x] != only:
            continue
        ok = False
        for dy in range(-rad, rad + 1):
            for dx in range(-rad, rad + 1):
                yy, xx = y + dy, x + dx
                if 0 <= yy < H and 0 <= xx < W and g[yy][xx] == near:
                    ok = True
        if ok:
            g[y][x] = ch
            placed += 1


def map_kota():
    """Hub 60x36: plaza tengah, enam gedung, deret toko di barat, gerbang di timur."""
    g = blank(".")
    for i in range(2):
        fill(g, i, i, W - 1 - i, i, "T")
        fill(g, i, H - 1 - i, W - 1 - i, H - 1 - i, "T")
        fill(g, i, i, i, H - 1 - i, "T")
        fill(g, W - 1 - i, i, W - 1 - i, H - 1 - i, "T")

    # jalan utama: horizontal (barat-timur) dan vertikal (utara-selatan)
    fill(g, 4, 18, 55, 20, ",")
    fill(g, 29, 5, 31, 32, ",")

    # plaza batu + kolam di tengah
    fill(g, 22, 10, 37, 27, "S")
    fill(g, 27, 15, 32, 21, "W")
    fill(g, 28, 16, 31, 20, "S")

    # enam gedung: balai kota, toko, kantor, gudang
    fill(g, 5, 4, 13, 9, "B")
    fill(g, 18, 4, 26, 9, "B")
    fill(g, 34, 4, 42, 9, "B")
    fill(g, 5, 26, 13, 31, "B")
    fill(g, 34, 26, 42, 31, "B")
    fill(g, 46, 5, 54, 10, "B")

    # jalan penghubung gedung selebar 2 tile + apron batu di depan gedung
    for (x0, y0, x1, y1) in [(7, 10, 9, 17), (21, 10, 23, 17), (37, 10, 39, 17),
                             (7, 21, 9, 25), (37, 21, 39, 25), (49, 11, 51, 17)]:
        fill(g, x0, y0, x1, y1, ",")
    for (x0, x1, y) in [(5, 13, 10), (18, 26, 10), (34, 42, 10), (46, 54, 11),
                        (5, 13, 25), (34, 42, 25)]:
        fill(g, x0, y, x1, y, "S")

    # gerbang keluar (portal) di ujung timur jalan utama
    fill(g, 56, 18, 57, 20, "O")
    fill(g, 55, 18, 55, 20, ",")

    # pohon pengisi di area terbuka + bunga di tepi jalan
    for (tx, ty) in [(16, 2), (17, 3), (44, 2), (45, 3), (3, 14), (3, 23),
                     (16, 32), (17, 33), (44, 32), (45, 33), (56, 5), (56, 30),
                     (15, 15), (16, 22), (43, 15), (44, 22), (24, 33), (35, 33)]:
        if 0 <= tx < W and 0 <= ty < H:
            g[ty][tx] = "T"
    scatter_near(g, "f", 26, 13, near=",")
    scatter(g, "f", 18, 12)

    g[14][30] = "N"
    return g


def map_hutan():
    g = blank(".")
    border(g, "T")
    fill(g, 0, 0, W - 1, 1, "T")
    for y in range(2, H - 1):
        x = 21 + int(5 * math.sin(y / 3.4))
        fill(g, x - 2, y, x + 1, y, ",")
    for y in range(0, H):
        x = 8 + int(2.2 * math.sin(y / 2.6))
        fill(g, x, y, x + 1, y, "W")
    scatter(g, "T", 130, 21, only=".")
    scatter(g, "R", 12, 22, only=".")
    fill(g, 14, 2, 26, 7, "S")
    fill(g, 17, 3, 23, 6, ".")
    fill(g, 20, 1, 22, 2, "O")
    g[4][18] = "N"
    return g


def map_pabrik():
    g = blank("M")
    border(g, "#")
    fill(g, 2, 2, W - 3, 2, "#")
    fill(g, 2, H - 3, W - 3, H - 3, "#")
    fill(g, 4, 13, 10, 18, "X")
    fill(g, 28, 4, 34, 8, "X")
    for (mx, my) in [(6, 5), (12, 5), (24, 13), (31, 16)]:
        fill(g, mx, my, mx + 2, my + 1, "P")
    fill(g, 2, 9, W - 3, 10, ",")
    fill(g, 19, 3, 20, H - 4, ",")
    fill(g, 6, 5, 6, 9, ",")
    fill(g, 12, 5, 12, 9, ",")
    fill(g, 24, 10, 24, 13, ",")
    fill(g, 31, 10, 31, 16, ",")
    fill(g, 6, 16, 31, 16, ",")
    scatter(g, "r", 8, 31, only="M")
    fill(g, 19, H - 3, 20, H - 2, "O")
    g[6][17] = "N"
    return g


def map_candi():
    g = blank("D")
    border(g, "#")
    fill(g, 5, 4, 34, 17, "S")
    for x in range(8, 33, 5):
        for y in (6, 15):
            g[y][x] = "P"
    fill(g, 17, 8, 22, 12, "W")
    fill(g, 18, 17, 21, H - 1, ",")
    fill(g, 18, 0, 21, 4, ",")
    scatter(g, "T", 20, 41, only="D")
    fill(g, 18, 1, 21, 2, "O")
    g[5][19] = "N"
    return g


def map_danau():
    g = blank(".")
    border(g, "T")
    fill(g, 0, 1, W - 1, 1, "T")
    fill(g, 0, H - 2, W - 1, H - 2, "T")
    fill(g, 1, 1, 24, H - 2, "W")
    for y in range(1, H - 1):
        g[y][25] = "D"
        g[y][26] = "D"
    fill(g, 20, 9, 28, 10, "=")
    fill(g, 7, 8, 10, 11, "D")
    scatter(g, "T", 12, 51, only=".")
    scatter(g, "R", 10, 52, only=".")
    fill(g, 36, 9, 38, 11, "O")
    g[9][27] = "N"
    return g


def map_source():
    g = blank(".")
    border(g, "#")
    fill(g, 13, 7, 26, 14, "S")
    for x in range(0, W):
        y = 17 + int(2 * math.sin(x / 5.0))
        fill(g, x, y, x, min(H - 2, y + 1), "L")
    fill(g, 19, 15, 20, H - 3, ",")
    fill(g, 19, 2, 20, 6, ",")
    fill(g, 8, 11, 12, 11, ",")
    fill(g, 27, 11, 31, 11, ",")
    scatter(g, "C", 16, 61, only=".")
    scatter(g, "R", 14, 62, only=".")
    for (px, py) in [(11, 6), (28, 6), (11, 15), (28, 15)]:
        g[py][px] = "P"
    fill(g, 19, 1, 21, 2, "O")
    g[11][20] = "N"
    return g


MAPS = [("kota", map_kota), ("hutan", map_hutan), ("pabrik", map_pabrik),
        ("candi", map_candi), ("danau", map_danau), ("source", map_source)]

## Ukuran per-map dalam tile (w, h). Kota Unggul sengaja lebih besar karena
## menjadi hub: toko, beberapa NPC, dan area tutorial (Tabel 2.6).
MAP_SIZE = {"kota": (60, 36)}

# ------------------------------------------------------------------ dasar
def cls(ch):
    return CLASS.get(ch, "grass")


def ground_color(ch, theme):
    k = cls(ch)
    if k == "grass":
        return c(theme, "grass", 1)
    if k == "canopy":
        return c(theme, "leaf", 0)
    if k == "path":
        return c(theme, "path", 1)
    if k == "sand":
        return c(theme, "path", 2)
    if k == "stone":
        return c(theme, "stone", 1)
    if k == "wood":
        return c(theme, "trunk", 1)
    if k == "metal":
        return c(theme, "metal", 0)
    if k == "water":
        return c(theme, "water", 1)
    if k == "toxic":
        return c(theme, "water", 1)
    if k == "lava":
        return c(theme, "water", 1)
    if k == "wall":
        return c(theme, "wall", 0)
    return c(theme, "grass", 1)


def paint_ground(g, theme, seed):
    img = Image.new("RGBA", (W * T, H * T), c(theme, "grass", 1))
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)

    for y in range(H):
        for x in range(W):
            ch = g[y][x]
            k = cls(ch)
            px, py = x * T, y * T
            base = ground_color(ch, theme)
            d.rectangle([px, py, px + T - 1, py + T - 1], fill=jit(base, rnd, 3))

            if k == "grass":
                for _ in range(10):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=jit(c(theme, "grass", 0), rnd, 4))
                for _ in range(6):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=jit(c(theme, "grass", 2), rnd, 4))
                if rnd.random() < 0.30:
                    gx, gy = px + rnd.randrange(3, 12), py + rnd.randrange(5, 14)
                    for (ox, oy) in [(0, 0), (-1, -2), (1, -3), (2, -1)]:
                        d.point((gx + ox, gy + oy), fill=c(theme, "grass", 2))
                    d.point((gx, gy + 1), fill=c(theme, "grass", 0))
            elif k == "path":
                for _ in range(14):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=jit(c(theme, "path", 0), rnd, 5))
                for _ in range(6):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=jit(c(theme, "path", 2), rnd, 5))
                if rnd.random() < 0.12:   # kerikil
                    rx, ry = px + rnd.randrange(2, 13), py + rnd.randrange(2, 13)
                    d.rectangle([rx, ry, rx + 1, ry + 1], fill=c(theme, "stone", 0))
            elif k == "sand":
                for _ in range(16):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=jit(c(theme, "path", 2), rnd, 6))
            elif k == "stone":
                # lempeng batu besar: garis nat tiap 8px, slab selang-seling
                half = (x + y) % 2
                d.rectangle([px, py, px + T - 1, py + T - 1],
                            fill=jit(c(theme, "stone", 1 + half), rnd, 2))
                for _ in range(8):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=jit(c(theme, "stone", 0), rnd, 4))
                d.line([(px, py + 7), (px + T - 1, py + 7)], fill=c(theme, "stone", 0))
                d.line([(px + 7, py), (px + 7, py + 6)], fill=c(theme, "stone", 0))
                d.line([(px, py + 15), (px + 6, py + 15)], fill=c(theme, "stone", 0))
                d.line([(px + 15, py + 8), (px + 15, py + 15)], fill=c(theme, "stone", 0))
            elif k == "wood":
                d.rectangle([px, py, px + T - 1, py + T - 1], fill=c(theme, "trunk", 1))
                for i in range(3):
                    d.line([(px, py + 2 + i * 5), (px + T - 1, py + 2 + i * 5)],
                           fill=c(theme, "trunk", 0))
            elif k == "metal":
                d.rectangle([px, py, px + T - 1, py + T - 1], fill=c(theme, "metal", 0))
                d.rectangle([px, py, px + T - 1, py + T - 1], outline=c(theme, "metal", 0))
                for _ in range(5):
                    d.point((px + rnd.randrange(0, T), py + rnd.randrange(0, T)),
                            fill=c(theme, "metal", 1))
                d.point((px + 3, py + 3), fill=c(theme, "metal", 1))
                d.point((px + 12, py + 12), fill=c(theme, "metal", 1))
            elif k in ("water", "toxic", "lava"):
                base = c(theme, "water", 1)
                d.rectangle([px, py, px + T - 1, py + T - 1], fill=jit(base, rnd, 2))
                for i in range(4):
                    yy = py + 2 + i * 4 + rnd.randrange(0, 2)
                    wl = rnd.randrange(4, 12)
                    x0 = px + rnd.randrange(0, T - wl)
                    d.line([(x0, yy), (x0 + wl, yy)], fill=c(theme, "water", 2))
                    d.point((x0 + wl // 2, yy + 1), fill=c(theme, "water", 0))

    # ---- transisi tepi (tanah → path/stone/water) dengan piksel bergerigi
    for y in range(H):
        for x in range(W):
            ch = g[y][x]
            k = cls(ch)
            if k in ("canopy",):
                continue
            px, py = x * T, y * T
            nbrs = {
                "up": (x, y - 1), "down": (x, y + 1),
                "left": (x - 1, y), "right": (x + 1, y),
            }
            for side, (nx, ny) in nbrs.items():
                if not (0 <= nx < W and 0 <= ny < H):
                    continue
                nk = cls(g[ny][nx])
                if nk == k or nk == "canopy":
                    continue
                edge = mix(ground_color(ch, theme), (0, 0, 0), 0.30)
                for i in range(T):
                    if rnd.random() < 0.35:
                        continue
                    if side == "up":
                        d.point((px + i, py), fill=edge)
                        if rnd.random() < 0.5:
                            d.point((px + i, py + 1), fill=mix(edge, ground_color(ch, theme), 0.5))
                    elif side == "down":
                        d.point((px + i, py + T - 1), fill=edge)
                    elif side == "left":
                        d.point((px, py + i), fill=edge)
                    else:
                        d.point((px + T - 1, py + i), fill=edge)

    return img


def paint_water(img, g, theme, seed):
    """Air digambar sebagai satu bidang: riak sinusoidal + gradasi kedalaman."""
    from collections import deque
    px = img.load()
    rnd = random.Random(seed + 3)
    cells = [(x, y) for y in range(H) for x in range(W) if cls(g[y][x]) in ("water", "toxic", "lava")]
    if not cells:
        return
    wset = set(cells)
    dist = {}
    dq = deque()
    for (x, y) in cells:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < W and 0 <= ny < H) or (nx, ny) not in wset:
                dist[(x, y)] = 0
                dq.append((x, y))
                break
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (nx, ny) in wset and (nx, ny) not in dist:
                dist[(nx, ny)] = dist[(x, y)] + 1
                dq.append((nx, ny))

    deep, mid, hi, foam = (c(theme, "water", 0), c(theme, "water", 1),
                           c(theme, "water", 2), c(theme, "water", 3))
    for (x, y) in cells:
        dd = min(1.0, dist.get((x, y), 3) / 5.0)
        base = mix(mid, deep, dd * 0.55)
        for i in range(T):
            for j in range(T):
                gx, gy = x * T + i, y * T + j
                # noise multi-oktaf: tidak periodik seperti ubin
                n = (0.55 * math.sin(gx * 0.13 + gy * 0.17 + 1.3)
                     + 0.30 * math.sin(gx * 0.31 - gy * 0.09 + 0.7)
                     + 0.15 * math.sin(gx * 0.07 + gy * 0.41 + 2.1))
                col = mix(base, hi, max(0.0, n) * 0.30)
                if n > 0.86:
                    col = mix(col, foam, 0.35)
                px[gx, gy] = (col[0], col[1], col[2], 255)
        # buih tepi: garis menerus dengan sedikit variasi
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) in wset:
                continue
            for i in range(0, T):
                wob = 1 if (i % 5 in (0, 1)) else 0
                if dy == -1:
                    gx, gy = x * T + i, y * T + 1 + wob
                elif dy == 1:
                    gx, gy = x * T + i, y * T + T - 2 - wob
                elif dx == -1:
                    gx, gy = x * T + 1 + wob, y * T + i
                else:
                    gx, gy = x * T + T - 2 - wob, y * T + i
                cur = px[gx, gy]
                px[gx, gy] = mix((cur[0], cur[1], cur[2]), foam, 0.55) + (255,)


# ------------------------------------------------------------------ kanopi
def paint_canopy(img, g, theme, seed):
    """Menggambar hutan tepi sebagai satu massa dedaunan, bukan pohon per tile."""
    d = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(seed + 5)
    leaf0, leaf1, leaf2 = c(theme, "leaf", 0), c(theme, "leaf", 1), c(theme, "leaf", 2)

    cells = [(x, y) for y in range(H) for x in range(W) if g[y][x] == "T"]
    if not cells:
        return
    # 1. isi dasar gelap
    for (x, y) in cells:
        d.rectangle([x * T, y * T, x * T + T - 1, y * T + T - 1], fill=leaf0)
    # 2. gumpalan daun yang saling menimpa (3 lapis)
    for (x, y) in cells:
        cx, cy = x * T + 8, y * T + 8
        for _ in range(2):
            r = rnd.randint(7, 11)
            ox, oy = rnd.randint(-3, 3), rnd.randint(-3, 3)
            col = leaf0 if rnd.random() < 0.45 else leaf1
            d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r], fill=col)
    # 3. highlight atas
    for (x, y) in cells:
        cx, cy = x * T + 8, y * T + 6
        for _ in range(2):
            r = rnd.randint(3, 6)
            ox, oy = rnd.randint(-5, 5), rnd.randint(-4, 2)
            d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r], fill=leaf2)
    # 4. tepi bawah: dedaunan menggantung tak beraturan + sesekali batang
    for (x, y) in cells:
        below = g[y + 1][x] if y + 1 < H else "T"
        if cls(below) == "canopy":
            continue
        cx, by = x * T + 8, y * T + T
        for _ in range(3):
            r = rnd.randint(4, 8)
            ox = rnd.randint(-8, 8)
            oy = rnd.randint(0, 5)
            d.ellipse([cx + ox - r, by - r + oy - 3, cx + ox + r, by + oy - 3],
                      fill=leaf0 if rnd.random() < .5 else leaf1)
        SD.ellipse([cx - 9, by - 4, cx + 9, by + 2], fill=(0, 0, 0, 60))
        if rnd.random() < 0.22:
            tx = cx + rnd.randint(-6, 6)
            d.rectangle([tx - 1, by - 5, tx + 1, by - 1], fill=c(theme, "trunk", 0))
    # 5. tepi atas: rim tipis (tidak rata) agar massa terpisah dari tanah
    for (x, y) in cells:
        above = g[y - 1][x] if y > 0 else "T"
        if cls(above) == "canopy":
            continue
        for i in range(0, T, 1):
            if rnd.random() < 0.55:
                continue
            d.point((x * T + i, y * T), fill=leaf1)
            if rnd.random() < 0.3:
                d.point((x * T + i, y * T + 1), fill=leaf2)


# ------------------------------------------------------------------ bangunan
# Warna khas tiap bangunan agar tidak terlihat copy-paste.
BUILDING_SKIN = {
    0: dict(wall=[(148, 146, 148), (198, 196, 196), (222, 220, 220)],
            roof=[(52, 60, 88), (74, 84, 116), (98, 110, 142)]),      # balai kota: batu & atap biru
    1: dict(wall=[(146, 116, 84), (196, 162, 118), (220, 190, 150)],
            roof=[(48, 78, 58), (70, 104, 76), (94, 130, 96)]),       # toko: kayu & atap hijau
    2: dict(wall=[(170, 158, 136), (216, 204, 182), (238, 230, 212)],
            roof=[(104, 52, 44), (158, 82, 66), (196, 118, 94)]),     # rumah: krem & atap merah
    3: dict(wall=[(150, 118, 92), (188, 152, 118), (212, 178, 142)],
            roof=[(78, 48, 34), (118, 72, 48), (150, 96, 66)]),       # penginapan: ochre & cokelat
}


def facade(img, d, x0, y0, x1, y1, theme, rnd, kind):
    """Empat tipe bangunan berbeda, digambar dengan perspektif 3/4 sederhana."""
    th = dict(PAL[theme])
    th["wall"] = BUILDING_SKIN[kind]["wall"]
    th["roof"] = BUILDING_SKIN[kind]["roof"]
    px0, py0 = x0 * T, y0 * T
    px1, py1 = (x1 + 1) * T, (y1 + 1) * T
    w = px1 - px0
    wall_lo, wall_mid, wall_hi = th["wall"]
    roof_lo, roof_mid, roof_hi = th["roof"]

    # bayangan jatuh ke kanan bawah (konsisten untuk semua bangunan)
    SD.polygon([(px0 + 10, py1 - 2), (px1 + 8, py1 - 2), (px1 + 8, py1 + 5), (px0 + 16, py1 + 5)],
               fill=(0, 0, 0, 55))
    SD.rectangle([px1 - 6, py0 + 26, px1 + 8, py1 + 3], fill=(0, 0, 0, 40))
    # dinding
    d.rectangle([px0 + 2, py0 + 18, px1 - 4, py1 - 2], fill=wall_mid)
    # sisi kanan lebih gelap (bayangan)
    d.rectangle([px1 - 12, py0 + 18, px1 - 4, py1 - 2], fill=wall_lo)
    # garis lantai
    d.rectangle([px0 + 2, py1 - 8, px1 - 4, py1 - 2], fill=mix(wall_lo, (0, 0, 0), .15))

    roof_top = py0 - 4
    roof_bot = py0 + 22

    if kind == 0:      # balai kota: atap pelana lebar + tiang
        d.polygon([(px0 - 4, roof_bot), (px1 + 2, roof_bot), (px1 - 14, roof_top), (px0 + 10, roof_top)],
                  fill=roof_mid)
        d.polygon([(px0 - 4, roof_bot), (px1 + 2, roof_bot), (px1 + 2, roof_bot - 5), (px0 - 4, roof_bot - 5)],
                  fill=roof_lo)
        for i in range(1, 6):
            t = i / 6.0
            yy = int(roof_top + (roof_bot - roof_top) * t)
            xa = int(px0 + 10 - 14 * t)
            xb = int(px1 - 14 + 16 * t)
            d.line([(xa, yy), (xb, yy)], fill=mix(roof_mid, roof_lo, .45))
        d.rectangle([px0 + 4, roof_top - 6, px1 - 6, roof_top - 1], fill=roof_hi)
        # tiang
        for i in range(4):
            cx = px0 + 12 + i * max(10, (w - 30) // 3)
            d.rectangle([cx, py0 + 24, cx + 4, py1 - 8], fill=wall_hi)
            d.rectangle([cx, py0 + 24, cx + 1, py1 - 8], fill=wall_mid)
        # pintu besar
        cxm = (px0 + px1) // 2
        d.rectangle([cxm - 10, py1 - 26, cxm + 10, py1 - 8], fill=mix(roof_lo, (0, 0, 0), .2))
        d.rectangle([cxm - 8, py1 - 24, cxm + 8, py1 - 8], fill=mix(th["trunk"][0], (0, 0, 0), .25))
        d.point((cxm + 5, py1 - 16), fill=th["accent"][1])
        # jendela tingkat atas
        for i in range(2):
            wx = cxm - 26 + i * 34
            d.rectangle([wx, py0 + 26, wx + 12, py0 + 36], fill=mix(th["accent"][1], (255, 255, 255), .3))
            d.rectangle([wx, py0 + 26, wx + 12, py0 + 36], outline=roof_lo)
            d.line([(wx + 6, py0 + 26), (wx + 6, py0 + 36)], fill=roof_lo)

    elif kind == 1:    # toko: kanopi bergaris + jendela pajang
        d.polygon([(px0 - 2, roof_bot - 2), (px1, roof_bot - 2), (px1 - 10, roof_top), (px0 + 8, roof_top)],
                  fill=roof_mid)
        for i in range(1, 5):
            t = i / 5.0
            yy = int(roof_top + (roof_bot - roof_top) * t)
            d.line([(int(px0 + 8 - 10 * t), yy), (int(px1 - 10 + 10 * t), yy)], fill=roof_lo)
        d.rectangle([px0 + 2, roof_top - 5, px1 - 4, roof_top - 1], fill=roof_hi)
        # kanopi bergaris di atas jendela
        ay = py0 + 24
        d.rectangle([px0 + 2, ay, px1 - 4, ay + 8], fill=th["accent"][1])
        for i in range(0, w - 6, 8):
            d.rectangle([px0 + 2 + i, ay, px0 + 5 + i, ay + 8], fill=roof_mid)
        SD.rectangle([px0 + 2, ay + 7, px1 - 4, ay + 9], fill=(0, 0, 0, 50))
        # jendela pajang
        d.rectangle([px0 + 8, ay + 14, px1 - 12, py1 - 14], fill=mix(th["accent"][1], (255, 255, 255), .45))
        d.rectangle([px0 + 8, ay + 14, px1 - 12, py1 - 14], outline=mix(th["trunk"][0], (0, 0, 0), .3))
        d.line([(px0 + 8, ay + 26), (px1 - 12, ay + 26)], fill=mix(th["trunk"][0], (0, 0, 0), .3))
        # pintu
        cxm = px0 + 14
        d.rectangle([cxm - 6, py1 - 20, cxm + 6, py1 - 8], fill=mix(th["trunk"][0], (0, 0, 0), .2))
        # papan nama
        d.rectangle([px0 + 10, roof_top + 8, px1 - 14, roof_top + 16], fill=mix(th["trunk"][0], (255, 255, 255), .2))
        d.rectangle([px0 + 10, roof_top + 8, px1 - 14, roof_top + 16], outline=roof_lo)
        d.line([(px0 + 14, roof_top + 12), (px1 - 20, roof_top + 12)], fill=roof_lo)

    elif kind == 2:    # rumah: atap miring + cerobong + kotak bunga
        d.polygon([(px0 - 2, roof_bot), (px1, roof_bot), (px1 - 12, roof_top), (px0 + 6, roof_top)],
                  fill=roof_mid)
        d.polygon([(px0 - 2, roof_bot), (px1, roof_bot), (px1, roof_bot - 4), (px0 - 2, roof_bot - 4)],
                  fill=roof_lo)
        for i in range(1, 4):
            t = i / 4.0
            yy = int(roof_top + (roof_bot - roof_top) * t)
            d.line([(int(px0 + 6 - 8 * t), yy), (int(px1 - 12 + 12 * t), yy)], fill=mix(roof_mid, roof_lo, .5))
        cx = px0 + 14
        d.rectangle([cx, roof_top - 8, cx + 7, roof_top + 4], fill=wall_lo)
        d.rectangle([cx - 1, roof_top - 10, cx + 8, roof_top - 7], fill=roof_lo)
        cxm = (px0 + px1) // 2
        d.rectangle([cxm - 5, py1 - 18, cxm + 5, py1 - 6], fill=mix(th["trunk"][0], (0, 0, 0), .25))
        d.rectangle([cxm - 4, py1 - 17, cxm + 4, py1 - 7], fill=th["trunk"][0])
        d.point((cxm + 3, py1 - 12), fill=th["accent"][1])
        for wx in (px0 + 6, px1 - 20):
            d.rectangle([wx, py0 + 28, wx + 12, py0 + 38], fill=mix(th["accent"][1], (255, 255, 255), .35))
            d.rectangle([wx, py0 + 28, wx + 12, py0 + 38], outline=roof_lo)
            d.line([(wx + 6, py0 + 28), (wx + 6, py0 + 38)], fill=roof_lo)
            # kotak bunga
            d.rectangle([wx - 1, py0 + 39, wx + 13, py0 + 42], fill=th["trunk"][0])
            for i in range(4):
                d.point((wx + 1 + i * 3, py0 + 38), fill=th["accent"][0])
                d.point((wx + 1 + i * 3, py0 + 37), fill=mix(th["leaf"][2], (255, 255, 255), .2))

    else:              # penginapan: dua lantai + balkon + lentera
        d.polygon([(px0 - 3, roof_bot - 6), (px1 + 1, roof_bot - 6), (px1 - 12, roof_top), (px0 + 8, roof_top)],
                  fill=roof_mid)
        for i in range(1, 5):
            t = i / 5.0
            yy = int(roof_top + (roof_bot - 6 - roof_top) * t)
            d.line([(int(px0 + 8 - 11 * t), yy), (int(px1 - 12 + 13 * t), yy)], fill=roof_lo)
        d.rectangle([px0 + 2, roof_bot - 8, px1 - 4, roof_bot - 4], fill=roof_hi)
        # balkon
        by = py0 + 34
        d.rectangle([px0, by, px1 - 2, by + 3], fill=th["trunk"][1])
        for i in range(0, w - 2, 6):
            d.line([(px0 + i, by - 7), (px0 + i, by)], fill=mix(th["trunk"][1], (255, 255, 255), .2))
        d.line([(px0, by - 7), (px1 - 2, by - 7)], fill=th["trunk"][1])
        # jendela dua lantai
        for row, wy in enumerate((py0 + 24, py0 + 42)):
            for i in range(2):
                wx = px0 + 8 + i * 18
                d.rectangle([wx, wy, wx + 11, wy + 10], fill=mix(th["accent"][1], (255, 255, 255), .4))
                d.rectangle([wx, wy, wx + 11, wy + 10], outline=roof_lo)
                d.line([(wx + 5, wy), (wx + 5, wy + 10)], fill=roof_lo)
        # pintu + lentera
        cxm = (px0 + px1) // 2
        d.rectangle([cxm - 6, py1 - 18, cxm + 6, py1 - 6], fill=mix(th["trunk"][0], (0, 0, 0), .2))
        for lx in (cxm - 12, cxm + 10):
            d.rectangle([lx, py1 - 26, lx + 3, py1 - 22], fill=th["accent"][1])
            d.point((lx + 1, py1 - 21), fill=th["accent"][0])
    # garis atap bawah
    d.line([(px0 + 2, py0 + 19), (px1 - 4, py0 + 19)], fill=mix(wall_lo, (0, 0, 0), .35))


def facade_flat(img, d, x0, y0, x1, y1, theme, rnd, kind):
    """Bangunan gaya datar 2D: atap dilihat lurus dari atas, tanpa dinding/perspektif."""
    th = dict(PAL[theme])
    th["wall"] = BUILDING_SKIN[kind]["wall"]
    th["roof"] = BUILDING_SKIN[kind]["roof"]
    px0, py0 = x0 * T, y0 * T
    px1, py1 = (x1 + 1) * T, (y1 + 1) * T
    roof_lo, roof_mid, roof_hi = th["roof"]
    pad = 2
    box = [px0 + pad, py0 + pad, px1 - pad, py1 - pad]
    edge = mix(roof_lo, (0, 0, 0), .45)
    d.rectangle([box[0] - 1, box[1] - 1, box[2] + 1, box[3] + 1], fill=edge)
    d.rectangle(box, fill=roof_mid)
    for yy in range(box[1] + 5, box[3] - 1, 5):
        d.line([(box[0] + 1, yy), (box[2] - 1, yy)], fill=mix(roof_mid, roof_lo, .28))
    cy = (box[1] + box[3]) // 2
    d.line([(box[0] + 1, cy), (box[2] - 1, cy)], fill=roof_hi)
    d.rectangle(box, outline=mix(roof_lo, (0, 0, 0), .30))
    cxm = (box[0] + box[2]) // 2
    cym = (box[1] + box[3]) // 2
    if kind == 0:
        r = max(3, min(box[2] - box[0], box[3] - box[1]) // 5)
        d.ellipse([cxm - r, cym - r, cxm + r, cym + r], fill=roof_hi, outline=edge)
    elif kind == 1:
        d.rectangle([box[0] + 4, box[1] + 4, box[0] + 9, box[1] + 9], fill=roof_hi, outline=edge)
        d.rectangle([box[2] - 9, box[3] - 9, box[2] - 4, box[3] - 4], fill=roof_hi, outline=edge)
    elif kind == 2:
        d.rectangle([box[0] + 5, box[1] + 4, box[0] + 10, box[1] + 9], fill=mix(roof_hi, (255, 255, 255), .25), outline=edge)
    else:
        for wy in (box[1] + 4, box[3] - 9):
            d.rectangle([cxm - 5, wy, cxm + 5, wy + 5], fill=roof_hi, outline=edge)


# Urutan tipe bangunan per peta (sesuai urutan penemuan: atas→bawah, kiri→kanan)
KIND_ORDER = {"kota": [0, 1, 2, 3]}


def paint_buildings(img, g, theme, seed):
    d = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(seed + 11)
    seen = set()
    idx = 0
    for y in range(H):
        for x in range(W):
            if g[y][x] == "B" and (x, y) not in seen:
                x1 = x
                while x1 + 1 < W and g[y][x1 + 1] == "B":
                    x1 += 1
                y1 = y
                while y1 + 1 < H and all(g[y1 + 1][xx] == "B" for xx in range(x, x1 + 1)):
                    y1 += 1
                for yy in range(y, y1 + 1):
                    for xx in range(x, x1 + 1):
                        seen.add((xx, yy))
                order = KIND_ORDER.get(theme, [])
                if idx < len(order):
                    kind = order[idx]
                else:
                    area = (x1 - x + 1) * (y1 - y + 1)
                    kind = 0 if area >= 40 else (2 if idx % 2 == 0 else 3)
                if FLAT:
                    facade_flat(img, d, x, y, x1, y1, theme, rnd, kind)
                else:
                    facade(img, d, x, y, x1, y1, theme, rnd, kind)
                idx += 1


# ------------------------------------------------------------------ properti
SHADOW = None
SD = None


def reset_shadow():
    global SHADOW, SD
    SHADOW = Image.new("RGBA", (W * T, H * T), (0, 0, 0, 0))
    SD = ImageDraw.Draw(SHADOW)


def shadow(cx, cy, w, h, a=70):
    if FLAT:
        return
    SD.ellipse([cx - w, cy - h, cx + w, cy + h], fill=(0, 0, 0, a))


def prop_tree(img, d, x, y, theme, rnd, big=1.0):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 15
    shadow(cx + 2, cy + 1, int(8 * big), 3)
    tw = max(2, int(3 * big))
    d.rectangle([cx - tw // 2, cy - int(9 * big), cx + tw // 2, cy], fill=th["trunk"][0])
    d.rectangle([cx - tw // 2, cy - int(9 * big), cx - tw // 2 + 1, cy], fill=th["trunk"][1])
    r = int(7 * big)
    for (ox, oy, col) in [(-2, -2, th["leaf"][0]), (2, -4, th["leaf"][1]), (0, -7, th["leaf"][2])]:
        d.ellipse([cx - r + ox, cy - 12 + oy - r, cx + r + ox, cy - 12 + oy + r], fill=col)
    d.ellipse([cx - 3, cy - 20, cx + 2, cy - 16], fill=mix(th["leaf"][2], (255, 255, 255), .18))


def prop_rock(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 13
    shadow(cx + 1, cy + 1, 7, 3)
    d.ellipse([cx - 7, cy - 8, cx + 7, cy + 2], fill=th["stone"][1])
    d.ellipse([cx - 5, cy - 8, cx + 3, cy - 2], fill=th["stone"][2])
    d.arc([cx - 7, cy - 8, cx + 7, cy + 2], 20, 150, fill=th["stone"][0])


def prop_crystal(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 14
    shadow(cx, cy, 6, 3)
    for (ox, h, w) in [(-4, 13, 3), (2, 18, 4), (5, 10, 2)]:
        d.polygon([(cx + ox, cy), (cx + ox - w, cy - h // 2), (cx + ox, cy - h), (cx + ox + w, cy - h // 2)],
                  fill=th["accent"][0], outline=mix(th["accent"][0], (0, 0, 0), .55))
        d.line([(cx + ox, cy - h), (cx + ox, cy - 2)], fill=th["accent"][1])


def prop_pillar(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 15
    shadow(cx + 2, cy, 8, 3)
    d.rectangle([cx - 5, cy - 20, cx + 5, cy], fill=th["wall"][1])
    d.rectangle([cx - 5, cy - 20, cx - 2, cy], fill=th["wall"][2])
    d.rectangle([cx - 7, cy - 24, cx + 7, cy - 19], fill=th["wall"][0])
    d.rectangle([cx - 7, cy - 3, cx + 7, cy], fill=th["wall"][0])


def prop_lamp(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 14
    shadow(cx, cy, 4, 2)
    d.rectangle([cx - 1, cy - 17, cx + 1, cy], fill=mix(th["metal"][0], (0, 0, 0), .3))
    SD.ellipse([cx - 5, cy - 24, cx + 5, cy - 14], fill=(255, 226, 150, 40))
    d.rectangle([cx - 4, cy - 22, cx + 4, cy - 15], fill=th["accent"][1])
    d.rectangle([cx - 3, cy - 21, cx + 3, cy - 16], fill=(255, 246, 214))
    d.rectangle([cx - 5, cy - 24, cx + 5, cy - 22], fill=th["metal"][0])


def prop_bench(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 13
    shadow(cx + 1, cy, 8, 3)
    d.rectangle([cx - 8, cy - 6, cx + 8, cy - 3], fill=th["trunk"][1])
    d.rectangle([cx - 8, cy - 11, cx + 8, cy - 9], fill=mix(th["trunk"][1], (255, 255, 255), .18))
    d.rectangle([cx - 6, cy - 3, cx - 5, cy], fill=th["trunk"][0])
    d.rectangle([cx + 5, cy - 3, cx + 6, cy], fill=th["trunk"][0])


def prop_stall(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 14
    shadow(cx + 2, cy, 11, 4)
    d.rectangle([cx - 11, cy - 9, cx + 11, cy], fill=th["trunk"][0])
    d.rectangle([cx - 11, cy - 9, cx + 11, cy - 7], fill=th["trunk"][1])
    for i in range(-12, 12, 6):
        col = th["roof"][1] if (i // 6) % 2 == 0 else (228, 220, 204)
        d.polygon([(cx + i, cy - 24), (cx + i + 6, cy - 24), (cx + i + 8, cy - 16), (cx + i + 2, cy - 16)], fill=col)
    d.rectangle([cx - 13, cy - 26, cx + 13, cy - 23], fill=th["roof"][0])
    for i in range(3):
        d.ellipse([cx - 8 + i * 6, cy - 14, cx - 4 + i * 6, cy - 10], fill=th["accent"][0])


def prop_sign(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 14
    shadow(cx, cy, 5, 2)
    d.rectangle([cx - 1, cy - 14, cx + 1, cy], fill=th["trunk"][0])
    d.rectangle([cx - 8, cy - 21, cx + 8, cy - 13], fill=th["trunk"][1])
    d.rectangle([cx - 8, cy - 21, cx + 8, cy - 13], outline=th["trunk"][0])
    d.line([(cx - 5, cy - 18), (cx + 4, cy - 18)], fill=th["trunk"][0])
    d.line([(cx - 5, cy - 15), (cx + 2, cy - 15)], fill=th["trunk"][0])


def prop_statue(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 15
    shadow(cx + 2, cy, 8, 3)
    d.rectangle([cx - 8, cy - 6, cx + 8, cy], fill=th["stone"][0])
    d.rectangle([cx - 8, cy - 6, cx + 8, cy - 4], fill=th["stone"][2])
    d.rectangle([cx - 3, cy - 17, cx + 3, cy - 6], fill=th["stone"][1])
    d.ellipse([cx - 4, cy - 23, cx + 4, cy - 15], fill=th["stone"][2])
    d.point((cx - 1, cy - 20), fill=th["stone"][0])
    d.point((cx + 2, cy - 20), fill=th["stone"][0])


def prop_fountain(img, d, x0, y0, x1, y1, theme, rnd):
    """Kolam kota: rim batu, air beriak, patung di tengah."""
    th = PAL[theme]
    px0, py0 = x0 * T, y0 * T
    px1, py1 = (x1 + 1) * T, (y1 + 1) * T
    d.rectangle([px0 - 2, py0 - 2, px1 + 2, py1 + 2], fill=th["stone"][0])
    d.rectangle([px0 - 2, py0 - 2, px1 + 2, py0 + 2], fill=th["stone"][2])
    d.rectangle([px0 + 3, py0 + 3, px1 - 3, py1 - 3], fill=th["water"][0])
    for _ in range(90):
        wx = rnd.randrange(px0 + 4, px1 - 4)
        wy = rnd.randrange(py0 + 4, py1 - 4)
        d.point((wx, wy), fill=th["water"][2] if rnd.random() < .6 else th["water"][1])
    # riak
    for r in (10, 18, 26):
        d.arc([(px0 + px1) // 2 - r, (py0 + py1) // 2 - r // 2,
               (px0 + px1) // 2 + r, (py0 + py1) // 2 + r // 2], 0, 360,
              fill=th["water"][3])


def prop_barrel(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 13
    shadow(cx, cy, 6, 3)
    d.rectangle([cx - 5, cy - 11, cx + 5, cy], fill=th["trunk"][1])
    d.rectangle([cx - 5, cy - 11, cx - 2, cy], fill=mix(th["trunk"][1], (255, 255, 255), .2))
    d.line([(cx - 5, cy - 7), (cx + 5, cy - 7)], fill=th["trunk"][0])
    d.line([(cx - 5, cy - 3), (cx + 5, cy - 3)], fill=th["trunk"][0])


def prop_reed(img, d, x, y, theme, rnd):
    cx, cy = x * T + 8, y * T + 15
    for i in range(5):
        ox = rnd.randint(-6, 6)
        h = rnd.randint(7, 13)
        d.line([(cx + ox, cy), (cx + ox + rnd.randint(-2, 2), cy - h)], fill=(92, 146, 92))
        d.point((cx + ox, cy - h), fill=(146, 196, 112))


def prop_altar(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 14
    shadow(cx + 2, cy, 11, 4)
    d.rectangle([cx - 11, cy - 9, cx + 11, cy], fill=th["wall"][0])
    d.rectangle([cx - 9, cy - 14, cx + 9, cy - 9], fill=th["wall"][1])
    d.polygon([(cx, cy - 34), (cx - 6, cy - 20), (cx, cy - 14), (cx + 6, cy - 20)], fill=th["accent"][0])
    d.polygon([(cx, cy - 34), (cx, cy - 14), (cx + 6, cy - 20)], fill=th["accent"][1])


def prop_machine(img, d, x, y, theme, rnd):
    th = PAL[theme]
    cx, cy = x * T + 8, y * T + 15
    shadow(cx + 2, cy, 10, 4)
    d.rectangle([cx - 9, cy - 18, cx + 9, cy], fill=th["metal"][0])
    d.rectangle([cx - 9, cy - 18, cx + 9, cy - 15], fill=th["metal"][1])
    d.rectangle([cx - 6, cy - 12, cx + 2, cy - 5], fill=(38, 44, 52))
    d.rectangle([cx - 5, cy - 11, cx + 1, cy - 9], fill=(96, 214, 158))
    d.rectangle([cx + 4, cy - 11, cx + 6, cy - 4], fill=th["accent"][0])


def paint_props(img, g, theme, seed):
    d = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(seed + 7)

    if NOBAKE:
        # Properti (pohon, gedung, mesin) digambar scripts/world.gd sebagai
        # sprite dari <map>.props.json; PNG peta hanya berisi tanah + kolam.
        if theme == "kota":
            # patung air mancur di pulau batu tengah kolam (28..31 x 16..20)
            th = PAL[theme]
            fx, fy = 30 * T - T // 2, 18 * T + T // 2
            d.ellipse([fx - 14, fy - 5, fx + 14, fy + 3], fill=th["stone"][0])
            d.rectangle([fx - 10, fy - 14, fx + 10, fy - 4], fill=th["stone"][0])
            d.rectangle([fx - 10, fy - 14, fx + 10, fy - 11], fill=th["stone"][2])
            d.rectangle([fx - 4, fy - 26, fx + 4, fy - 14], fill=th["stone"][1])
            d.ellipse([fx - 6, fy - 33, fx + 6, fy - 23], fill=th["stone"][2])
            d.point((fx - 2, fy - 29), fill=th["stone"][0])
            d.point((fx + 3, fy - 29), fill=th["stone"][0])
            # pancuran: air memancar lalu jatuh ke kolam
            for r, a in ((3, 255), (2, 200)):
                d.ellipse([fx - r, fy - 44 - r, fx + r, fy - 44 + r],
                          fill=th["water"][3] if len(th["water"]) > 3 else th["water"][2])
            d.arc([fx - 30, fy - 48, fx - 6, fy - 26], 195, 330, fill=th["water"][2], width=2)
            d.arc([fx + 6, fy - 48, fx + 30, fy - 26], 210, 345, fill=th["water"][2], width=2)
            d.line([(fx - 26, fy - 26), (fx - 26, fy - 16)], fill=th["water"][2])
            d.line([(fx + 26, fy - 26), (fx + 26, fy - 16)], fill=th["water"][2])
        if theme == "danau":
            # tiang penyangga dermaga supaya tidak terlihat menempel di air
            wood_d, wood_l = (74, 52, 34), (120, 88, 58)
            # Lima pasang tiang di bawah sisi dermaga, sampai air.
            # Digambar setelah air agar penyangga tidak tertutup tekstur danau.
            for x in (20, 21, 22, 23, 24):
                cx = x * T + T // 2
                top = 11 * T - 8
                bottom = 11 * T + 46
                d.rectangle([cx - 5, top, cx + 5, bottom], fill=wood_d)
                d.rectangle([cx - 3, top + 2, cx - 1, bottom - 1], fill=wood_l)
                # kepala tiang menonjol sedikit melewati lantai papan.
                d.rectangle([cx - 6, top - 3, cx + 6, top + 2], fill=wood_l)
        return

    paint_buildings(img, g, theme, seed)

    # kolam kota digambar sebagai satu objek
    if theme == "kota":
        prop_fountain(img, d, 18, 8, 23, 13, theme, rnd)

    for y in range(H):
        for x in range(W):
            ch = g[y][x]
            if ch == "T":
                # pohon individual hanya di tepi dalam (dekat area jalan)
                near = False
                for (dx, dy) in [(0, 1), (1, 0), (-1, 0), (0, -1)]:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < W and 0 <= yy < H and cls(g[yy][xx]) not in ("canopy",):
                        near = True
                if near and rnd.random() < 0.55:
                    prop_tree(img, d, x, y, theme, rnd, 1.05 if theme == "hutan" else 0.95)
            elif ch == "R":
                prop_rock(img, d, x, y, theme, rnd)
            elif ch == "C":
                prop_crystal(img, d, x, y, theme, rnd)
            elif ch == "P":
                if theme == "pabrik":
                    prop_machine(img, d, x, y, theme, rnd)
                elif theme == "source":
                    prop_crystal(img, d, x, y, theme, rnd)
                else:
                    prop_pillar(img, d, x, y, theme, rnd)
            elif ch == "r":
                prop_barrel(img, d, x, y, theme, rnd)
            elif ch == "f":
                for i in range(5):
                    px = x * T + rnd.randint(2, 13)
                    py = y * T + rnd.randint(3, 13)
                    d.point((px, py), fill=PAL[theme]["accent"][0])
                    d.point((px, py + 1), fill=mix(PAL[theme]["accent"][0], PAL[theme]["leaf"][1], .4))

    if theme == "danau":
        for y in range(2, H - 2, 2):
            for x in range(2, 23, 3):
                if g[y][x] == "W" and rnd.random() < 0.4:
                    prop_reed(img, d, x, y, theme, rnd)
    if theme == "pabrik":
        for (tx, ty) in [(3, 4), (3, 6), (35, 12), (35, 14), (14, 16), (24, 5)]:
            prop_machine(img, d, tx, ty, theme, rnd)
    if theme == "kota":
        for (lx, ly) in [(14, 9), (14, 13), (27, 9), (27, 13), (19, 15), (23, 15), (16, 5), (26, 5)]:
            prop_lamp(img, d, lx, ly, theme, rnd)
        prop_bench(img, d, 16, 14, theme, rnd)
        prop_bench(img, d, 25, 14, theme, rnd)
        prop_bench(img, d, 16, 7, theme, rnd)
        prop_statue(img, d, 20, 10, theme, rnd)
        prop_stall(img, d, 14, 5, theme, rnd)
        prop_stall(img, d, 17, 5, theme, rnd)
        prop_sign(img, d, 33, 10, theme, rnd)
        prop_barrel(img, d, 26, 9, theme, rnd)
    if theme == "candi":
        prop_altar(img, d, 19, 6, theme, rnd)
        for (sx, sy) in [(7, 9), (31, 9), (7, 13), (31, 13)]:
            prop_statue(img, d, sx, sy, theme, rnd)
    if theme == "source":
        prop_altar(img, d, 19, 11, theme, rnd)


# ------------------------------------------------------------------ akhir
def finish(img, theme):
    # cahaya lembut + vignette ringan (tidak mengaburkan warna)
    light = Image.new("L", img.size, 0)
    ld = ImageDraw.Draw(light)
    ld.ellipse([img.width * 0.10, -img.height * 0.45, img.width * 0.90, img.height * 0.90], fill=70)
    light = light.filter(ImageFilter.GaussianBlur(90))
    warm = Image.new("RGBA", img.size, (255, 244, 214, 20))
    img = Image.composite(Image.alpha_composite(img, warm), img, light)

    v = Image.new("L", img.size, 0)
    vd = ImageDraw.Draw(v)
    vd.ellipse([-img.width * 0.10, -img.height * 0.14, img.width * 1.10, img.height * 1.14], fill=255)
    v = v.filter(ImageFilter.GaussianBlur(60))
    dark = Image.new("RGBA", img.size, (8, 10, 16, 90))
    img = Image.composite(img, Image.alpha_composite(img, dark), v)
    return img


def export(name, fn):
    global W, H
    W, H = MAP_SIZE.get(name, (40, 22))
    reset_shadow()
    g = fn()
    s = abs(hash(name)) % 9999
    img = paint_ground(g, name, s)
    paint_water(img, g, name, s)
    paint_canopy(img, g, name, s)
    paint_props(img, g, name, s)
    if FLAT:
        # Gaya datar: bayangan tetap dipakai tipis supaya objek tidak "melayang".
        sh = SHADOW.copy()
        sh.putalpha(sh.getchannel("A").point(lambda v: int(v * 0.40)))
        img = Image.alpha_composite(img, sh)
    else:
        img = Image.alpha_composite(img, SHADOW)
        img = finish(img, name)
    tile = T
    if UPSCALE > 1:
        img = img.resize((img.width * UPSCALE, img.height * UPSCALE), Image.LANCZOS)
        tile = T * UPSCALE
    img.save(f"{OUT}/{name}.png")

    solid = [[1 if ch in "#TBWXLRPC" else 0 for ch in row] for row in g]
    npc = portal = None
    for y in range(H):
        for x in range(W):
            if g[y][x] == "N":
                npc = {"x": x, "y": y}
            if g[y][x] == "O":
                portal = {"x": x, "y": y}
    meta = {"w": W, "h": H, "tile": tile, "solid": solid, "npc": npc, "portal": portal}
    with open(f"{OUT}/{name}.json", "w") as f:
        json.dump(meta, f)
    print("map", name, "ok")
    W, H = 40, 22


if __name__ == "__main__":
    for n, f in MAPS:
        export(n, f)
