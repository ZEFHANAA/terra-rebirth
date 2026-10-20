"""
Terra Rebirth — generator aset pixel art (original, bebas lisensi).
Menghasilkan: tiles, karakter, NPC, ikon badge, panel UI, latar judul.
Jalankan: python3 assets_gen.py
"""
from PIL import Image, ImageDraw, ImageFilter
import os, math, random

OUT = "assets"
os.makedirs(f"{OUT}/sprites", exist_ok=True)
os.makedirs(f"{OUT}/ui", exist_ok=True)

# ---------------------------------------------------------------- palet
OUTLINE = (18, 22, 32, 255)

SKIN = (232, 180, 138, 255)
SKIN_D = (196, 142, 104, 255)
HAIR = (58, 42, 32, 255)
BOOT = (74, 52, 40, 255)

def c(hexs):
    hexs = hexs.lstrip("#")
    return tuple(int(hexs[i:i+2], 16) for i in (0, 2, 4)) + (255,)

# ---------------------------------------------------------------- util
def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def rect(d, box, fill):
    d.rectangle(box, fill=fill)

def px(img, x, y, col):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), col)

def outline(img, col=OUTLINE):
    """Tambah outline 1px di sekeliling pixel tidak transparan."""
    src = img.copy()
    w, h = img.size
    out = img.copy()
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] != 0:
                continue
            near = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3] > 0:
                    near = True
                    break
            if near:
                out.putpixel((x, y), col)
    return out

# ================================================================ KARAKTER
# 24x32, 4 arah (down, up, left, right), 3 frame (idle, step1, step2).
# Gaya: outline tebal, cel-shading 3 tingkat, ikat pinggang merah + syal.
SPRITE_W, SPRITE_H = 24, 32

def shade(col, f):
    """f > 0 menuju putih, f < 0 menuju hitam."""
    r, g, b = col[:3]
    if f >= 0:
        r, g, b = [int(v + (255 - v) * f) for v in (r, g, b)]
    else:
        r, g, b = [int(v * (1 + f)) for v in (r, g, b)]
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), 255)

def make_pal(coat, sash, scarf, hair, skin=(240, 196, 154, 255), pants=None, boot=None):
    return dict(
        coat=coat, coat_d=shade(coat, -0.38), coat_l=shade(coat, 0.26),
        sash=sash, sash_d=shade(sash, -0.32),
        scarf=scarf, scarf_d=shade(scarf, -0.18),
        hair=hair, hair_l=shade(hair, 0.28),
        skin=skin, skin_d=shade(skin, -0.22),
        pants=pants or shade(coat, -0.18), pants_d=shade(pants or coat, -0.42),
        boot=boot or (74, 58, 48, 255), boot_l=shade(boot or (74, 58, 48, 255), 0.30),
        eye=(20, 22, 30, 255), white=(236, 244, 255, 255),
    )

_LET = {"h": "hair", "H": "hair_l", "s": "skin", "S": "skin_d",
        "c": "coat", "C": "coat_d", "L": "coat_l",
        "r": "sash", "R": "sash_d", "f": "scarf", "F": "scarf_d",
        "p": "pants", "P": "pants_d", "b": "boot", "B": "boot_l",
        "e": "eye", "w": "white"}


def _grid():
    return [["." for _ in range(SPRITE_W)] for _ in range(SPRITE_H)]


def _row(g, y, x, s):
    if y < 0 or y >= SPRITE_H:
        return
    for i, ch in enumerate(s):
        if ch != "." and 0 <= x + i < SPRITE_W:
            g[y][x + i] = ch


def _paint(g, pal):
    im = new(SPRITE_W, SPRITE_H)
    d = ImageDraw.Draw(im)
    for y in range(SPRITE_H):
        for x in range(SPRITE_W):
            ch = g[y][x]
            if ch in _LET:
                d.point((x, y), fill=pal[_LET[ch]])
    return outline(im)


