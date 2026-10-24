#!/usr/bin/env python3
"""Menata properti baru (mesin, pilar, rak server) pada peta Pabrik, Candi, The Source.

Aturan penting:
  * Aset besar hanya diletakkan di atas tile `solid` (area yang memang tidak bisa
    dilewati). Jadi area terlarang yang tadinya kosong berubah jadi "ruang" tanpa
    mengubah jalur yang bisa ditempuh pemain — keterjangkauan NPC/objek/portal
    tetap sama.
  * Aset kecil (peti, puing, semak) boleh di tile bebas karena tidak punya
    tabrakan, hanya menambah kerapatan visual.
  * Tidak ada aset dalam radius 2 tile dari NPC, objek pencarian, atau portal.

Jalankan: python3 tools/place_props.py   (menulis assets/maps/*.props.json)
"""
import json
import math
import os
import random
from collections import deque

ROOT = os.path.join(os.path.dirname(__file__), "..")
MAPS = os.path.join(ROOT, "assets", "maps")
T = 48  # ukuran tile

# tinggi gambar (px dunia) per jenis aset
H = {
    "tank": 150, "chimney": 250, "machine": 130, "conveyor": 110,
    "crate": 84, "crates": 104, "pipe": 116, "pillar": 210,
    "pillar_broken": 118, "relief": 186, "rubble": 66, "server": 200,
    "terminal": 108, "pylon": 190, "bush": 120, "tree_big": 150,
    "core": 300, "hall": 330,
}

BIG = ["tank", "chimney", "machine", "conveyor", "pipe", "pillar",
       "pillar_broken", "relief", "server", "terminal", "pylon"]
SMALL = ["crate", "crates", "rubble"]

# resep per peta: (jenis, jumlah)
RECIPE = {
    "pabrik": [("hall", 2), ("chimney", 3), ("tank", 4), ("machine", 8),
               ("conveyor", 5), ("pipe", 6), ("crates", 9), ("crate", 9),
               ("rubble", 8)],
    "candi": [("pillar", 9), ("pillar_broken", 6), ("relief", 6),
              ("rubble", 12), ("bush", 12)],
    "source": [("core", 1), ("server", 9), ("terminal", 7), ("pylon", 4),
               ("pipe", 5), ("rubble", 8)],
}

# aset yang dicari tempat paling "dalam" (jauh dari jalur) supaya jadi landmark
LANDMARK = {"core", "hall"}


def load(mid):
    with open(os.path.join(MAPS, mid + ".json")) as f:
        return json.load(f)


def dist_to_free(rows):
    """Jarak (BFS) setiap tile solid ke tile bebas terdekat."""
    h, w = len(rows), len(rows[0])
    d = [[-1] * w for _ in range(h)]
    q = deque()
    for y in range(h):
        for x in range(w):
            if not rows[y][x]:
                d[y][x] = 0
                q.append((x, y))
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and d[ny][nx] < 0:
                d[ny][nx] = d[y][x] + 1
                q.append((nx, ny))
    return d


def points_of_interest(mid, meta):
    pts = []
    npc = meta.get("npc") or {}
    if npc:
        pts.append((int(npc.get("x", -1)), int(npc.get("y", -1))))
    portal = meta.get("portal") or {}
    if portal:
        pts.append((int(portal.get("x", -1)), int(portal.get("y", -1))))
    # objek pencarian ada di content.gd -> dibaca dari /tmp/points.json bila ada
    pj = "/tmp/points.json"
    if os.path.exists(pj):
        with open(pj) as f:
            for p in json.load(f).get(mid, []):
                if p["x"] >= 0:
                    pts.append((p["x"], p["y"]))
    return [p for p in pts if p[0] >= 0]


