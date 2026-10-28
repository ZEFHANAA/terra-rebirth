class_name UiKit
extends RefCounted
## Kumpulan helper tampilan agar gaya UI konsisten di seluruh layar.
## Tema: papan kayu + kertas lusuh di tengah hutan Terra Rebirth.

const BG      := Color("0c1712")
const PANEL   := Color("182a1e")
const PANEL_2 := Color("22372a")
const PANEL_3 := Color("2c4635")
const BORDER  := Color("4a6b45")
const TEXT    := Color("f0e6cf")
const MUTED   := Color("a9b79a")
const ACCENT  := Color("8cc65c")
const GOLD    := Color("e3b04a")
const DANGER  := Color("d0604a")
const BLUE    := Color("7fb6c9")
## Kertas soal: latar terang dengan tinta cokelat tua.
const PARCH   := Color("e8dab6")
const INK     := Color("33240f")

## Tema per wilayah. Panel kuis/puzzle memakai bahan wilayahnya sendiri supaya
## terasa bagian dari peta: kayu hutan, besi pabrik, batu candi, kayu apung danau,
## obsidian The Source.
const THEMES := {
	"kota": {
		"frame": "res://assets/ui/frame_kota.png",
		"paper": "res://assets/ui/card_kota.png",
		"ribbon": "res://assets/ui/ribbon_kota.png",
		"ink": Color("33240f"), "accent": Color("e3b04a"),
		"dim": Color(0.02, 0.05, 0.03, 0.86),
	},
	"hutan": {
		"frame": "res://assets/ui/frame_hutan.png",
		"paper": "res://assets/ui/card_hutan.png",
		"ribbon": "res://assets/ui/ribbon_hutan.png",
		"ink": Color("1d320f"), "accent": Color("9ed46a"),
		"dim": Color(0.02, 0.06, 0.03, 0.86),
	},
	"pabrik": {
		"frame": "res://assets/ui/frame_pabrik.png",
		"paper": "res://assets/ui/card_pabrik.png",
		"ribbon": "res://assets/ui/ribbon_pabrik.png",
		"ink": Color("1b2730"), "accent": Color("e0914c"),
		"dim": Color(0.03, 0.04, 0.05, 0.88),
	},
	"candi": {
		"frame": "res://assets/ui/frame_candi.png",
		"paper": "res://assets/ui/card_candi.png",
		"ribbon": "res://assets/ui/ribbon_candi.png",
		"ink": Color("3a2a12"), "accent": Color("e6c878"),
		"dim": Color(0.05, 0.04, 0.03, 0.88),
	},
	"danau": {
		"frame": "res://assets/ui/frame_danau.png",
		"paper": "res://assets/ui/card_danau.png",
		"ribbon": "res://assets/ui/ribbon_danau.png",
		"ink": Color("0f3038"), "accent": Color("8fd6d6"),
		"dim": Color(0.02, 0.05, 0.06, 0.87),
	},
	"source": {
		"frame": "res://assets/ui/frame_source.png",
		"paper": "res://assets/ui/card_source.png",
		"ribbon": "res://assets/ui/ribbon_source.png",
		"ink": Color("2a1a3a"), "accent": Color("c79cf0"),
		"dim": Color(0.04, 0.02, 0.06, 0.90),
	},
}

const FONT_BODY := "res://assets/fonts/Baloo2.ttf"
const FONT_PIXEL := "res://assets/fonts/PressStart2P.ttf"

static var _pixel_font: Font = null
static var _body_font: Font = null
static var _tex_cache: Dictionary = {}
static var _theme_key := ""

## Ganti tema sesuai wilayah yang sedang dibuka. String kosong = tema dasar (Kota).
static func set_theme(map_id: String) -> void:
	_theme_key = map_id if THEMES.has(map_id) else ""

static func theme_key() -> String:
	return _theme_key if _theme_key != "" else "kota"

static func theme() -> Dictionary:
	return THEMES[theme_key()]

static func theme_ink() -> Color:
	return theme()["ink"]

