extends Node2D
## Gerbang portal bergaya pixel-art: lengkung batu ber-outline gelap,
## permukaan bercahaya berdenyut (terbuka) atau redup + gembok besar (terkunci).
## Menyala terang saat pemain mendekat (world.gd mengatur `near`).

var color := Color("3ee0a4")
var locked := false
var near := false
var _t := 0.0

const STONE := Color("8f8d85")
const STONE_D := Color("615f59")
const STONE_L := Color("b6b3a8")
const EDGE := Color("2b2a27")          # outline gelap
const MORTAR := Color("74726c")        # sambungan antar batu

const HALF_W := 54.0       # setengah lebar luar gerbang
const TOP := -138.0        # puncak lengkung
const OPEN_W := 32.0       # setengah lebar lubang portal
const OPEN_TOP := -102.0   # puncak lubang
const LEG_W := 17.0        # tebal pilar
const LEG_X0 := -HALF_W    # sisi luar pilar kiri
const LEG_X1 := HALF_W - LEG_W  # sisi kiri pilar kanan


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var base := color if not locked else Color("5a6a86")
	var pulse := 0.5 + 0.5 * sin(_t * 2.4)

	_draw_ground_glow(base, pulse)
	_draw_surface(base, pulse)
	_draw_frame()
	_draw_keystone()

	if locked:
		_draw_lock_bar()
	else:
		_draw_sparkles(base, pulse)

	if near:
		_draw_near_highlight(base, pulse)


# ---------------------------------------------------------------------------

func _draw_ground_glow(base: Color, pulse: float) -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.34))
	draw_circle(Vector2.ZERO, HALF_W * 1.1, Color(0, 0, 0, 0.26))
	if not locked:
		for i in range(3, 0, -1):
			draw_circle(Vector2.ZERO, HALF_W * (0.5 + i * 0.22),
				Color(base.r, base.g, base.b, 0.05 * pulse * (4 - i) / 3.0))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_surface(base: Color, pulse: float) -> void:
	var h := (-OPEN_TOP) - 6.0
	var cy := OPEN_TOP + h * 0.5

	if not locked:
		# halo besar di belakang lengkung
		for i in range(5, 0, -1):
			draw_circle(Vector2(0, cy), OPEN_W * (1.35 + i * 0.16),
				Color(base.r, base.g, base.b, 0.028 * pulse * (6 - i) / 5.0))

	# permukaan portal (elips) — dasar pekat supaya dinding di belakang tidak tembus
	draw_set_transform(Vector2(0, cy), 0, Vector2(1, h / (OPEN_W * 2.0)))
	draw_circle(Vector2.ZERO, OPEN_W * 1.02,
		Color(0.07, 0.09, 0.15, 0.94) if locked else Color(0.04, 0.16, 0.14, 0.86))
	for i in range(5, 0, -1):
		draw_circle(Vector2.ZERO, OPEN_W * (0.55 + i * 0.12),
			Color(base.r, base.g, base.b, 0.05 + 0.05 * pulse))
	var core_a := 0.30 + 0.18 * pulse if not locked else 0.20
	draw_circle(Vector2.ZERO, OPEN_W * (0.98 + 0.03 * pulse), Color(base.r, base.g, base.b, core_a))
	draw_circle(Vector2.ZERO, OPEN_W * 0.70, Color(base.r, base.g, base.b, core_a + 0.12))
	if not locked:
		draw_circle(Vector2.ZERO, OPEN_W * 0.34, Color(1, 1, 1, 0.20 + 0.16 * pulse))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# pusaran di dalam portal (tetap ada walau terkunci, hanya lebih redup)
	var swirl_a := 0.16 + 0.10 * pulse if not locked else 0.07
	for i in range(3):
		var rr := OPEN_W * (0.35 + i * 0.22)
		var a0: float = _t * (0.8 + i * 0.35) + i
		draw_arc(Vector2(0, cy), rr, a0, a0 + 2.0, 10, Color(1, 1, 1, swirl_a), 1.6)