def components(rows):
    """Kelompokkan tile solid yang saling bersambung (4 arah)."""
    h, w = len(rows), len(rows[0])
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            if not rows[y][x] or seen[y][x]:
                continue
            q = deque([(x, y)])
            seen[y][x] = True
            comp = []
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and rows[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True
                        q.append((nx, ny))
            out.append(comp)
    out.sort(key=len, reverse=True)
    return out


def far_enough(x, y, pts, r=2):
    return all(abs(x - px) > r or abs(y - py) > r for px, py in pts)


def place(mid, rng):
    meta = load(mid)
    rows = [[int(v) for v in r] for r in meta["solid"]]
    h, w = len(rows), len(rows[0])
    dist = dist_to_free(rows)
    pts = points_of_interest(mid, meta)

    props = []
    path = os.path.join(MAPS, mid + ".props.json")
    if os.path.exists(path):
        with open(path) as f:
            props = json.load(f)
    taken = [(p["x"] / T, p["y"] / T) for p in props]

    def free_spot(tx, ty, gap=1.9):
        for px, py in taken:
            if abs(px - (tx + 0.5)) < gap and abs(py - (ty + 0.9)) < gap:
                return False
        return True

    def add(kind, tx, ty, jitter=7.0):
        x = tx * T + T * 0.5 + rng.uniform(-jitter, jitter)
        y = ty * T + T * 0.92 + rng.uniform(-jitter, jitter)
        props.append({"t": "prop", "n": kind, "x": round(x, 1), "y": round(y, 1),
                      "h": float(H.get(kind, 120))})
        taken.append((x / T, y / T))

    # kandidat: tile solid yang berbatasan dengan jalur (dist 1..3),
    # tidak terlalu mepet tepi peta supaya aset tidak terpotong bingkai
    edge = [(x, y) for y in range(2, h - 2) for x in range(2, w - 2)
            if 1 <= dist[y][x] <= 3]
    # kandidat landmark: titik tengah gugusan area terlarang terbesar
    inner = []
    for comp in components(rows)[:4]:
        cx = sum(p[0] for p in comp) / len(comp)
        cy = sum(p[1] for p in comp) / len(comp)
        best, best_key = None, None
        for tx, ty in comp:
            if not (2 <= tx < w - 2 and 2 <= ty < h - 2):
                continue
            key = (dist[ty][tx], -math.hypot(tx - cx, ty - cy))
            if best_key is None or key > best_key:
                best, best_key = (tx, ty), key
        if best is not None:
            inner.append(best)
    # kandidat kecil: tile bebas yang menempel dinding (dist 0 tapi tetangga solid)
    free_edge = []
    for y in range(h):
        for x in range(w):
            if rows[y][x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and rows[ny][nx]:
                    free_edge.append((x, y))
                    break

    rng.shuffle(edge)
    rng.shuffle(free_edge)
    inner.sort(key=lambda t: -dist[t[1]][t[0]])
    print("  kandidat: edge=%d free_edge=%d inner=%d maxdist=%d"
          % (len(edge), len(free_edge), len(inner),
             max(max(r) for r in dist)))

    for kind, count in RECIPE[mid]:
        pool = free_edge if kind in SMALL or kind == "bush" else edge
        if kind in LANDMARK:
            pool = inner
        placed = 0
        for tx, ty in pool:
            if placed >= count:
                break
            if kind not in LANDMARK:
                if not far_enough(tx, ty, pts, 2):
                    continue
                if not free_spot(tx, ty):
                    continue
            add(kind, tx, ty)
            placed += 1
        print("  %-14s %d/%d" % (kind, placed, count))

    # ---- ujung jalur buntu: beri penutup visual (peti/puing) agar tidak
    # terasa seperti jalan yang terputus tanpa alasan
    dead_kind = {"pabrik": "crates", "candi": "rubble", "source": "crate"}.get(mid, "crate")
    n_dead = 0
    for ty in range(1, h - 1):
        for tx in range(1, w - 1):
            if n_dead >= 6:
                break
            if rows[ty][tx]:
                continue
            nb = 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if not rows[ty + dy][tx + dx]:
                    nb += 1
            if nb > 1:
                continue
            if not far_enough(tx, ty, pts, 2) or not free_spot(tx, ty, 1.4):
                continue
            add(dead_kind, tx, ty, 5.0)
            n_dead += 1
    print("  ujung buntu    %d" % n_dead)

    with open(path, "w") as f:
        json.dump(props, f, ensure_ascii=False, separators=(",", ":"))
    print("%s: %d properti" % (mid, len(props)))


def main():
    rng = random.Random(20251021)
    for mid in ("pabrik", "candi", "source"):
        print("menata", mid)
        place(mid, rng)


if __name__ == "__main__":
    main()