static func theme_accent() -> Color:
	return theme()["accent"]

static func theme_dim() -> Color:
	return theme()["dim"]

## Tombol papan mengikuti bahan wilayah: "" (normal), "_hover", "_press".
static func btn_tex(state: String = "") -> String:
	return "res://assets/ui/btn_%s%s.png" % [theme_key(), state]

static func pixel_font() -> Font:
	if _pixel_font == null:
		if ResourceLoader.exists(FONT_PIXEL):
			_pixel_font = load(FONT_PIXEL)
		elif ResourceLoader.exists(FONT_BODY):
			_pixel_font = load(FONT_BODY)
	return _pixel_font

static func body_font() -> Font:
	if _body_font == null and ResourceLoader.exists(FONT_BODY):
		_body_font = load(FONT_BODY)
	return _body_font

## 9-patch dari tekstur pixel. Margin dalam piksel tekstur.
static func tex_style(path: String, margin: int = 32, tile_center: bool = false) -> StyleBoxTexture:
	var key := "%s|%d|%s" % [path, margin, str(tile_center)]
	if _tex_cache.has(key):
		return (_tex_cache[key] as StyleBoxTexture).duplicate() as StyleBoxTexture
	var sb := StyleBoxTexture.new()
	if ResourceLoader.exists(path):
		sb.texture = load(path)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	if tile_center:
		# Bagian tengah diulang, bukan ditarik, supaya butir kertas tidak jadi garis.
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	else:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	_tex_cache[key] = sb
	return sb.duplicate() as StyleBoxTexture

## Bingkai kayu untuk panel layar penuh.
static func frame_style(pad_h: int = 30, pad_v: int = 22) -> StyleBoxTexture:
	var sb := tex_style(str(theme()["frame"]), 34)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb

## Pita kayu gelap untuk kepala panel (nama wilayah, nyawa).
static func ribbon_style() -> StyleBoxTexture:
	var sb := tex_style(str(theme()["ribbon"]), 20)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

## Kertas lusuh untuk teks soal dan pilihan jawaban.
static func parchment_style(pad_h: int = 22, pad_v: int = 16) -> StyleBoxTexture:
	var sb := tex_style(str(theme()["paper"]), 22)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb

## Kotak datar kecil (chip, tabel) dengan sudut hampir tegak.
static func panel_style(bg: Color = PANEL, border: Color = BORDER, radius: int = 3,
		border_w: int = 2, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 4)
	return sb

## Panel layar: bingkai kayu, bukan kotak polos.
static func screen_style() -> StyleBoxTexture:
	return frame_style(32, 24)

static func label(text: String, size: int = 18, color: Color = TEXT, wrap: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	var f := body_font()
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap
	return l

## Teks paragraf dengan jarak baris lega agar tidak terasa padat.
static func body(text: String, size: int = 18, color: Color = TEXT, wrap: int = 0) -> Label:
	var l := label(text, size, color, wrap)
	l.add_theme_constant_override("line_spacing", 6)
	return l

static func title(text: String, size: int = 22, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	var f := pixel_font()
	if f:
		l.add_theme_font_override("font", f)
	# Huruf pixel jauh lebih lebar; kecilkan sedikit agar tidak meluber.
	var fs := int(max(8, round(size * 0.62)))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	# Bayangan 1 px saja: pada huruf pixel kecil, offset 2 px terbaca seperti teks dobel.
	var off := 1 if fs <= 12 else 2
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.42))
	l.add_theme_constant_override("shadow_offset_x", off)
	l.add_theme_constant_override("shadow_offset_y", off)
	return l

## Label kecil bergaya pixel untuk penanda bagian (MAP, TANTANGAN, BADGE).
static func kicker(text: String, color: Color = MUTED, size: int = 10) -> Label:
	var l := title(text.to_upper(), size, color)
	return l

