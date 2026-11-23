extends Control
## Jurnal misi: satu layar berisi seluruh tantangan per wilayah, status selesai,
## dan siapa/benda apa pemicunya. Tujuannya mengubah pesan sekilas
## "Quest selesai 3/10" menjadi catatan yang bisa dibaca ulang kapan saja.
##
## Data diambil dari `Content` (daftar tantangan & pemicu) dan `Game` (progres,
## badge, nyawa). Layar ini tidak mengubah progres apa pun kecuali lewat tombol
## "Tandai", yang hanya meminta main menaruh penanda di peta.

signal closed
signal mark_requested(kind: String, id: String, label: String)
signal open_maps

const LEFT_W := 330

var _sel := "kota"
var _left: VBoxContainer
var _right: VBoxContainer
var _total: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var bg := ColorRect.new()
	bg.color = Color("081310")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var leaves := TextureRect.new()
	if ResourceLoader.exists("res://assets/ui/bg_leaves.png"):
		leaves.texture = load("res://assets/ui/bg_leaves.png")
	leaves.stretch_mode = TextureRect.STRETCH_TILE
	leaves.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leaves.modulate = Color(1, 1, 1, 0.5)
	leaves.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leaves)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := UiKit.vbox(12)
	margin.add_child(root)

	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UiKit.ribbon_style())
	root.add_child(band)
	var head := UiKit.hbox(16)
	band.add_child(head)
	var hcol := UiKit.vbox(2)
	head.add_child(hcol)
	hcol.add_child(UiKit.kicker("JURNAL MISI", UiKit.GOLD, 10))
	hcol.add_child(UiKit.title("CATATAN PERJALANAN", 20, UiKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_total = UiKit.label("", 15, UiKit.MUTED)
	head.add_child(_total)
	var btn_map := UiKit.button("Peta  [M]", 14, UiKit.BLUE)
	btn_map.pressed.connect(func():
		visible = false
		open_maps.emit())
	head.add_child(btn_map)
	var back := UiKit.button("Tutup  [Esc]", 14, UiKit.MUTED)
	back.pressed.connect(_on_close)
	head.add_child(back)

	var body := UiKit.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(LEFT_W, 0)
	left_panel.add_theme_stylebox_override("panel", UiKit.parchment_style(18, 14))
	body.add_child(left_panel)
	var left_scroll := ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(left_scroll)
	_left = UiKit.vbox(6)
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(_left)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", UiKit.frame_style(22, 18))
	body.add_child(right_panel)
	var right_scroll := ScrollContainer.new()
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_panel.add_child(right_scroll)
	_right = UiKit.vbox(6)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_right)

	root.add_child(UiKit.label(
		"Tekan J kapan saja untuk membuka jurnal. Tombol Tandai menaruh penanda di peta menuju pemicu misi.",
		12, UiKit.MUTED))

func open(map_id: String) -> void:
	if map_id != "" and not Content.map_by_id(map_id).is_empty():
		_sel = map_id
	visible = true
	refresh()

## Esc menutup jurnal; ditangani di sini karena pohon scene sedang dijeda.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()

func _on_close() -> void:
	visible = false
	closed.emit()

func refresh() -> void:
	if _left == null:
		return
	_total.text = "%d/%d tantangan  ·  %d/%d badge" % [
		Game.total_done(), Content.total_challenges(), Game.badges.size(), Content.badge_total()]
	_fill_left()
	_fill_right()

func _fill_left() -> void:
	for c in _left.get_children():
		c.queue_free()
	for i in range(Content.MAPS.size()):
		var m: Dictionary = Content.MAPS[i]
		var mid := str(m["id"])
		var unlocked := Game.map_unlocked(mid)
		var dipilih := mid == _sel
		var row := PanelContainer.new()
		var bg := Color("efe3c2") if dipilih else Color("e2d5b3")
		var border := Color("7c5a2e") if dipilih else Color("b8a887")
		row.add_theme_stylebox_override("panel", UiKit.panel_style(bg, border, 2, 2, false))
		_left.add_child(row)

		var h := UiKit.hbox(8)
		row.add_child(h)
		var num := UiKit.title("%02d" % (i + 1), 11, Color("7c5a2e"))
		h.add_child(num)
		var col := UiKit.vbox(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		var ink := Color("2f2415") if unlocked else Color("6b5c45")
		col.add_child(UiKit.label(str(m["name"]), 14, ink, LEFT_W - 130))
		var sub := "%d/%d" % [Game.map_done(mid), Game.map_total(mid)]
		if not unlocked:
			sub += "  ·  terkunci"
		col.add_child(UiKit.label(sub, 11, Color("6b5c45")))
		var btn := UiKit.button("Lihat", 12, UiKit.ACCENT)
		btn.pressed.connect(func():
			_sel = mid
			refresh())
		h.add_child(btn)

func _fill_right() -> void:
	for c in _right.get_children():
		c.queue_free()
	var m := Content.map_by_id(_sel)
	if m.is_empty():
		return
	var unlocked := Game.map_unlocked(_sel)
	var cleared := Game.is_map_cleared(_sel)

	var judul := UiKit.title(str(m.get("name", "")).to_upper(), 15, UiKit.GOLD)
	# Font pixel menggambar lebih rendah dari tinggi baris yang dilaporkan, jadi
	# judul diberi ruang ekstra agar tidak terpotong baris berikutnya.
	judul.custom_minimum_size = Vector2(0, 26)
	_right.add_child(judul)
	var sub := "%s  ·  %d/%d tantangan  ·  nyawa %d/%d" % [
		str(m.get("material", "")), Game.map_done(_sel), Game.map_total(_sel),
		Game.lives_left(_sel), Content.LIVES_PER_MAP]
	_right.add_child(UiKit.label(sub, 12, UiKit.MUTED))
	if cleared:
		_right.add_child(UiKit.label("Wilayah ini sudah selesai — badge %s sudah dikantongi." %
			str(m.get("badge_name", "")), 12, UiKit.ACCENT, 700))
	elif not unlocked:
		_right.add_child(UiKit.label("Belum terbuka: %s." % Game.unlock_hint(_sel), 12, UiKit.DANGER, 700))
	_right.add_child(UiKit.rule())

	var challenges: Array = m.get("challenges", [])
	for i in range(challenges.size()):
		_right.add_child(_row(challenges[i], i + 1))

## Satu baris tantangan: status, judul, pemicu, dan tombol Tandai.
func _row(ch: Dictionary, no: int) -> Control:
	var cid := str(ch.get("id", ""))
	var selesai := Game.done.has(cid)
	var trig := Content.trigger_of(_sel, cid)

	var box := PanelContainer.new()
	var bg := Color(1, 1, 1, 0.04)
	if selesai:
		bg = Color(0.55, 0.78, 0.36, 0.10)
	box.add_theme_stylebox_override("panel", UiKit.panel_style(bg, Color(1, 1, 1, 0.06), 2, 2, false))
	var h := UiKit.hbox(10)
	box.add_child(h)

	var tanda := UiKit.title("OK" if selesai else "%02d" % no, 11,
		UiKit.ACCENT if selesai else UiKit.MUTED)
	tanda.custom_minimum_size = Vector2(34, 0)
	h.add_child(tanda)

	var col := UiKit.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var judul := str(ch.get("title", cid))
	col.add_child(UiKit.label(judul, 14, UiKit.MUTED if selesai else UiKit.TEXT, 470))
	var pemicu := "Pemicu belum tercatat"
	if not trig.is_empty():
		var jenis := "benda" if str(trig["kind"]) == "benda" else "NPC"
		pemicu = "Pemicu: %s (%s)" % [str(trig["label"]), jenis]
		if selesai:
			pemicu = "Selesai lewat %s (%s)" % [str(trig["label"]), jenis]
	col.add_child(UiKit.label(pemicu, 11, UiKit.MUTED if selesai else UiKit.GOLD, 470))

	if not selesai and not trig.is_empty():
		var btn := UiKit.button("Tandai", 12, UiKit.BLUE)
		btn.pressed.connect(func():
			visible = false
			mark_requested.emit(str(trig["kind"]), str(trig["id"]), str(trig["label"])))
		h.add_child(btn)
	elif not selesai:
		h.add_child(UiKit.label("—", 12, UiKit.MUTED))
	return box
