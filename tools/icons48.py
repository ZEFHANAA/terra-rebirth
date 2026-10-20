"""Ikon objek 48x48 bergaya kartun halus (pengganti ikon pixel 16x16)."""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/assets/sprites"
S = 4          # supersample
N = 48         # ukuran akhir


def canvas():
    return Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))


def p(v):
    return v * S


def outline(d, box, radius, fill, line=(46, 34, 26), width=2.4):
    d.rounded_rectangle([p(box[0]), p(box[1]), p(box[2]), p(box[3])], radius=p(radius),
                        fill=fill, outline=line, width=int(p(width)))


def save(im, name):
    im = im.resize((N, N), Image.LANCZOS)
    im.save(os.path.join(OUT, name))
    print("ok", name)


def sign():
    im = canvas()
    d = ImageDraw.Draw(im)
    # bayangan
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([p(9), p(39), p(39), p(45)], fill=(30, 40, 30, 110))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(p(2.5))))
    d = ImageDraw.Draw(im)
    # tiang
    for x in (16, 30):
        outline(d, (x, 22, x + 4, 42), 1.6, (146, 104, 64))
    # papan
    outline(d, (6, 6, 42, 27), 4, (198, 152, 92))
    d.rounded_rectangle([p(9), p(9), p(39), p(24)], radius=p(2.5), fill=(224, 186, 126))
    # garis teks
    for i, w in enumerate((22, 16, 19)):
        d.rounded_rectangle([p(12), p(12 + i * 4), p(12 + w), p(13.6 + i * 4)], radius=p(0.9),
                            fill=(120, 86, 54))
    # paku
    for x in (9, 39):
        d.ellipse([p(x - 1.4), p(9), p(x + 1.4), p(11.8)], fill=(120, 92, 62))
    save(im, "obj_sign.png")


def part():
    im = canvas()
    d = ImageDraw.Draw(im)
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([p(7), p(34), p(41), p(44)], fill=(30, 40, 30, 115))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(p(2.5))))
    d = ImageDraw.Draw(im)
    # papan PCB
    outline(d, (7, 12, 41, 36), 4, (58, 118, 158), line=(22, 46, 74), width=2.4)
    d.rounded_rectangle([p(10), p(15), p(38), p(33)], radius=p(2.6), fill=(74, 142, 186))
    # chip
    outline(d, (16, 19, 32, 29), 2.2, (36, 44, 56), line=(18, 22, 30), width=2)
    for i in range(3):
        d.rounded_rectangle([p(18 + i * 4.6), p(21), p(20.4 + i * 4.6), p(27)], radius=p(0.8),
                            fill=(126, 226, 204))
    # antena
    d.line([p(36), p(12), p(40), p(4)], fill=(120, 128, 140), width=int(p(1.8)))
    d.ellipse([p(37.6), p(1.6), p(42.4), p(6.4)], fill=(240, 196, 96), outline=(150, 110, 40),
              width=int(p(1.2)))
    # konektor emas
    for i in range(4):
        d.rounded_rectangle([p(12 + i * 6.4), p(36), p(15.6 + i * 6.4), p(41)], radius=p(1.2),
                            fill=(226, 190, 104), outline=(150, 116, 44), width=int(p(1.2)))
    save(im, "obj_part.png")


if __name__ == "__main__":
    sign()
    part()
