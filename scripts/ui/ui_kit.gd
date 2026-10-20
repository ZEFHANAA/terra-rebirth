class_name UiKit
extends RefCounted
## Kumpulan helper tampilan agar gaya UI konsisten di seluruh layar.

const BG      := Color("0b1220")
const PANEL   := Color("141d2b")
const PANEL_2 := Color("1b2636")
const PANEL_3 := Color("223045")
const BORDER  := Color("33465f")
const TEXT    := Color("e4ecf6")
const MUTED   := Color("93a7bd")
const ACCENT  := Color("4fd1a5")
const GOLD    := Color("e8b75a")
const DANGER  := Color("e8697a")
const BLUE    := Color("6fa8f0")

static var _pixel_font: Font = null

static func pixel_font() -> Font:
	if _pixel_font == null:
		var path := "res://assets/fonts/Baloo2.ttf"
		if ResourceLoader.exists(path):
			_pixel_font = load(path)
	return _pixel_font

## Kotak dasar. Bayangan lembut dipakai agar panel terpisah dari latar peta.
static func panel_style(bg: Color = PANEL, border: Color = BORDER, radius: int = 12,
		border_w: int = 1, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 4)
	return sb

## Panel utama layar (lebih gelap, garis atas lebih tebal sebagai kilau).
static func screen_style() -> StyleBoxFlat:
	var sb := panel_style(Color("101828"), Color("2b3b52"), 16, 1)
	sb.border_width_top = 2
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	return sb

static func label(text: String, size: int = 18, color: Color = TEXT, wrap: int = 0) -> Label:
	var l := Label.new()
	l.text = text
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
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

## Label kecil bergaya pixel untuk penanda bagian (MAP, TANTANGAN, BADGE).
static func kicker(text: String, color: Color = MUTED, size: int = 10) -> Label:
	return title(text.to_upper(), size, color)

## Pil berisi label singkat: level, keping data, badge.
static func chip(text: String, color: Color = MUTED, bg: Color = Color(1, 1, 1, 0.05)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(label(text, 13, color))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

static func button(text: String, size: int = 17, accent: Color = ACCENT) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	b.add_theme_stylebox_override("normal", panel_style(PANEL_2, BORDER, 9, 1, false))
	b.add_theme_stylebox_override("hover", panel_style(PANEL_3, accent, 9, 2, false))
	b.add_theme_stylebox_override("pressed", panel_style(PANEL_2.darkened(0.18), accent, 9, 2, false))
	b.add_theme_stylebox_override("focus", panel_style(Color(0, 0, 0, 0), accent, 9, 2, false))
	b.add_theme_stylebox_override("disabled", panel_style(PANEL.darkened(0.2), BORDER.darkened(0.45), 9, 1, false))
	b.custom_minimum_size.y = 44
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

## Tombol utama: latar berwarna, teks gelap, jelas sebagai aksi.
static func primary_button(text: String, color: Color = GOLD, size: int = 18) -> Button:
	var b := button(text, size, color)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = color.lightened(0.12)
	b.add_theme_stylebox_override("hover", hov)
	var pr := sb.duplicate() as StyleBoxFlat
	pr.bg_color = color.darkened(0.12)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_color_override("font_color", Color("141d2b"))
	b.add_theme_color_override("font_hover_color", Color("141d2b"))
	b.add_theme_color_override("font_pressed_color", Color("141d2b"))
	return b

## Dropdown dengan warna teks yang terbaca (bukan gelap di atas gelap).
static func dropdown(width: float = 380) -> OptionButton:
	var ob := OptionButton.new()
	ob.add_theme_font_size_override("font_size", 16)
	ob.add_theme_color_override("font_color", TEXT)
	ob.add_theme_color_override("font_hover_color", Color.WHITE)
	ob.add_theme_color_override("font_pressed_color", Color.WHITE)
	ob.add_theme_stylebox_override("normal", panel_style(PANEL_2, BORDER, 8, 1, false))
	ob.add_theme_stylebox_override("hover", panel_style(PANEL_3, ACCENT, 8, 1, false))
	ob.add_theme_stylebox_override("pressed", panel_style(PANEL_3, ACCENT, 8, 1, false))
	ob.add_theme_stylebox_override("focus", panel_style(Color(0, 0, 0, 0), ACCENT, 8, 1, false))
	ob.custom_minimum_size = Vector2(width, 40)
	return ob

## Kartu berisi konten, dengan garis aksen di sisi kiri.
static func card(child: Control, accent: Color = Color(0, 0, 0, 0), bg: Color = Color("16202f")) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := panel_style(bg, BORDER, 10, 1, false)
	if accent.a > 0.0:
		sb.border_width_left = 3
		sb.border_color = accent
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(child)
	return p

## Garis pemisah tipis.
static func rule(color: Color = Color(1, 1, 1, 0.08)) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size.y = 1
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