def _body(g, pal, bob, st, side):
    ly = 22
    if side is None:
        for i, x0 in enumerate((8, 13)):
            dy = (-st if i == 0 else st)
            for y in range(ly + dy, ly + 6 + dy):
                _row(g, y, x0, "ppp")
            _row(g, ly + 5 + dy, x0, "PPP")
            _row(g, ly + 6 + dy, x0, "bbb")
            _row(g, ly + 7 + dy, x0, "bBb")
    else:
        dy = -st
        _row(g, ly + dy, 10, "pppp")
        _row(g, ly + 1 + dy, 9, "pppppp")
        for y in range(ly + 2 + dy, ly + 6 + dy):
            _row(g, y, 9, "pppppp")
        _row(g, ly + 5 + dy, 9, "PPPPPP")
        _row(g, ly + 6 + dy, 9, "bbbbbb")
        _row(g, ly + 7 + dy, 8, "bBBBBBb")
        _row(g, ly + 8 + dy, 9, "bbbbbb")

    ty = 12 + bob
    _row(g, ty, 7, "LcccccccC")
    for y in range(ty + 1, ty + 5):
        _row(g, y, 7, "LcccccccC")
    _row(g, ty + 5, 7, "rrrrrrrrrr")
    _row(g, ty + 6, 7, "RRRRRRRRRR")
    for y in range(ty + 7, ty + 10):
        _row(g, y, 8, "CCCCCCCC")
    _row(g, ty + 1, 11, "C")
    _row(g, ty + 3, 11, "C")

    ao = 0 if st == 0 else (1 if st > 0 else -1)
    if side is None:
        for y in range(ty + 1, ty + 8):
            _row(g, y, 5, "LL")
            _row(g, y, 17, "LL")
        _row(g, ty + 8 - ao, 5, "SS")
        _row(g, ty + 8 + ao, 17, "SS")
    elif side == "left":
        for y in range(ty + 1, ty + 8):
            _row(g, y, 5, "LL")
        _row(g, ty + 8 - ao, 5, "SS")
    else:
        for y in range(ty + 1, ty + 8):
            _row(g, y, 17, "LL")
        _row(g, ty + 8 + ao, 17, "SS")

    _row(g, ty - 1, 9, "ffffff")
    _row(g, ty, 9, "fFffFf")


def _head_down(g, hy):
    _row(g, hy, 9, "hhhhhh")
    _row(g, hy + 1, 8, "hhhhhhhh")
    _row(g, hy + 2, 7, "hhhhhhhhhh")
    _row(g, hy + 3, 7, "hhhhhhhhhh")
    _row(g, hy + 4, 8, "ssssssss")
    _row(g, hy + 5, 9, "ssssss")
    _row(g, hy + 6, 9, "ssssss")
    _row(g, hy + 7, 9, "ssssss")
    _row(g, hy + 4, 9, "hhhh")
    _row(g, hy + 6, 10, "e")
    _row(g, hy + 6, 13, "e")
    _row(g, hy + 8, 9, "SSSSSS")
    _row(g, hy + 8, 11, "SS")
    _row(g, hy + 9, 10, "SSSS")


def _head_up(g, hy):
    _row(g, hy, 9, "hhhhhh")
    _row(g, hy + 1, 8, "hhhhhhhh")
    for y in range(hy + 2, hy + 9):
        _row(g, y, 7, "hhhhhhhhhh")
    _row(g, hy + 4, 10, "HHHH")
    _row(g, hy + 9, 10, "SSSS")


def _head_left(g, hy):
    _row(g, hy, 9, "hhhhhh")
    _row(g, hy + 1, 8, "hhhhhhhh")
    _row(g, hy + 2, 7, "hhhhhhhhhh")
    for y in range(hy + 3, hy + 8):
        _row(g, y, 8, "sssssshh")
    _row(g, hy + 3, 8, "hhhh")
    _row(g, hy + 4, 8, "hh")
    _row(g, hy + 6, 9, "e")
    _row(g, hy + 8, 9, "SSSSSS")
    _row(g, hy + 9, 10, "SSSS")


def _head_right(g, hy):
    _row(g, hy, 9, "hhhhhh")
    _row(g, hy + 1, 8, "hhhhhhhh")
    _row(g, hy + 2, 7, "hhhhhhhhhh")
    for y in range(hy + 3, hy + 8):
        _row(g, y, 8, "hhssssss")
    _row(g, hy + 3, 12, "hhhh")
    _row(g, hy + 4, 14, "hh")
    _row(g, hy + 6, 13, "e")
    _row(g, hy + 8, 9, "SSSSSS")
    _row(g, hy + 9, 10, "SSSS")


