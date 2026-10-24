"""Susun ulang assets/maps/<map>.props.json sesuai latar tiap map pada
Tabel 2.6 dokumen (Kota Unggul, Hutan Pengetahuan, Pabrik Limbah, Candi Kuno,
Danau Citra, The Source).

Pohon, semak, bangunan, dan peralatan digambar scripts/world.gd sebagai sprite
terpisah di atas PNG peta (supaya pemain bisa lewat di belakangnya), jadi daftar
inilah yang menentukan isi visual map. PNG peta hanya berisi tanah.

Jalankan:  python3 tools/map_props.py
"""
import json
import random
import sys

sys.path.insert(0, "tools")
import maps_gen as m  # noqa: E402

T = 48  # px per tile (sama dengan meta "tile" pada *.json)

# tinggi sprite di layar (px)
H = {
    "tree_big": 150, "bush": 54, "rubble": 44, "lamp": 86,
    "bldg_house": 190, "bldg_shop": 172, "bldg_office": 200, "hall": 205,
    "machine": 92, "conveyor": 66, "pipe": 78, "tank": 112, "crates": 74,
    "crate": 48, "chimney": 150, "pillar": 118, "pillar_broken": 66,
    "house": 250, "flag": 150, "sign_toko": 150, "banner_red": 150, "banner_blue": 150, "campfire": 90, "fence_h": 90, "fence_v": 90, "relief": 88, "stone_tower": 236, "well": 120, "tent": 130, "windmill": 240, "castle_sq": 200, "castle_rnd": 200, "core": 140, "server": 92, "terminal": 78, "pylon": 128,
}


def open_cell(g, x, y):
    return 0 <= x < m.W and 0 <= y < m.H and g[y][x] not in "#TBWXLRPC"


def near_special(g, x, y, r=1):
    """Jangan menaruh properti di dekat NPC/portal supaya tetap bisa diakses."""
    for yy in range(max(0, y - r), min(m.H, y + r + 1)):
        for xx in range(max(0, x - r), min(m.W, x + r + 1)):
            if g[yy][xx] in "NO":
                return True
    return False


def rects(g, ch):
    """Cari persegi panjang terbesar dari karakter ch (dipakai untuk gedung)."""
    out = []
    seen = [[False] * m.W for _ in range(m.H)]
    for y in range(m.H):
        for x in range(m.W):
            if g[y][x] != ch or seen[y][x]:
                continue
            w = 0
            while x + w < m.W and g[y][x + w] == ch and not seen[y][x + w]:
                w += 1
            h = 1
            while y + h < m.H and all(g[y + h][x + i] == ch and not seen[y + h][x + i] for i in range(w)):
                h += 1
            for j in range(h):
                for i in range(w):
                    seen[y + j][x + i] = True
            out.append((x, y, w, h))
    return out


def put(items, name, x, y, h=None, rnd=None, flip=None):
    jx = (rnd.random() - .5) * 10 if rnd else 0
    it = {"t": name.split("_")[0], "n": name,
          "x": round(x * T + T * .5 + jx, 1),
          "y": round((y + 1) * T, 1),
          "h": float(h if h is not None else H.get(name, 100))}
    if flip or (flip is None and rnd and rnd.random() < 0.35):
        it["f"] = True
    items.append(it)


