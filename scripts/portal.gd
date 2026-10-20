extends Node2D
## Gerbang keluar peta. Berdenyut bila terbuka, redup bila terkunci.

var color := Color("3ee0a4")
var locked := false
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var base := color if not locked else Color("5a6b82")
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	# cahaya luar
	for i in range(4, 0, -1):
		var r := 9.0 + i * 3.0
		var a := (0.05 + 0.04 * pulse) * (5 - i) / 4.0
		draw_circle(Vector2(0, -8), r, Color(base.r, base.g, base.b, a))
	# gerbang
	var w := 9.0 + pulse * 1.2
	var h := 15.0 + pulse * 1.5
	draw_set_transform(Vector2(0, -10), 0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w, h), Vector2(w, h), Vector2(w * 0.8, -h), Vector2(-w * 0.8, -h)
	]), Color(base.r, base.g, base.b, 0.22))
	draw_polyline(PackedVector2Array([
		Vector2(-w, h), Vector2(w, h), Vector2(w * 0.8, -h), Vector2(-w * 0.8, -h), Vector2(-w, h)
	]), Color(base.r, base.g, base.b, 0.9), 1.5)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# alas
	draw_circle(Vector2(0, 2), 7.0, Color(0, 0, 0, 0.25))
