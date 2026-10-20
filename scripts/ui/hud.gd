extends Control
## HUD: level, XP, badge, nama wilayah, dan petunjuk interaksi.

signal open_map
signal open_menu

var _lv: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _map_title: Label
var _map_sub: Label
var _map_id := ""
var _progress: Label
var _prompt: Label
var _badges: HBoxContainer
var _coins: Label

const BADGE_ORDER := ["nature", "core", "cipher", "aqua", "guardian"]
const BADGE_ICON := {
	"nature": "res://assets/ui/badge_nature.png",
	"core": "res://assets/ui/badge_core.png",
	"cipher": "res://assets/ui/badge_cipher.png",
	"aqua": "res://assets/ui/badge_aqua.png",
	"guardian": "res://assets/ui/badge_guardian.png",
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
	_lv = UiKit.title("LV 1", 15, UiKit.ACCENT)
	row.add_child(_lv)
	_xp_text = UiKit.label("0 / 60 XP", 13, UiKit.MUTED)
	_xp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_xp_text)

	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size = Vector2(218, 10)
	_xp_bar.max_value = 100
	_xp_bar.value = 0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0a111c")
	bg.set_corner_radius_all(5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = UiKit.ACCENT
	fg.set_corner_radius_all(5)
	_xp_bar.add_theme_stylebox_override("background", bg)
	_xp_bar.add_theme_stylebox_override("fill", fg)
	lv.add_child(_xp_bar)

	_coins = UiKit.label("◆  0 Keping Data", 13, UiKit.GOLD)
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

	# ---- tombol kanan bawah
	var btns := UiKit.hbox(8)
	btns.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	btns.offset_left = -252
	btns.offset_top = -68
	btns.offset_right = -16
	btns.offset_bottom = -14
	add_child(btns)
	var b1 := UiKit.button("Peta  [M]", 13)
	b1.pressed.connect(func(): open_map.emit())
	btns.add_child(b1)
	var b2 := UiKit.button("Menu  [Esc]", 13, UiKit.MUTED)
	b2.pressed.connect(func(): open_menu.emit())
	btns.add_child(b2)

	Game.xp_changed.connect(_on_xp)
	Game.challenge_completed.connect(func(_id: String): refresh())
	Game.badge_earned.connect(func(_id, _n): refresh())
	Game.prompt_changed.connect(_on_prompt)
	Game.coins_changed.connect(func(_c: int): refresh())
	refresh()

func _on_prompt(text: String) -> void:
	_prompt.text = text

func _on_xp(_xp: int, _lv: int) -> void:
	refresh()

func set_map(m: Dictionary) -> void:
	_map_id = str(m["id"])
	_map_title.text = str(m.get("name", "")).to_upper()
	_progress = null
	refresh()

func refresh() -> void:
	if _map_id != "":
		var mm := Content.map_by_id(_map_id)
		_map_sub.text = "%s  ·  %d/%d tantangan" % [str(mm.get("material", "")), Game.map_done(_map_id), Game.map_total(_map_id)]
	var lv := Game.level()
	_lv.text = "LV %d" % lv
	_coins.text = "◆  %d Keping Data" % Game.coins
	var lo: int = Content.LEVELS[lv - 1]
	var hi: int = Content.LEVELS[mini(lv, Content.LEVELS.size() - 1)]
	if lv >= Content.LEVELS.size():
		_xp_text.text = "%d XP" % Game.xp
		_xp_bar.value = 100
	else:
		_xp_text.text = "%d / %d XP" % [Game.xp, hi]
		var span: float = max(1.0, float(hi - lo))
		_xp_bar.value = clamp((Game.xp - lo) / span * 100.0, 0.0, 100.0)

	for i in range(_badges.get_child_count()):
		var id: String = BADGE_ORDER[i]
		var t: TextureRect = _badges.get_child(i)
		t.modulate = Color(1, 1, 1, 1) if Game.has_badge(id) else Color(1, 1, 1, 0.16)