## Pil berisi label singkat: uang dan badge.
static func chip(text: String, color: Color = MUTED, bg: Color = Color(1, 1, 1, 0.05)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg if bg.a > 0.0 else Color(0.06, 0.1, 0.07, 0.85)
	sb.border_color = color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(title(text.to_upper(), 10, color))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

## Tombol papan kayu. Teks krem, jelas terbaca di atas kayu.
static func button(text: String, size: int = 17, accent: Color = ACCENT) -> Button:
	var b := Button.new()
	b.text = text
	var f := body_font()
	if f:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color("fff6de"))
	b.add_theme_color_override("font_pressed_color", Color("e8dcc0"))
	b.add_theme_color_override("font_disabled_color", Color("8d8a76"))
	b.add_theme_stylebox_override("normal", tex_style(btn_tex(), 18))
	b.add_theme_stylebox_override("hover", tex_style(btn_tex("_hover"), 18))
	b.add_theme_stylebox_override("pressed", tex_style(btn_tex("_press"), 18))
	var focus := tex_style(btn_tex("_hover"), 18)
	focus.draw_center = false
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", tex_style(btn_tex("_press"), 18))
	b.custom_minimum_size.y = 44
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_constant_override("outline_size", 0)
	return b

## Tombol utama: daun hijau, teks krem terang.
static func primary_button(text: String, color: Color = GOLD, size: int = 18) -> Button:
	var b := button(text, size, color)
	b.add_theme_stylebox_override("normal", tex_style("res://assets/ui/btn_leaf.png", 18))
	b.add_theme_stylebox_override("hover", tex_style("res://assets/ui/btn_leaf_hover.png", 18))
	b.add_theme_stylebox_override("pressed", tex_style("res://assets/ui/btn_leaf_press.png", 18))
	b.add_theme_color_override("font_color", Color("f4ffe4"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("dbe8c8"))
	return b

## Pilihan jawaban bergaya kertas lusuh: teks tinta cokelat.
static func choice_button(text: String, size: int = 18) -> Button:
	var b := Button.new()
	b.text = text
	var f := body_font()
	if f:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", theme_ink())
	b.add_theme_color_override("font_hover_color", theme_ink().darkened(0.25))
	b.add_theme_color_override("font_pressed_color", theme_ink().darkened(0.25))
	b.add_theme_color_override("font_disabled_color", Color("6f6350"))
	b.add_theme_stylebox_override("normal", parchment_style(20, 12))
	b.add_theme_stylebox_override("hover", parchment_style(20, 12))
	b.add_theme_stylebox_override("pressed", parchment_style(20, 12))
	b.add_theme_stylebox_override("disabled", parchment_style(20, 12))
	b.custom_minimum_size.y = 50
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

## Dropdown dengan warna teks yang terbaca (bukan gelap di atas gelap).
static func dropdown(width: float = 380) -> OptionButton:
	var ob := OptionButton.new()
	var f := body_font()
	if f:
		ob.add_theme_font_override("font", f)
	ob.add_theme_font_size_override("font_size", 16)
	ob.add_theme_color_override("font_color", TEXT)
	ob.add_theme_color_override("font_hover_color", Color.WHITE)
	ob.add_theme_color_override("font_pressed_color", Color.WHITE)
	ob.add_theme_stylebox_override("normal", tex_style(btn_tex(), 18))
	ob.add_theme_stylebox_override("hover", tex_style(btn_tex("_hover"), 18))
	ob.add_theme_stylebox_override("pressed", tex_style(btn_tex("_press"), 18))
	ob.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ob.custom_minimum_size = Vector2(width, 42)
	return ob

## Kartu berisi konten. `paper` = kertas terang, selain itu papan hijau.
static func card(child: Control, accent: Color = Color(0, 0, 0, 0), bg: Color = Color("16241b")) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = accent if accent.a > 0.0 else BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(child)
	return p

## Kartu kertas lusuh untuk soal/penjelasan panjang.
static func paper_card(child: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", parchment_style(22, 16))
	p.add_child(child)
	return p

## Garis pemisah bergaya ukiran kayu.
static func rule(color: Color = Color("3b5537")) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size.y = 2
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c

static func vbox(sep: int = 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func expander() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c