def draw_actor(direction, frame, pal):
    g = _grid()
    bob = 0 if frame == 0 else -1
    st = 0 if frame == 0 else (1 if frame == 1 else -1)
    side = None if direction in ("down", "up") else direction
    _body(g, pal, bob, st, side)
    hy = 1 + bob
    {"down": _head_down, "up": _head_up,
     "left": _head_left, "right": _head_right}[direction](g, hy)

    ty = 12 + bob
    if direction == "down":
        _row(g, ty + 9, 4, "r")
        _row(g, ty + 10, 4, "r")
        _row(g, ty + 11, 4, "R")
    elif direction == "up":
        _row(g, ty + 7, 18, "rr")
        _row(g, ty + 8, 18, "rr")
        _row(g, ty + 9, 19, "RR")
    else:
        _row(g, ty + 6, 18, "rr")
        _row(g, ty + 7, 18, "rr")
        _row(g, ty + 8, 19, "RR")
    return _paint(g, pal)


def make_sheet(pal, path=None):
    dirs = ["down", "up", "left", "right"]
    sheet = new(SPRITE_W * 3, SPRITE_H * 4)
    for r, dr in enumerate(dirs):
        for f in range(3):
            fr = draw_actor(dr, f, pal)
            sheet.paste(fr, (f * SPRITE_W, r * SPRITE_H), fr)
    if path:
        sheet.save(path)
    return sheet

# ================================================================ IKON BADGE
def badge_crystal(path):
    im = new(24, 24); d = ImageDraw.Draw(im)
    d.polygon([(12, 2), (20, 9), (12, 22), (4, 9)], fill=c("3ee0a4"), outline=c("0e5a41"))
    d.polygon([(12, 2), (16, 9), (12, 22)], fill=c("7bf0c6"))
    d.line([(4, 9), (20, 9)], fill=c("d8fff0"))
    outline(im).save(path)

def badge_gear(path):
    im = new(24, 24); d = ImageDraw.Draw(im)
    d.ellipse([6, 6, 18, 18], fill=c("c9d6e6"), outline=c("5a6b82"))
    for i in range(8):
        a = i * math.pi / 4
        x, y = 12 + math.cos(a) * 8, 12 + math.sin(a) * 8
        d.rectangle([x - 2, y - 2, x + 2, y + 2], fill=c("c9d6e6"), outline=c("5a6b82"))
    d.ellipse([10, 10, 14, 14], fill=c("2c3a52"))
    outline(im).save(path)

def badge_key(path):
    im = new(24, 24); d = ImageDraw.Draw(im)
    d.ellipse([4, 3, 14, 13], outline=c("f2c14e"), width=3)
    d.rectangle([11, 12, 14, 21], fill=c("f2c14e"))
    d.rectangle([14, 16, 18, 19], fill=c("f2c14e"))
    d.rectangle([14, 20, 17, 21], fill=c("f2c14e"))
    outline(im).save(path)

def badge_signal(path):
    im = new(24, 24); d = ImageDraw.Draw(im)
    d.rectangle([10, 12, 14, 21], fill=c("63a8ff"))
    d.ellipse([7, 3, 17, 13], fill=c("63a8ff"), outline=c("1d4f8f"))
    for r in (4, 7, 10):
        d.arc([12 - r, 8 - r, 12 + r, 8 + r], start=200, end=340, fill=c("9fd0ff"))
    outline(im).save(path)

def badge_trophy(path):
    im = new(24, 24); d = ImageDraw.Draw(im)
    d.rectangle([6, 3, 18, 11], fill=c("f2c14e"), outline=c("8a6a1c"))
    d.rectangle([9, 11, 15, 15], fill=c("d9a733"))
    d.rectangle([6, 15, 18, 19], fill=c("8a6a1c"))
    d.arc([2, 4, 9, 12], start=90, end=270, fill=c("f2c14e"), width=2)
    d.arc([15, 4, 22, 12], start=270, end=90, fill=c("f2c14e"), width=2)
    outline(im).save(path)