func _draw_frame() -> void:
	var leg_h := -OPEN_TOP - 4.0

	# --- outline gelap (siluet) digambar lebih dulu
	for sx in [-1.0, 1.0]:
		var x0: float = LEG_X0 if sx < 0.0 else LEG_X1
		draw_rect(Rect2(x0 - 2, OPEN_TOP - 2, LEG_W + 4, leg_h + 4), EDGE)
		draw_rect(Rect2(x0 - 6, -14.0, LEG_W + 12, 12.0), EDGE)   # alas
		draw_rect(Rect2(x0 - 5, OPEN_TOP - 8, LEG_W + 10, 10.0), EDGE)  # kapitel
	draw_arc(Vector2(0, OPEN_TOP), HALF_W - LEG_W * 0.5, PI, TAU, 28, EDGE, LEG_W + 4)
	draw_rect(Rect2(-15.0, TOP - 8, 30.0, 16.0), EDGE)           # batu puncak

	# --- tangga / alas
	draw_rect(Rect2(-58.0, -8.0, 116.0, 8.0), EDGE)
	draw_rect(Rect2(-56.0, -8.0, 112.0, 8.0), STONE_L)
	draw_rect(Rect2(-56.0, -8.0, 112.0, 2.0), STONE)
	draw_rect(Rect2(-48.0, -14.0, 96.0, 6.0), EDGE)
	draw_rect(Rect2(-46.0, -14.0, 92.0, 6.0), STONE)

	# --- pilar + bayangan + sambungan batu
	for sx in [-1.0, 1.0]:
		var x0: float = LEG_X0 if sx < 0.0 else LEG_X1
		draw_rect(Rect2(x0, OPEN_TOP, LEG_W, leg_h), STONE)
		draw_rect(Rect2(x0, OPEN_TOP, 4.0, leg_h), STONE_L)
		draw_rect(Rect2(x0 + LEG_W - 4.0, OPEN_TOP, 4.0, leg_h), STONE_D)
		# sambungan bata
		var yy := OPEN_TOP + 14.0
		while yy < -16.0:
			draw_line(Vector2(x0, yy), Vector2(x0 + LEG_W, yy), MORTAR, 2.0)
			yy += 14.0
		# alas pilar
		draw_rect(Rect2(x0 - 4.0, -12.0, LEG_W + 8.0, 10.0), STONE_L)
		draw_rect(Rect2(x0 - 4.0, -12.0, LEG_W + 8.0, 3.0), STONE_D)
		# kapitel
		draw_rect(Rect2(x0 - 3.0, OPEN_TOP - 6.0, LEG_W + 6.0, 8.0), STONE_L)

	# --- lengkung: isi + tepi terang + garis radial antar batu
	var rr := HALF_W - LEG_W * 0.5
	draw_arc(Vector2(0, OPEN_TOP), rr, PI, TAU, 28, STONE, LEG_W)
	draw_arc(Vector2(0, OPEN_TOP), rr - LEG_W * 0.5 + 2.0, PI, TAU, 28, STONE_L, 3.0)
	draw_arc(Vector2(0, OPEN_TOP), rr + LEG_W * 0.5 - 2.0, PI, TAU, 28, STONE_D, 2.0)
	for i in range(1, 6):
		var a: float = PI + i * PI / 6.0
		var p0 := Vector2(0, OPEN_TOP) + Vector2(cos(a), sin(a)) * (rr - LEG_W * 0.5)
		var p1 := Vector2(0, OPEN_TOP) + Vector2(cos(a), sin(a)) * (rr + LEG_W * 0.5)
		draw_line(p0, p1, MORTAR, 2.0)


func _draw_keystone() -> void:
	draw_rect(Rect2(-13.0, TOP - 6.0, 26.0, 12.0), STONE_L)
	draw_rect(Rect2(-13.0, TOP + 2.0, 26.0, 4.0), STONE_D)
	# ukiran kecil
	draw_rect(Rect2(-4.0, TOP - 2.0, 8.0, 6.0), STONE)


func _draw_lock_bar() -> void:
	var bar_y := OPEN_TOP * 0.50
	# palang kayu (satu palang tebal, jelas)
	draw_rect(Rect2(-OPEN_W - 5.0, bar_y - 7.0, (OPEN_W + 5.0) * 2.0, 14.0), EDGE)
	draw_rect(Rect2(-OPEN_W - 3.0, bar_y - 5.0, (OPEN_W + 3.0) * 2.0, 10.0), Color("8a6238"))
	draw_rect(Rect2(-OPEN_W - 3.0, bar_y - 5.0, (OPEN_W + 3.0) * 2.0, 3.0), Color("a87c4c"))
	draw_rect(Rect2(-OPEN_W - 3.0, bar_y + 3.0, (OPEN_W + 3.0) * 2.0, 2.0), Color("6a4826"))
	# paku di ujung palang
	for sx in [-1.0, 1.0]:
		draw_circle(Vector2(sx * (OPEN_W - 1.0), bar_y), 2.2, Color("4a4a4e"))
	# gembok besar di tengah palang
	var ly := bar_y - 4.0
	draw_arc(Vector2(0, ly - 11.0), 9.0, PI, TAU, 14, EDGE, 6.0)
	draw_arc(Vector2(0, ly - 11.0), 9.0, PI, TAU, 14, Color("d6d9dd"), 3.4)
	draw_rect(Rect2(-13.0, ly - 3.0, 26.0, 21.0), EDGE)
	draw_rect(Rect2(-11.0, ly - 1.0, 22.0, 17.0), Color("efd071"))
	draw_rect(Rect2(-11.0, ly - 1.0, 22.0, 4.0), Color("c9a94f"))
	draw_rect(Rect2(-11.0, ly + 14.0, 22.0, 2.0), Color("b1913f"))
	# lubang kunci
	draw_circle(Vector2(0, ly + 6.0), 3.0, Color("3d3222"))
	draw_rect(Rect2(-1.4, ly + 7.0, 2.8, 5.0), Color("3d3222"))


func _draw_sparkles(base: Color, pulse: float) -> void:
	for i in range(7):
		var ph := fmod(_t * 0.55 + i * 0.17, 1.0)
		var px := sin(_t * 1.7 + i * 2.1) * (OPEN_W * 0.8)
		var py := lerpf(-6.0, OPEN_TOP + 8.0, ph)
		var a := (1.0 - ph) * 0.75
		draw_circle(Vector2(px, py), 3.4, Color(base.r, base.g, base.b, a * 0.35))
		draw_circle(Vector2(px, py), 1.7, Color(1, 1, 1, a))


func _draw_near_highlight(base: Color, pulse: float) -> void:
	# tepi menyala saat pemain mendekat
	var a := 0.25 + 0.35 * pulse
	var rim := base if not locked else Color("e8c86a")
	draw_arc(Vector2(0, OPEN_TOP), HALF_W - LEG_W * 0.5, PI, TAU, 28,
		Color(rim.r, rim.g, rim.b, a), 3.0)
	for sx in [-1.0, 1.0]:
		var x0: float = LEG_X0 if sx < 0.0 else LEG_X1
		draw_line(Vector2(x0 + 2.0, OPEN_TOP), Vector2(x0 + 2.0, -14.0),
			Color(rim.r, rim.g, rim.b, a), 2.0)
		draw_line(Vector2(x0 + LEG_W - 2.0, OPEN_TOP), Vector2(x0 + LEG_W - 2.0, -14.0),
			Color(rim.r, rim.g, rim.b, a), 2.0)
