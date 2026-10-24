extends Control
## HUD: badge, uang, nama wilayah, dan petunjuk interaksi.
## Tidak ada level/XP: satu-satunya penanda progres adalah badge (Bab II 2.5).

signal open_map
signal open_menu

var _lv: Label
var _badge_text: Label
var _map_title: Label
var _map_sub: Label
var _map_id := ""
var _progress: Label
var _prompt: Label
var _badges: HBoxContainer
var _coins: Label
var _obj_marker: Control
var _obj_arrow: Control
var _obj_label: Label

## Panah penunjuk arah ke tujuan berikutnya (objek/NPC yang belum selesai).
class ObjArrow extends Control:
	var ang := 0.0

	func _draw() -> void:
		var c := size * 0.5
		draw_set_transform(c, ang, Vector2.ONE)
		var pts := PackedVector2Array([
			Vector2(17, 0), Vector2(-9, -11), Vector2(-3, 0), Vector2(-9, 11)])
		draw_colored_polygon(pts, Color(1.0, 0.84, 0.36, 0.95))
		draw_polyline(PackedVector2Array([
			Vector2(17, 0), Vector2(-9, -11), Vector2(-3, 0), Vector2(-9, 11), Vector2(17, 0)]),
			Color(0.1, 0.12, 0.16, 0.9), 2.0)

const BADGE_ORDER := ["nature", "core", "cipher", "aqua"]
const BADGE_ICON := {
	"nature": "res://assets/ui/badge_nature.png",
	"core": "res://assets/ui/badge_core.png",
	"cipher": "res://assets/ui/badge_cipher.png",
	"aqua": "res://assets/ui/badge_aqua.png",
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ---- panel kiri atas
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.055, 0.08, 0.125, 0.92), UiKit.BORDER, 12, 1))
	left.position = Vector2(18, 14)
	left.custom_minimum_size = Vector2(250, 0)
	add_child(left)
	var lv := UiKit.vbox(4)
	left.add_child(lv)
	var row := UiKit.hbox(10)
	lv.add_child(row)
	_lv = UiKit.title("BADGE", 14, UiKit.ACCENT)
	row.add_child(_lv)
	_badge_text = UiKit.label("0 / %d" % Content.badge_total(), 14, UiKit.GOLD)
	_badge_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_badge_text)

	_coins = UiKit.label("◆  Uang 0", 13, UiKit.GOLD)
	lv.add_child(_coins)

	# ---- judul peta (tengah atas)
	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 12
	center.alignment = BoxContainer.ALIGNMENT_BEGIN
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_map_title = UiKit.title("KOTA UNGGUL", 13, UiKit.TEXT)
	_map_title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.95))
	_map_title.add_theme_constant_override("outline_size", 5)
	_map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_map_title)
	_map_sub = UiKit.label("", 13, Color(0.78, 0.85, 0.93, 0.9))
	_map_sub.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.9))
	_map_sub.add_theme_constant_override("outline_size", 5)
	_map_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_map_sub)

	# ---- badge kanan atas
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.055, 0.08, 0.125, 0.92), UiKit.BORDER, 12, 1))
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -250
	right.offset_right = -18
	right.offset_top = 14
	add_child(right)
	_badges = UiKit.hbox(6)
	right.add_child(_badges)
	for b in BADGE_ORDER:
		var t := TextureRect.new()
		t.texture = load(BADGE_ICON[b])
		t.custom_minimum_size = Vector2(30, 30)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.modulate = Color(1, 1, 1, 0.16)
		t.tooltip_text = b
		_badges.add_child(t)

	# ---- petunjuk interaksi
	_prompt = UiKit.label("", 16, UiKit.GOLD)
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.95))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -54
	_prompt.offset_bottom = -24
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt)

	# ---- panah penunjuk tujuan
	_obj_marker = Control.new()
	_obj_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_obj_marker.visible = false
	add_child(_obj_marker)
	_obj_arrow = ObjArrow.new()
	_obj_arrow.size = Vector2(40, 40)
	_obj_arrow.position = Vector2(-20, -20)
	_obj_arrow.pivot_offset = Vector2(20, 20)
	_obj_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_obj_marker.add_child(_obj_arrow)
	_obj_label = UiKit.label("", 14, UiKit.GOLD)
	_obj_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.95))
	_obj_label.add_theme_constant_override("outline_size", 5)
	_obj_marker.add_child(_obj_label)

	# ---- tombol kanan bawah
	var btns := UiKit.hbox(8)
	btns.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	btns.offset_left = -400
	btns.offset_top = -68
	btns.offset_right = -16
	btns.offset_bottom = -14
	add_child(btns)
	var b3 := UiKit.button("Suara: Hidup", 13, UiKit.MUTED)
	b3.pressed.connect(func():
		var on := Game.toggle_audio()
		if on:
			Game.sfx("sfx_click", -11.0)
		b3.text = "Suara: Hidup" if on else "Suara: Mati")
	btns.add_child(b3)
	var b1 := UiKit.button("Peta  [M]", 13)
	b1.pressed.connect(func(): open_map.emit())
	btns.add_child(b1)
	var b2 := UiKit.button("Menu  [Esc]", 13, UiKit.MUTED)
	b2.pressed.connect(func(): open_menu.emit())
	btns.add_child(b2)

	Game.progress_changed.connect(refresh)
	Game.challenge_completed.connect(func(_id: String): refresh())
	Game.badge_earned.connect(func(_id, _n): refresh())
	Game.prompt_changed.connect(_on_prompt)
	Game.coins_changed.connect(func(_c: int): refresh())
	refresh()

## Menampilkan panah ke tujuan berikutnya; sembunyi bila sudah dekat.
func set_objective(target: Vector2, player: Vector2, txt: String) -> void:
	if _obj_marker == null:
		return
	var d := target - player
	if d.length() < 150.0:
		_obj_marker.visible = false
		return
	_obj_marker.visible = true
	var vp := get_viewport_rect().size
	var center := vp * 0.5
	var dir := d.normalized()
	var p := center + Vector2(dir.x * (center.x - 150.0), dir.y * (center.y - 120.0))
	p.x = clamp(p.x, 120.0, vp.x - 120.0)
	p.y = clamp(p.y, 150.0, vp.y - 120.0)
	_obj_marker.position = p
	_obj_arrow.set("ang", dir.angle())
	_obj_arrow.queue_redraw()
	_obj_label.text = "%s · %d m" % [txt, int(d.length() / 48.0)]
	_obj_label.reset_size()
	_obj_label.position = Vector2(-_obj_label.size.x * 0.5, 24.0)

func _on_prompt(text: String) -> void:
	_prompt.text = text

func set_map(m: Dictionary) -> void:
	_map_id = str(m["id"])
	_map_title.text = str(m.get("name", "")).to_upper()
	_progress = null
	refresh()

func refresh() -> void:
	if _map_id != "":
		var mm := Content.map_by_id(_map_id)
		_map_sub.text = "%s  ·  %d/%d tantangan" % [str(mm.get("material", "")), Game.map_done(_map_id), Game.map_total(_map_id)]
	_badge_text.text = "%d / %d" % [Game.badges.size(), BADGE_ORDER.size()]
	_coins.text = "◆  Uang %d" % Game.coins

	for i in range(_badges.get_child_count()):
		var id: String = BADGE_ORDER[i]
		var t: TextureRect = _badges.get_child(i)
		t.modulate = Color(1, 1, 1, 1) if Game.has_badge(id) else Color(1, 1, 1, 0.16)