def build(name, g):
    rnd = random.Random(abs(hash(name)) % 9999)
    items = []

    # ---- pohon & semak: hanya di tepi agar tidak menutup seluruh map
    for y in range(m.H):
        for x in range(m.W):
            ch = g[y][x]
            if near_special(g, x, y):
                continue
            if ch == "T":
                edge = any(open_cell(g, x + dx, y + dy)
                           for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)))
                if not edge:
                    continue
                if name in ("hutan",) or rnd.random() < 0.85:
                    hh = (140 + rnd.random() * 55) if name == "hutan" else (128 + rnd.random() * 48)
                    put(items, "tree_big", x, y, hh, rnd)
            elif ch == "f":
                if rnd.random() < 0.7:
                    put(items, "bush", x, y, 46 + rnd.random() * 16, rnd)
            elif ch == "R":
                put(items, "rubble", x, y, 36 + rnd.random() * 14, rnd)

    # ---- gedung & perlengkapan sesuai latar tiap map
    if name == "kota":
        # tiap kavling dapat bangunan berbeda supaya tidak terasa copy-paste
        kavling = {(5, 4): ("house", 252), (18, 4): ("house", 244),
                   (34, 4): ("castle_sq", 286), (46, 5): ("windmill", 272),
                   (5, 26): ("castle_rnd", 250), (34, 26): ("house", 248)}
        for (x, y, w, h) in rects(g, "B"):
            k, hh = kavling.get((x, y), ("house", 240))
            put(items, k, x + w // 2 - 0.5, y + h - 1, hh, rnd)
        # lampu di tepi plaza
        for (x, y) in [(21, 11), (38, 11), (21, 26), (38, 26), (24, 18), (35, 20)]:
            if open_cell(g, x, y):
                put(items, "lamp", x, y, 86, rnd)
        # plang toko di sebelah pedagang
        for (x, y, k) in [(13, 17, "sign_toko"), (16, 19, "crate"), (12, 20, "crates")]:
            # Plang toko selalu ditaruh depan kios; jangan ditolak karena tile dekoratif.
            if k == "sign_toko" or open_cell(g, x, y):
                put(items, k, x, y, H.get(k, 120), rnd, flip=False)
        # pasar: tenda + peti + gerobak di kiri (dekat pedagang) dan kanan
        for (x, y, k) in [(15, 12, "tent"), (18, 12, "crates"), (20, 12, "crate"),
                          (12, 13, "crate"), (22, 13, "crates"),
                          (46, 12, "tent"), (49, 12, "crates"), (52, 12, "crate"),
                          (44, 27, "crate"), (45, 27, "crates"),
                          (23, 22, "well"), (36, 12, "campfire")]:
            if open_cell(g, x, y):
                put(items, k, x, y, H.get(k, 120), rnd)
        # bendera & umbul-umbul di depan balai kota dan pasar
        for (x, y, k) in [(34, 11, "flag"), (42, 11, "banner_red"),
                          (15, 11, "banner_blue"), (53, 11, "flag"),
                          (5, 25, "banner_red"), (42, 25, "banner_blue")]:
            if open_cell(g, x, y):
                put(items, k, x, y, H.get(k, 150), rnd)

    elif name == "hutan":
        for (x, y, w, h) in rects(g, "R"):
            put(items, "rubble", x, y, 50, rnd)
        # batang pohon tumbang: pakai pillar_broken sebagai kayu rebah
        for (x, y) in [(20, 6), (30, 16), (12, 17)]:
            if open_cell(g, x, y):
                put(items, "pillar_broken", x, y, 60, rnd)

    elif name == "pabrik":
        pool = ["machine", "conveyor", "pipe", "tank", "crates", "crate", "chimney"]
        for y in range(m.H):
            for x in range(m.W):
                if g[y][x] != "M" or near_special(g, x, y):
                    continue
                if rnd.random() < 0.11:
                    k = rnd.choice(pool)
                    put(items, k, x, y, H[k], rnd)
        for (x, y, w, h) in rects(g, "P"):
            put(items, "pylon", x, y, 128, rnd)

    elif name == "candi":
        for y in range(m.H):
            for x in range(m.W):
                if g[y][x] == "P" and not near_special(g, x, y):
                    put(items, "stone_tower", x, y, 236, rnd)
                elif g[y][x] == "r" and not near_special(g, x, y):
                    put(items, "pillar_broken", x, y, 62, rnd)
                elif g[y][x] == "#" and rnd.random() < 0.06 and not near_special(g, x, y):
                    put(items, "relief", x, y, 88, rnd)
        for (x, y, w, h) in rects(g, "P"):
            put(items, "stone_tower", x, y, 240, rnd)
        # kolonade di depan tembok atas: sel dengan '#' di atas dan terbuka di bawah
        for x in range(2, m.W - 2, 3):
            for y in range(2, min(m.H - 2, 13)):
                if g[y][x] in "SD," and g[y - 1][x] == "#" and not near_special(g, x, y):
                    put(items, "stone_tower", x, y, 232, rnd)
                    break

    elif name == "danau":
        for y in range(m.H):
            for x in range(m.W):
                if g[y][x] == "R" and not near_special(g, x, y):
                    put(items, "rubble", x, y, 44, rnd)
                elif g[y][x] == "W" and rnd.random() < 0.012 and not near_special(g, x, y):
                    put(items, "rubble", x, y, 30, rnd)
        for y in range(m.H):
            for x in range(m.W):
                if g[y][x] == "D" and rnd.random() < 0.55 and not near_special(g, x, y):
                    put(items, "bush", x, y, 46, rnd)
        for (x, y) in [(14, 9), (25, 14)]:
            if open_cell(g, x, y):
                put(items, "lamp", x, y, 86, rnd)

    elif name == "source":
        for y in range(m.H):
            for x in range(m.W):
                if near_special(g, x, y):
                    continue
                if g[y][x] == "C":
                    put(items, "core" if rnd.random() < 0.5 else "pylon", x, y, 130, rnd)
                elif g[y][x] == "S" and rnd.random() < 0.10:
                    put(items, rnd.choice(["pylon", "terminal"]), x, y, 110, rnd)
                elif g[y][x] == "P":
                    put(items, "pylon", x, y, 128, rnd)
                elif g[y][x] == "#" and rnd.random() < 0.30:
                    put(items, "server" if rnd.random() < 0.5 else "terminal", x, y, 88, rnd)

    # area gerbang jangan ditutup properti (pohon/semak/batu)
    gates = [(x, y) for y in range(m.H) for x in range(m.W) if g[y][x] == "O"]
    if gates:
        gx0 = min(x for x, y in gates) - 2
        gx1 = max(x for x, y in gates) + 2
        gy0 = min(y for x, y in gates) - 2
        gy1 = max(y for x, y in gates) + 1
        items = [it for it in items
                 if not (gx0 * T <= it["x"] <= (gx1 + 1) * T
                         and gy0 * T <= it["y"] <= (gy1 + 1) * T)
                 or it["n"] in ("lamp",)]

    items.sort(key=lambda it: it["y"])
    return items


def main():
    for name, fn in m.MAPS:
        m.W, m.H = m.MAP_SIZE.get(name, (40, 22))
        g = fn()
        items = build(name, g)
        with open("assets/maps/%s.props.json" % name, "w") as f:
            json.dump(items, f)
        kinds = {}
        for it in items:
            kinds[it["n"]] = kinds.get(it["n"], 0) + 1
        print(name, len(items), kinds)


if __name__ == "__main__":
    main()