# ================================================================ LATAR JUDUL
def title_bg(path, w=1280, h=720):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    top, bot = (12, 22, 38), (32, 74, 66)
    for y in range(h):
        t = y / h
        col = tuple(int(top[i] + (bot[i] - top[i]) * (t ** 0.8)) for i in range(3))
        d.line([(0, y), (w, y)], fill=col)

    rnd = random.Random(7)
    for _ in range(180):
        x, y = rnd.randrange(w), rnd.randrange(h // 2)
        a = rnd.randint(60, 160)
        d.point((x, y), fill=(200, 220, 255))

    # bulan
    d.ellipse([w - 260, 70, w - 140, 190], fill=(226, 240, 220))
    d.ellipse([w - 300, 90, w - 180, 210], fill=(20, 40, 50))

    # gunung berlapis
    layers = [
        ((26, 46, 58), 0.55, 90),
        ((20, 38, 46), 0.45, 140),
        ((15, 30, 36), 0.35, 200),
    ]
    for col, amp, base in layers:
        pts = [(0, h)]
        for x in range(0, w + 40, 40):
            y = h - base - int(math.sin(x / 160.0) * amp * 60) - rnd.randint(0, 30)
            pts.append((x, y))
        pts.append((w, h))
        d.polygon(pts, fill=col)

    # tanah
    d.rectangle([0, h - 90, w, h], fill=(12, 26, 24))
    for _ in range(400):
        x = rnd.randrange(w)
        y = rnd.randrange(h - 90, h)
        d.point((x, y), fill=(18, 40, 34))

    # kabut
    fog = new(w, h)
    fd = ImageDraw.Draw(fog)
    for i in range(6):
        y = h - 160 - i * 26
        fd.ellipse([-100 + i * 40, y, w + 100 - i * 30, y + 70], fill=(120, 200, 170, 18))
    im = Image.alpha_composite(im.convert("RGBA"), fog).convert("RGB")
    im = im.filter(ImageFilter.GaussianBlur(0.4))
    im.save(path)


def obj_sign(path):
    im = new(16, 16); d = ImageDraw.Draw(im)
    d.rectangle([7, 8, 8, 15], fill=(92, 66, 42, 255))
    d.rectangle([1, 2, 14, 8], fill=(158, 116, 62, 255), outline=(74, 50, 26, 255))
    d.line([3, 4, 12, 4], fill=(238, 224, 190, 255))
    d.line([3, 6, 9, 6], fill=(238, 224, 190, 255))
    im.save(path)

def obj_part(path):
    im = new(16, 16); d = ImageDraw.Draw(im)
    d.rectangle([2, 4, 13, 11], fill=(58, 118, 158, 255), outline=(20, 48, 78, 255))
    for i in range(3):
        d.rectangle([4 + i * 3, 6, 5 + i * 3, 9], fill=(126, 226, 204, 255))
    d.rectangle([5, 11, 10, 14], fill=(206, 180, 92, 255))
    d.rectangle([6, 12, 9, 13], fill=(120, 96, 40, 255))
    im.save(path)

# ================================================================ PANEL UI
def ui_panel(path, w=48, h=48):
    im = new(w, h); d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=8, fill=(16, 26, 42, 240), outline=(48, 70, 100, 255), width=2)
    d.rounded_rectangle([4, 4, w - 5, h - 5], radius=6, outline=(30, 46, 68, 255), width=1)
    im.save(path)

if __name__ == "__main__":
    HERO = make_pal(coat=c("2f4054"), sash=c("d1442f"), scarf=c("e9dfc6"), hair=c("3a2b26"))
    make_sheet(HERO, path=f"{OUT}/sprites/hero.png")

    npcs = {
        "kepala":   make_pal(coat=c("8a6a34"), sash=c("d9b44a"), scarf=c("efe6cd"), hair=c("5b452f")),
        "peneliti": make_pal(coat=c("39675c"), sash=c("7fd6c0"), scarf=c("e3efe4"), hair=c("2f3b34")),
        "teknisi":  make_pal(coat=c("7a5334"), sash=c("d9a441"), scarf=c("e8dcc4"), hair=c("3d2d22")),
        "penjaga":  make_pal(coat=c("4a5568"), sash=c("9aa8bc"), scarf=c("dfe6ef"), hair=c("2b303a")),
        "inventor": make_pal(coat=c("35607a"), sash=c("7fd6c0"), scarf=c("e2eef4"), hair=c("33313c")),
        "guardian": make_pal(coat=c("7a3a3a"), sash=c("d1442f"), scarf=c("e9d9c6"), hair=c("3a2626")),
        "pedagang": make_pal(coat=c("8a6238"), sash=c("d9a441"), scarf=c("eee2c8"), hair=c("4a3423")),
    }
    for name, pal in npcs.items():
        make_sheet(pal, path=f"{OUT}/sprites/npc_{name}.png")

    badge_crystal(f"{OUT}/ui/badge_nature.png")
    badge_gear(f"{OUT}/ui/badge_core.png")
    badge_key(f"{OUT}/ui/badge_cipher.png")
    badge_signal(f"{OUT}/ui/badge_aqua.png")
    badge_trophy(f"{OUT}/ui/badge_guardian.png")

    title_bg(f"{OUT}/ui/title_bg.png")
    ui_panel(f"{OUT}/ui/panel.png")
    obj_sign(f"{OUT}/sprites/obj_sign.png")
    obj_part(f"{OUT}/sprites/obj_part.png")
    print("aset dasar selesai")
