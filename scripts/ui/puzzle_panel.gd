extends Control
## Panel tantangan. Tipe: mcq, build (SQL), order, fill, cipher, craft, wire.

signal solved(challenge_id: String)
signal closed

const WIDTH := 960

var _c: Dictionary = {}
var _index := 0
var _total := 0
var _done := false
var _failed := false
var _lives_suffix := ""
var _attempts := 0

var _root: VBoxContainer
var _body: VBoxContainer
var _body_scroll: ScrollContainer
var _feedback: Label
var _action_row: HBoxContainer
var _lensa_btn: Button
var _boss_row: HBoxContainer
var _boss_name: Label
var _boss_hp: Label
var _craft_slots: Array = []
var _craft_btns: Array = []
var _craft_pool_btns: Array = []
var _progress: Label
var _title: Label
var _prompt: Label
var _map_chip: PanelContainer
var _parts_select: Array = []
var _order_answer: Array = []
var _order_pool: Array = []
var _cipher_shift := 0
var _cipher_label: Label
var _pool_box: VBoxContainer
var _answer_box: VBoxContainer
var _lesson_done := false
var _fill_edit: LineEdit
var _hearts: Array = []
# --- puzzle kabel (wire): merakit perangkat IoT dengan menyambung pin
var _wire_pins: Dictionary = {}    # id -> Button pin
var _wire_links: Array = []        # pasangan id ternormalisasi [a, b]
var _wire_lines: Array = []        # Line2D emas, sejajar dengan _wire_links
var _wire_outlines: Array = []     # Line2D bayangan di bawah tiap kabel
var _wire_selected := ""
var _wire_layer: Control
var _wire_count: Label
var _wire_lamp: Label
var _wire_nyala := false
var _dim: ColorRect
var _panel: PanelContainer
var _band: PanelContainer
var _paper: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	_dim = ColorRect.new()
	_dim.color = UiKit.theme_dim()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	# Panel mengisi tinggi layar dengan margin tetap, supaya isi yang panjang
	# bisa di-scroll dan tombol aksi tidak pernah keluar layar.
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 150)
	frame.add_theme_constant_override("margin_right", 150)
	frame.add_theme_constant_override("margin_top", 16)
	frame.add_theme_constant_override("margin_bottom", 16)
	add_child(frame)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.screen_style())
	_panel.custom_minimum_size = Vector2(WIDTH, 0)
	frame.add_child(_panel)

	_root = UiKit.vbox(12)
	_panel.add_child(_root)

	# ---------------------------------------------------------- kepala panel
	_band = PanelContainer.new()
	_band.add_theme_stylebox_override("panel", UiKit.ribbon_style())
	_root.add_child(_band)
	var head := UiKit.hbox(10)
	_band.add_child(head)

	_map_chip = UiKit.chip("KOTA UNGGUL", UiKit.GOLD, Color(0.91, 0.72, 0.35, 0.10))
	head.add_child(_map_chip)
	_progress = UiKit.label("TANTANGAN 1/3", 13, UiKit.MUTED)
	_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_progress)
	head.add_child(UiKit.expander())

	_boss_row = UiKit.hbox(8)
	_boss_row.visible = false
	head.add_child(_boss_row)
	_boss_name = UiKit.kicker("THE SOURCE", UiKit.DANGER, 11)
	_boss_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_row.add_child(_boss_name)
	_boss_hp = UiKit.label("HP 3 / 3", 14, UiKit.DANGER)
	_boss_row.add_child(_boss_hp)

	# Nyawa wilayah tampil sebagai hati kayu di kepala panel.
	var hearts_row := UiKit.hbox(2)
	hearts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(hearts_row)
	for i in range(Content.LIVES_PER_MAP):
		var h := TextureRect.new()
		h.custom_minimum_size = Vector2(26, 22)
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_row.add_child(h)
		_hearts.append(h)

	_lensa_btn = UiKit.button("Lensa (0)", 14, UiKit.GOLD)
	_lensa_btn.tooltip_text = "Membuka petunjuk. Dibeli dari pedagang di Kota Unggul."
	_lensa_btn.custom_minimum_size = Vector2(120, 40)
	_lensa_btn.pressed.connect(_on_lensa)
	head.add_child(_lensa_btn)

	var close_btn := UiKit.button("✕", 16, UiKit.MUTED)
	close_btn.custom_minimum_size = Vector2(44, 40)
	close_btn.tooltip_text = "Tutup (Esc)"
	close_btn.pressed.connect(_on_close)
	head.add_child(close_btn)

	_root.add_child(UiKit.rule())

	# ---------------------------------------------------------- judul & soal
	_title = UiKit.title("", 16, UiKit.GOLD)
	_root.add_child(_title)

	_prompt = UiKit.body("", 20, UiKit.theme_ink(), WIDTH - 210)
	_paper = UiKit.paper_card(_prompt)
	_root.add_child(_paper)

	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(_body_scroll)

	_body = UiKit.vbox(6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.add_child(_body)

	_feedback = UiKit.body("", 16, UiKit.ACCENT, WIDTH - 96)
	_feedback.visible = false
	_root.add_child(_feedback)

	_root.add_child(UiKit.rule())

	_action_row = UiKit.hbox(12)
	_action_row.alignment = BoxContainer.ALIGNMENT_END
	_root.add_child(_action_row)

func open(challenge: Dictionary, index: int, total: int) -> void:
	# Tema mengikuti wilayah yang sedang dimainkan: pabrik tampil seperti besi,
	# candi seperti batu, danau seperti kayu apung, The Source seperti obsidian.
	UiKit.set_theme(Game.current_map)
	_apply_theme()
	_c = challenge
	_index = index
	_total = total
	_done = false
	_failed = false
	_attempts = 0
	_parts_select.clear()
	_order_answer.clear()
	_order_pool.clear()
	_cipher_shift = 0
	# Materi pembelajaran hanya diberikan lewat dialog NPC pengajar, jadi panel
	# tantangan langsung menampilkan soal tanpa layar pelajaran.
	_lesson_done = true
	_feedback.visible = false
	_feedback.text = ""
	for ch in _action_row.get_children():
		ch.queue_free()
	for ch in _body.get_children():
		ch.queue_free()

	_refresh_lensa()
	_refresh_hearts()
	if _c.has("boss_hp"):
		_boss_row.visible = true
		_boss_name.text = str(_c.get("boss_name", "BOSS")).to_upper()
		_boss_hp.text = "HP %d / %d" % [int(_c["boss_hp"]), int(_c.get("boss_max", 3))]
	else:
		_boss_row.visible = false
	if bool(_c.get("final", false)):
		_progress.text = "TANTANGAN AKHIR · %d/%d" % [index + 1, total]
	else:
		_progress.text = "TANTANGAN %d DARI %d" % [index + 1, total]
	var mn := str(Content.map_by_id(Game.current_map).get("name", "")).to_upper()
	if mn != "" and _map_chip.get_child_count() > 0:
		(_map_chip.get_child(0) as Label).text = mn
	_title.text = str(_c.get("title", "Tantangan")).to_upper()
	_prompt.text = str(_c.get("prompt", ""))
	_paper.visible = str(_c.get("type", "")) != "wire"

	if _lesson_done:
		_build_active_challenge()
	else:
		_build_lesson()
	visible = true

## Terapkan bahan & warna wilayah ke panel, pita kepala, kertas soal, dan judul.
func _apply_theme() -> void:
	if _dim:
		_dim.color = UiKit.theme_dim()
	if _panel:
		_panel.add_theme_stylebox_override("panel", UiKit.screen_style())
	if _band:
		_band.add_theme_stylebox_override("panel", UiKit.ribbon_style())
	if _paper:
		_paper.add_theme_stylebox_override("panel", UiKit.parchment_style(22, 16))
	if _prompt:
		_prompt.add_theme_color_override("font_color", UiKit.theme_ink())
	if _title:
		_title.add_theme_color_override("font_color", UiKit.theme_accent())
	if _feedback:
		_feedback.add_theme_color_override("font_color", UiKit.theme_accent())
	if _map_chip and _map_chip.get_child_count() > 0:
		var chip_lbl := _map_chip.get_child(0) as Label
		if chip_lbl:
			chip_lbl.add_theme_color_override("font_color", UiKit.theme_accent())

func _build_active_challenge() -> void:
	if _c.has("bank_materi"):
		var q := Game.bank_question(str(_c.get("id", "")), str(_c["bank_materi"]))
		if q.is_empty():
			_show_feedback("Bank soal belum tersedia untuk materi ini.", UiKit.DANGER)
			return
		# id tantangan tetap stabil agar progres save tidak berubah.
		_c["prompt"] = str(q.get("prompt", ""))
		_c["options"] = q.get("options", [])
		_c["answer"] = int(q.get("answer", 0))
		_c["explain"] = str(q.get("explain", ""))
		_c["bank_id"] = str(q.get("id", ""))
		_title.text = str(_c.get("bank_materi", "Uji Materi")).to_upper()
		_prompt.text = str(_c.get("prompt", ""))
	if _c.has("puzzle_bank"):
		var pz := Game.bank_puzzle(str(_c.get("id", "")), str(_c["bank_materi"]))
		if pz.is_empty():
			_show_feedback("Bank puzzle belum tersedia untuk materi ini.", UiKit.DANGER)
			return
		_c["puzzle_id"] = str(pz.get("id", ""))
		_c["prompt"] = str(pz.get("prompt", ""))
		_c["explain"] = str(pz.get("explain", ""))
		_c["fatal"] = true
		_title.text = "PUZZLE " + str(_c.get("bank_materi", "")).to_upper()
		_prompt.text = str(_c.get("prompt", ""))
		if str(pz.get("type", "order")) == "fill":
			_c["type"] = "fill"
			_c["code"] = str(pz.get("code", ""))
			_c["accept"] = pz.get("accept", [])
		else:
			_c["type"] = "order"
			_c["items"] = pz.get("steps", [])
	if _c.has("table"):
		_body.add_child(_make_table(_c["table"]))

	match str(_c.get("type", "mcq")):
		"mcq":
			_build_mcq()
		"build":
			_build_sql()
		"order":
			_build_order()
		"craft":
			_build_craft()
		"wire":
			_build_wire()
		"cipher":
			_build_cipher()
		"fill":
			_build_fill()

func _build_lesson() -> void:
	var lesson: Dictionary = _c.get("lesson", {})
	var head := UiKit.kicker("SIMULASI BELAJAR", UiKit.ACCENT, 11)
	_body.add_child(head)
	_body.add_child(UiKit.body(str(lesson.get("text", "Coba konsep ini sebelum mengerjakan misi.")), 16, UiKit.TEXT, WIDTH - 70))
	var question := UiKit.label(str(lesson.get("prompt", "Apa langkah yang tepat?")), 16, UiKit.GOLD, WIDTH - 70)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(question)
	var options: Array = lesson.get("options", [])
	for i in range(options.size()):
		# Tombol pilihan dibuat ringkas (margin tekstur 8 px) supaya tiga opsi
		# simulasi + soal + bagian rakit muat tanpa perlu menggulir.
		var btn := UiKit.small_button("%s.  %s" % [char(65 + i), str(options[i])], 15)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(WIDTH - 96, 42)
		btn.pressed.connect(_on_lesson_answer.bind(i, btn))
		_body.add_child(btn)

func _on_lesson_answer(index: int, btn: Button) -> void:
	if _lesson_done:
		return
	var lesson: Dictionary = _c.get("lesson", {})
	if index != int(lesson.get("answer", -1)):
		btn.disabled = true
		_attempts += 1
		_register_mistake()
		_show_feedback(str(lesson.get("wrong", "Belum tepat. Coba pahami kembali simulasi.")), UiKit.DANGER)
		return
	_lesson_done = true
	_show_feedback(str(lesson.get("success", "Konsep dipahami. Tantangan utama terbuka.")), UiKit.ACCENT)
	for c in _body.get_children():
		c.queue_free()
	for c in _action_row.get_children():
		c.queue_free()
	await get_tree().process_frame
	_build_active_challenge()


# ------------------------------------------------------------------ rakit perangkat
func _build_craft() -> void:
	var slots: Array = _c.get("slots", [])
	var pool: Array = _c.get("pool", [])
	_craft_slots.clear()
	_craft_btns.clear()
	_craft_pool_btns.clear()
	for i in range(slots.size()):
		_craft_slots.append("")

	var info := UiKit.label("Klik komponen di bawah untuk mengisi slot. Klik slot untuk mengosongkannya kembali.", 14, UiKit.MUTED, WIDTH - 60)
	_body.add_child(info)

	for i in range(slots.size()):
		var b := UiKit.small_button("", 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(WIDTH - 70, 40)
		b.pressed.connect(_on_slot_click.bind(i))
		_body.add_child(b)
		_craft_btns.append(b)
	_refresh_craft()

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	_body.add_child(flow)
	for item in pool:
		var pb := UiKit.button(str(item), 14, UiKit.BLUE)
		pb.pressed.connect(_on_pool_click.bind(str(item), pb))
		flow.add_child(pb)
		_craft_pool_btns.append({"item": str(item), "btn": pb})

	var row := UiKit.hbox(10)
	_body.add_child(row)
	var check := UiKit.primary_button("Periksa Rakit", UiKit.ACCENT, 16)
	check.pressed.connect(_on_craft_check)
	_action_row.add_child(check)

func _refresh_craft() -> void:
	var slots: Array = _c.get("slots", [])
	for i in range(_craft_btns.size()):
		var b: Button = _craft_btns[i]
		var v := str(_craft_slots[i]) if i < _craft_slots.size() else ""
		if v == "":
			b.text = "Slot %d — kosong" % (i + 1)
			b.add_theme_color_override("font_color", UiKit.MUTED)
		else:
			b.text = "Slot %d — %s" % [i + 1, v]
			b.add_theme_color_override("font_color", UiKit.TEXT)
	for entry in _craft_pool_btns:
		var used := _craft_slots.has(str(entry["item"]))
		(entry["btn"] as Button).disabled = used

func _on_pool_click(item: String, _btn: Button) -> void:
	if _done:
		return
	for i in range(_craft_slots.size()):
		if str(_craft_slots[i]) == "":
			_craft_slots[i] = item
			_refresh_craft()
			return
	_show_feedback("Semua slot sudah terisi. Klik salah satu slot untuk mengosongkannya.", UiKit.GOLD)

func _on_slot_click(i: int) -> void:
	if _done:
		return
	_craft_slots[i] = ""
	_refresh_craft()

func _on_craft_check() -> void:
	if _done:
		return
	var slots: Array = _c.get("slots", [])
	if _craft_slots.size() != slots.size():
		return
	for i in range(slots.size()):
		if str(_craft_slots[i]) != str(slots[i]):
			_attempts += 1
			_register_mistake()
			_show_feedback("Belum tepat. Perangkat harus mengikuti aliran data: masukan → pengolahan → pengiriman → perantara.", UiKit.DANGER)
			if _attempts >= 2:
				_show_free_hint()
			return
	_win()

# ------------------------------------------------------ rakit kabel (wire)
## Gambar komponen dibuat dari bentuk sederhana (kotak, garis, lingkaran) supaya
## papan terasa seperti perangkat, bukan formulir teks. Tidak perlu aset baru.
class WireGlyph extends Control:
	var kind := "board"

	func _init(k: String) -> void:
		kind = k
		custom_minimum_size = Vector2(0, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var ink := Color("cfe3c0")
		var c := Vector2(size.x * 0.5, 22)
		match kind:
			"battery":
				draw_rect(Rect2(c + Vector2(-26, -14), Vector2(52, 36)), Color("2c3a24"), true)
				draw_rect(Rect2(c + Vector2(-26, -14), Vector2(52, 36)), ink, false, 2.0)
				draw_rect(Rect2(c + Vector2(-8, -21), Vector2(16, 7)), Color("d8b25a"), true)
				draw_line(c + Vector2(-14, -2), c + Vector2(-2, -2), Color("d8b25a"), 2.0)
				draw_line(c + Vector2(-8, -8), c + Vector2(-8, 4), Color("d8b25a"), 2.0)
				draw_line(c + Vector2(6, -2), c + Vector2(18, -2), ink, 2.0)
			"board":
				draw_rect(Rect2(c + Vector2(-42, -21), Vector2(84, 42)), Color("1d3a24"), true)
				draw_rect(Rect2(c + Vector2(-42, -21), Vector2(84, 42)), Color("7fbf6a"), false, 2.0)
				for i in range(1, 4):
					draw_line(c + Vector2(-42, -21 + i * 10), c + Vector2(42, -21 + i * 10), Color("33553a"), 1.0)
				for i in range(1, 5):
					draw_line(c + Vector2(-42 + i * 17, -21), c + Vector2(-42 + i * 17, 21), Color("33553a"), 1.0)
				draw_circle(c + Vector2(-28, 0), 3.0, Color("d8b25a"))
				draw_circle(c + Vector2(28, 0), 3.0, Color("d8b25a"))
			"chip":
				draw_rect(Rect2(c + Vector2(-22, -15), Vector2(44, 30)), Color("232a30"), true)
				draw_rect(Rect2(c + Vector2(-22, -15), Vector2(44, 30)), ink, false, 2.0)
				for i in range(3):
					var yy := -10 + i * 10
					draw_line(c + Vector2(-31, yy), c + Vector2(-22, yy), ink, 2.0)
					draw_line(c + Vector2(22, yy), c + Vector2(31, yy), ink, 2.0)
				draw_circle(c + Vector2(-12, -7), 3.0, Color("6f8a63"))
			"probe":
				draw_line(c + Vector2(0, -24), c + Vector2(0, 2), ink, 3.0)
				draw_circle(c + Vector2(0, 10), 9.0, Color("2c3a24"))
				draw_arc(c + Vector2(0, 10), 9.0, 0, TAU, 20, Color("7fd8c8"), 2.0)
				draw_polyline(PackedVector2Array([
					c + Vector2(-28, 20), c + Vector2(-14, 16), c + Vector2(0, 20),
					c + Vector2(14, 16), c + Vector2(28, 20)]), Color("5f9fbf"), 2.0)
			"fan":
				draw_arc(c, 19.0, 0, TAU, 28, ink, 2.0)
				for i in range(3):
					var ang := TAU * float(i) / 3.0
					draw_line(c, c + Vector2(cos(ang), sin(ang)) * 15.0, Color("9fc4d8"), 3.0)
				draw_circle(c, 4.0, Color("d8b25a"))
			"led":
				draw_arc(c + Vector2(0, 2), 12.0, PI, TAU, 20, Color("e86a6a"), 2.0)
				draw_line(c + Vector2(-12, 2), c + Vector2(-12, 14), Color("e86a6a"), 2.0)
				draw_line(c + Vector2(12, 2), c + Vector2(12, 14), Color("e86a6a"), 2.0)
				draw_line(c + Vector2(-12, 14), c + Vector2(12, 14), Color("e86a6a"), 2.0)
				draw_line(c + Vector2(16, -10), c + Vector2(22, -16), Color("e8a96a"), 2.0)
				draw_line(c + Vector2(20, -2), c + Vector2(28, -4), Color("e8a96a"), 2.0)
			_:
				draw_circle(c, 10.0, ink)

## Latar papan: titik-titik seperti papan rangkaian (PCB).
class WireBackdrop extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var step := 26.0
		var dot := Color(0.45, 0.62, 0.42, 0.16)
		var y := 6.0
		while y < size.y:
			var x := 6.0
			while x < size.x:
				draw_circle(Vector2(x, y), 1.4, dot)
				x += step
			y += step

const WIRE_CARD := Vector2(160, 86)

## Pemain menyambung pin komponen dengan kabel. Sambungan benar dihitung
## sebagai pasangan tak berarah: daya–papan sama dengan papan–daya.
func _build_wire() -> void:
	_wire_pins.clear()
	_wire_links.clear()
	_wire_lines.clear()
	_wire_outlines.clear()
	_wire_selected = ""
	_wire_nyala = false

	# Papan butuh ruang tinggi: kertas soal besar disembunyikan dan
	# instruksinya dipindah ke baris status yang ramping.
	_paper.visible = false
	var status := UiKit.hbox(16)
	var hint := UiKit.label("Klik pin lalu pin lain untuk memasang kabel. Klik pasangan yang sama untuk mencabutnya.",
		12, UiKit.MUTED, 470)
	status.add_child(hint)
	_wire_count = UiKit.label("Kabel 0/4", 14, UiKit.MUTED)
	status.add_child(_wire_count)
	_wire_lamp = UiKit.label("● Perangkat mati", 14, Color("6b7a6b"))
	status.add_child(_wire_lamp)
	_body.add_child(status)

	var board := Control.new()
	board.custom_minimum_size = Vector2(WIDTH - 70, 196)
	board.clip_contents = false
	_body.add_child(board)

	var bg := WireBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.add_child(bg)

	# Lapisan kabel digambar di bawah kartu komponen.
	_wire_layer = Control.new()
	_wire_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wire_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(_wire_layer)

	for nd in _c.get("nodes", []):
		var node := nd as Dictionary
		var nid := str(node.get("id", ""))
		var pos: Array = node.get("pos", [0, 0])
		var card := PanelContainer.new()
		# Semua kartu tampil sama: komponen pengganggu TIDAK dibedakan warna,
		# supaya pemain memutuskan dari materi, bukan dari petunjuk visual.
		card.add_theme_stylebox_override("panel", UiKit.panel_style(
			Color("17251c"), Color("4f6b48"), 3, 2, false))
		card.position = Vector2(float(pos[0]), float(pos[1]))
		card.custom_minimum_size = WIRE_CARD
		board.add_child(card)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		card.add_child(vb)
		vb.add_child(WireGlyph.new(str(node.get("glyph", "board"))))
		var nm := UiKit.label(str(node.get("name", "")), 11, UiKit.TEXT, 146)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(nm)

		# Pin berada di tepi kartu menghadap papan, jadi kabel keluar dari
		# sisi komponen seperti colokan — bukan dari tengah tulisan.
		var side := str(node.get("pin", "right"))
		var pin := Button.new()
		pin.custom_minimum_size = Vector2(30, 30)
		pin.tooltip_text = "Colokan " + str(node.get("name", ""))
		match side:
			"left":
				pin.position = Vector2(float(pos[0]) - 15, float(pos[1]) + 28)
			"top":
				pin.position = Vector2(float(pos[0]) + 65, float(pos[1]) - 15)
			"bottom":
				pin.position = Vector2(float(pos[0]) + 65, float(pos[1]) + 71)
			_:
				pin.position = Vector2(float(pos[0]) + 145, float(pos[1]) + 28)
		pin.add_theme_stylebox_override("normal",
			UiKit.panel_style(Color("2a2318"), UiKit.GOLD, 15, 3, false))
		pin.add_theme_stylebox_override("hover",
			UiKit.panel_style(Color("5a4a22"), UiKit.GOLD, 15, 4, false))
		pin.pressed.connect(_on_wire_pin.bind(nid))
		board.add_child(pin)
		_wire_pins[nid] = pin

	var undo := UiKit.button("Cabut Kabel Terakhir", 14, UiKit.MUTED)
	undo.pressed.connect(_on_wire_undo)
	_action_row.add_child(undo)
	var check := UiKit.primary_button("Nyalakan Perangkat", UiKit.ACCENT, 16)
	check.pressed.connect(_on_wire_check)
	_action_row.add_child(check)
	_wire_refresh_status()

func _on_wire_pin(nid: String) -> void:
	if _done:
		return
	if _wire_selected == "":
		_wire_selected = nid
		_mark_pin(nid, true)
		Game.sfx("sfx_click", -11.0)
		return
	if _wire_selected == nid:
		_wire_selected = ""
		_mark_pin(nid, false)
		return
	# Pasangan diurutkan supaya daya–papan dan papan–daya dianggap sama.
	var a := _wire_selected
	var b := nid
	if a > b:
		var t := a
		a = b
		b = t
	var pair := [a, b]
	var idx := _wire_links.find(pair)
	if idx >= 0:
		_wire_drop(idx)
	else:
		_wire_links.append(pair)
		_wire_draw(_wire_center(a), _wire_center(b))
		Game.sfx("sfx_click", -9.0)
	_mark_pin(_wire_selected, false)
	_wire_selected = ""
	_wire_refresh_status()

## Gambar satu kabel: garis gelap sebagai bayangan + garis emas di atasnya.
func _wire_draw(a: Vector2, b: Vector2) -> void:
	var pts := _wire_curve(a, b)
	var outline := Line2D.new()
	outline.points = pts
	outline.width = 9.0
	outline.default_color = Color("0c1310")
	_wire_layer.add_child(outline)
	var line := Line2D.new()
	line.points = pts
	line.width = 5.0
	line.default_color = Color("d8b25a")
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_wire_layer.add_child(line)
	_wire_lines.append(line)
	_wire_outlines.append(outline)

func _wire_drop(idx: int) -> void:
	(_wire_lines[idx] as Node).queue_free()
	(_wire_outlines[idx] as Node).queue_free()
	_wire_lines.remove_at(idx)
	_wire_outlines.remove_at(idx)
	_wire_links.remove_at(idx)

## Kabel sedikit melengkung; arah lengkung dipilih supaya tidak menimpa kartu.
func _wire_curve(a: Vector2, b: Vector2) -> PackedVector2Array:
	var mid := (a + b) * 0.5
	var dir := b - a
	var nrm := Vector2(-dir.y, dir.x).normalized()
	var bulge := clampf(dir.length() * 0.16, 12.0, 44.0)
	var ctrl := mid + nrm * bulge
	if _wire_on_card(ctrl):
		ctrl = mid - nrm * bulge
	var pts := PackedVector2Array()
	for i in range(21):
		var t := float(i) / 20.0
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts

func _wire_on_card(p: Vector2) -> bool:
	for nd in _c.get("nodes", []):
		var pos: Array = (nd as Dictionary).get("pos", [0, 0])
		if Rect2(Vector2(float(pos[0]), float(pos[1])), WIRE_CARD).has_point(p):
			return true
	return false

## Pusat pin dalam koordinat lapisan kabel, dihitung saat kabel dibuat.
func _wire_center(nid: String) -> Vector2:
	var pin: Button = _wire_pins[nid]
	return pin.get_global_position() - _wire_layer.get_global_position() + pin.size / 2.0

func _mark_pin(nid: String, on: bool) -> void:
	if _wire_pins.has(nid):
		(_wire_pins[nid] as Button).modulate = Color("ffd76b") if on else Color(1, 1, 1)

func _on_wire_undo() -> void:
	if _done or _wire_links.is_empty():
		return
	_wire_drop(_wire_links.size() - 1)
	_wire_refresh_status()

## Daftar sambungan benar dari data, dinormalisasi seperti _wire_links.
func _wire_required() -> Array:
	var need: Array = []
	for l in _c.get("links", []):
		var a := str((l as Array)[0])
		var b := str((l as Array)[1])
		if a > b:
			var t := a
			a = b
			b = t
		need.append([a, b])
	return need

## Nama tampilan komponen dari id-nya (untuk petunjuk).
func _wire_name(nid: String) -> String:
	for nd in _c.get("nodes", []):
		if str((nd as Dictionary).get("id", "")) == nid:
			return str((nd as Dictionary).get("name", nid))
	return nid

## Penghitung kabel dan lampu status perangkat.
func _wire_refresh_status() -> void:
	if _wire_count == null or _wire_lamp == null:
		return
	_wire_count.text = "Kabel %d/%d" % [_wire_links.size(), _wire_required().size()]
	if _wire_nyala:
		_wire_lamp.text = "● Perangkat menyala"
		_wire_lamp.add_theme_color_override("font_color", Color("8fdc7b"))
	else:
		_wire_lamp.text = "● Perangkat mati"
		_wire_lamp.add_theme_color_override("font_color", Color("6b7a6b"))

func _on_wire_check() -> void:
	if _done:
		return
	var need := _wire_required()
	# Kurang kabel tidak dihukum — pemain mungkin belum selesai merangkai.
	if _wire_links.size() < need.size():
		_show_feedback("Belum semua tersambung (%d/%d kabel). Rangkaian butuh daya, dasar papan, sensor, dan mikrokontroler."
			% [_wire_links.size(), need.size()], UiKit.GOLD)
		return
	var ok := _wire_links.size() == need.size()
	if ok:
		for n in need:
			if not _wire_links.has(n):
				ok = false
				break
	if ok:
		# Kabel menjadi hijau dan lampu menyala saat perangkat benar-benar hidup.
		for line in _wire_lines:
			(line as Line2D).default_color = Color("8fdc7b")
		_wire_nyala = true
		_wire_refresh_status()
		_win()
	else:
		_attempts += 1
		if bool(_c.get("fatal", false)):
			_fatal_fail("Ada kabel yang salah sambung — rangkaian korslet. Puzzle gagal, nyawa wilayah habis.")
			return
		_register_mistake()
		_show_feedback("Ada sambungan yang tidak tepat. Ikuti rantainya: daya → papan → sensor → mikrokontroler.", UiKit.DANGER)

# ------------------------------------------------------------------ tabel
func _make_table(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb := UiKit.panel_style(Color(0.05, 0.07, 0.11, 1.0), UiKit.BORDER, 8, 1)
	# Padding dalam tabel dibuat tipis supaya tabel panjang tidak mendorong
	# isi tantangan keluar dari panel.
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	var grid := GridContainer.new()
	grid.columns = (data["head"] as Array).size()
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 2)
	panel.add_child(grid)
	for h in data["head"]:
		grid.add_child(UiKit.label(str(h), 14, UiKit.ACCENT))
	for row in data["rows"]:
		for cell in row:
			grid.add_child(UiKit.label(str(cell), 14, UiKit.TEXT))
	return panel

# ------------------------------------------------------------------ mcq
func _build_mcq() -> void:
	var opts: Array = _c.get("options", [])
	for i in range(opts.size()):
		var b := UiKit.choice_button("", 17)
		b.text = "   %s      %s" % [char(65 + i), str(opts[i])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(WIDTH - 110, 56)
		b.pressed.connect(_on_mcq.bind(i, b))
		_body.add_child(b)

func _on_mcq(idx: int, btn: Button) -> void:
	if _done:
		return
	if idx == int(_c.get("answer", -1)):
		btn.add_theme_color_override("font_color", Color("1f3d16"))
		btn.add_theme_stylebox_override("normal", UiKit.panel_style(Color("cfe3a8"), UiKit.ACCENT, 3, 3, false))
		_win()
	else:
		btn.disabled = true
		btn.text = "×   " + btn.text.strip_edges()
		btn.add_theme_color_override("font_disabled_color", Color("7d5040"))
		btn.add_theme_stylebox_override("disabled",
			UiKit.panel_style(Color("cdbf9f"), Color("9a6a52"), 3, 2, false))
		_attempts += 1
		_register_mistake()
		_show_feedback("Belum tepat. Periksa lagi hubungan antar konsepnya.", UiKit.DANGER)
		if _attempts >= 2:
			_show_free_hint()

## Petunjuk otomatis setelah dua kali salah: gratis, tidak memakai Lensa.
func _show_free_hint() -> void:
	var hint := _hint_text()
	if not hint.is_empty():
		_show_feedback(hint, UiKit.GOLD)

func _refresh_lensa() -> void:
	if _lensa_btn == null:
		return
	_lensa_btn.text = "Lensa (%d)" % Game.item_count("lensa")
	_lensa_btn.disabled = Game.item_count("lensa") <= 0

## Memakai Lensa Analisis yang dibeli dari pedagang. Barang hanya dipotong
## bila petunjuk untuk soal itu memang tersedia, supaya uang pemain tidak hangus.
func _on_lensa() -> void:
	if _done:
		return
	if Game.item_count("lensa") <= 0:
		_show_feedback("Kamu tidak punya Lensa Analisis. Beli dulu di pedagang Kota Unggul.", UiKit.DANGER)
		_refresh_lensa()
		return
	var hint := _hint_text()
	if hint.is_empty():
		_show_feedback("Belum ada petunjuk untuk soal ini. Lensa tidak terpakai.", UiKit.MUTED)
		return
	if not Game.use_item("lensa"):
		_refresh_lensa()
		return
	_refresh_lensa()
	_show_feedback(hint, UiKit.GOLD)

## Satu kalimat petunjuk sesuai jenis tantangan. String kosong berarti belum ada.
func _hint_text() -> String:
	match str(_c.get("type", "")):
		"wire":
			var need := _wire_required()
			if need.is_empty():
				return ""
			return "Petunjuk: salah satu sambungan wajib adalah antara “%s” dan “%s”." \
				% [_wire_name(need[0][0]), _wire_name(need[0][1])]
		"craft":
			var slots: Array = _c.get("slots", [])
			if slots.is_empty():
				return ""
			return "Petunjuk: slot pertama adalah “%s”, dan slot terakhir “%s”." \
				% [str(slots[0]), str(slots[slots.size() - 1])]
		"order":
			var items: Array = _c.get("items", [])
			if items.is_empty():
				return ""
			return "Petunjuk: langkah pertama adalah “%s”." % str(items[0])
		"cipher":
			var ct := str(_c.get("ciphertext", ""))
			var plain := str(_c.get("answer", ""))
			var shift := int(_c.get("answer_shift", 0))
			if ct.is_empty() or plain.is_empty():
				return ""
			return "Petunjuk: putar cakram %d langkah ke belakang; “%s” menjadi “%s”." \
				% [shift, ct.substr(0, 1), plain.substr(0, 1)]
		"fill":
			var accept: Array = _c.get("accept", [])
			if accept.is_empty():
				return ""
			var word := str(accept[0])
			return "Petunjuk: isian yang tepat berawalan “%s” dan panjangnya %d huruf." \
				% [word.substr(0, 1).to_upper(), word.replace(" ", "").length()]
		"build":
			var parts: Array = _c.get("parts", [])
			if parts.is_empty():
				return ""
			var first: Dictionary = parts[0]
			return "Petunjuk: ada %d bagian; bagian “%s” diisi “%s”." \
				% [parts.size(), str(first.get("pre", "")), str(first.get("answer", ""))]
	var opts: Array = _c.get("options", [])
	var key := int(_c.get("answer", -1))
	if key >= 0 and key < opts.size():
		return "Petunjuk: jawaban yang paling tepat berkaitan dengan “%s”." % str(opts[key]).substr(0, 40)
	return ""

# ------------------------------------------------------------------ SQL builder
func _build_sql() -> void:
	var info := UiKit.label(str(_c.get("tables", "")), 15, UiKit.MUTED, WIDTH - 60)
	_body.add_child(info)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.05, 0.07, 0.11, 1.0), UiKit.BORDER, 8, 1))
	_body.add_child(panel)
	var v := UiKit.vbox(6)
	panel.add_child(v)

	for part in _c.get("parts", []):
		var row := UiKit.hbox(10)
		v.add_child(row)
		var pre := UiKit.kicker(str(part["pre"]), UiKit.GOLD, 11)
		pre.custom_minimum_size.x = 104
		pre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(pre)
		var ob := UiKit.small_dropdown(WIDTH - 240)
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var opts: Array = part["options"].duplicate()
		opts.shuffle()
		for o in opts:
			ob.add_item(str(o))
		row.add_child(ob)
		_parts_select.append({"node": ob, "answer": str(part["answer"])})

	var check := UiKit.primary_button("Jalankan Query", UiKit.ACCENT, 17)
	check.pressed.connect(_on_sql_check)
	_action_row.add_child(check)

func _on_sql_check() -> void:
	if _done:
		return
	var ok := true
	for p in _parts_select:
		var ob: OptionButton = p["node"]
		var chosen := ob.get_item_text(ob.selected)
		if chosen != str(p["answer"]):
			ok = false
	if ok:
		_win()
	else:
		_attempts += 1
		_register_mistake()
		_show_feedback("Query belum menghasilkan keluaran yang diminta. Periksa klausa SELECT, JOIN, WHERE, dan ORDER BY.", UiKit.DANGER)
		if _attempts >= 2:
			var first_bad := ""
			for p in _parts_select:
				var ob: OptionButton = p["node"]
				if ob.get_item_text(ob.selected) != str(p["answer"]):
					first_bad = str(p["answer"])
					break
			_show_feedback("Petunjuk: klausa yang belum tepat seharusnya berbunyi “%s”." % first_bad, UiKit.GOLD)

# ------------------------------------------------------------------ urutan
func _build_order() -> void:
	var cols := UiKit.hbox(18)
	_body.add_child(cols)

	var left := UiKit.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UiKit.label("Langkah tersedia", 14, UiKit.MUTED))
	_pool_box = UiKit.vbox(4)
	left.add_child(_pool_box)

	var right := UiKit.vbox(4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UiKit.label("Urutan jawabanmu", 14, UiKit.MUTED))
	_answer_box = UiKit.vbox(4)
	right.add_child(_answer_box)

	var items: Array = _c.get("items", []).duplicate()
	_order_pool = items.duplicate()
	for attempt in range(12):
		_order_pool.shuffle()
		var same := true
		for i in range(_order_pool.size()):
			if str(_order_pool[i]) != str(items[i]):
				same = false
				break
		if not same:
			break
	_refresh_order()

	var check := UiKit.primary_button("Periksa Urutan", UiKit.ACCENT, 17)
	check.pressed.connect(_on_order_check)
	_action_row.add_child(check)

func _refresh_order() -> void:
	for c in _pool_box.get_children():
		c.queue_free()
	for c in _answer_box.get_children():
		c.queue_free()

	for i in range(_order_pool.size()):
		var idx := i
		var b := UiKit.small_choice_button("%s" % str(_order_pool[i]), 14)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(430, 34)
		b.pressed.connect(func():
			_order_answer.append(_order_pool[idx])
			_order_pool.remove_at(idx)
			_refresh_order()
		)
		_pool_box.add_child(b)

	if _order_answer.is_empty():
		var hint := UiKit.label("Klik langkah di kolom kiri untuk menyusun urutan di sini.", 14, UiKit.MUTED, 400)
		_answer_box.add_child(hint)

	for i in range(_order_answer.size()):
		var idx := i
		var b := UiKit.small_choice_button("%d.  %s" % [i + 1, str(_order_answer[i])], 14)
		b.add_theme_stylebox_override("normal", UiKit.panel_style(Color("dcebc0"), Color("6f9a4a"), 3, 2, false))
		b.add_theme_stylebox_override("hover", UiKit.panel_style(Color("e6f2cd"), UiKit.ACCENT, 3, 3, false))
		b.add_theme_stylebox_override("pressed", UiKit.panel_style(Color("cfe0ab"), Color("6f9a4a"), 3, 2, false))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(430, 34)
		b.pressed.connect(func():
			_order_pool.append(_order_answer[idx])
			_order_answer.remove_at(idx)
			_refresh_order()
		)
		_answer_box.add_child(b)

func _on_order_check() -> void:
	if _done:
		return
	var items: Array = _c.get("items", [])
	if _order_answer.size() != items.size():
		_show_feedback("Susun seluruh langkah terlebih dahulu (%d/%d)." % [_order_answer.size(), items.size()], UiKit.GOLD)
		return
	var ok := true
	for i in range(items.size()):
		if str(_order_answer[i]) != str(items[i]):
			ok = false
			break
	if ok:
		_win()
	else:
		_attempts += 1
		if bool(_c.get("fatal", false)):
			_fatal_fail("Urutan salah. Puzzle gagal — nyawa wilayah habis.")
			return
		_register_mistake()
		_show_feedback("Urutannya belum tepat. Ingat alur keadaan proses/sistem dari awal sampai akhir.", UiKit.DANGER)
		if _attempts >= 2:
			_show_feedback("Petunjuk: langkah pertama adalah “%s”." % str(items[0]), UiKit.GOLD)

# ------------------------------------------------------------- isi rumpang
func _build_fill() -> void:
	var code := str(_c.get("code", ""))
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.panel_style(Color("0f1d14"), Color("6f9a4a"), 3, 2, false))
	_body.add_child(frame)
	var l := UiKit.label(code, 19, Color("cfe8a8"), WIDTH - 140)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frame.add_child(l)

	_body.add_child(UiKit.label("Tulis isi bagian bertanda ___ :", 14, UiKit.MUTED))
	_fill_edit = LineEdit.new()
	_fill_edit.placeholder_text = "tulis jawabanmu di sini…"
	_fill_edit.custom_minimum_size = Vector2(WIDTH - 96, 50)
	var f := UiKit.body_font()
	if f:
		_fill_edit.add_theme_font_override("font", f)
	_fill_edit.add_theme_font_size_override("font_size", 19)
	_fill_edit.add_theme_color_override("font_color", UiKit.INK)
	_fill_edit.add_theme_color_override("font_placeholder_color", Color("8a7a5c"))
	_fill_edit.add_theme_color_override("caret_color", UiKit.INK)
	_fill_edit.add_theme_color_override("selection_color", Color("b9cf92"))
	_fill_edit.add_theme_stylebox_override("normal", UiKit.parchment_style(20, 12))
	_fill_edit.add_theme_stylebox_override("focus", UiKit.parchment_style(20, 12))
	_body.add_child(_fill_edit)

	var check := UiKit.primary_button("Periksa Jawaban", UiKit.ACCENT, 17)
	check.pressed.connect(_on_fill_check)
	_action_row.add_child(check)
	_fill_edit.grab_focus()

func _on_fill_check() -> void:
	if _done or _fill_edit == null:
		return
	var typed := _fill_edit.text.strip_edges().to_lower()
	var accept: Array = _c.get("accept", [])
	var ok := false
	for a in accept:
		if typed == str(a).strip_edges().to_lower():
			ok = true
			break
	if ok:
		_win()
		return
	_attempts += 1
	if bool(_c.get("fatal", false)):
		_fatal_fail("Jawaban salah. Puzzle gagal — nyawa wilayah habis.")
		return
	_register_mistake()
	_show_feedback("Belum tepat. Periksa lagi bagian rumpangnya.", UiKit.DANGER)

## Puzzle gagal tidak memotong satu nyawa: nyawa wilayah langsung habis,
## progres direset, dan pemain dikembalikan ke Kota Unggul oleh main.gd.
func _fatal_fail(msg: String) -> void:
	Game.sfx("sfx_err")
	_show_feedback(msg, UiKit.DANGER)
	visible = false
	Game.fail_puzzle(_map_id())

# ------------------------------------------------------------------ caesar
func _build_cipher() -> void:
	var ct := str(_c.get("ciphertext", ""))

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.05, 0.07, 0.11, 1.0), UiKit.BORDER, 8, 1))
	_body.add_child(box)
	var v := UiKit.vbox(10)
	box.add_child(v)

	var row := UiKit.hbox(24)
	v.add_child(row)
	row.add_child(UiKit.label("Ciphertext", 14, UiKit.MUTED))
	var ct_lbl := UiKit.title(ct, 18, UiKit.GOLD)
	row.add_child(ct_lbl)

	var row2 := UiKit.hbox(24)
	v.add_child(row2)
	row2.add_child(UiKit.label("Hasil putar", 14, UiKit.MUTED))
	_cipher_label = UiKit.title(_decode(ct, 0), 18, UiKit.ACCENT)
	row2.add_child(_cipher_label)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(sp2)
	var shift_lbl := UiKit.label("geser 0", 14, UiKit.MUTED)
	row2.add_child(shift_lbl)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 25
	slider.step = 1
	slider.value = 0
	slider.custom_minimum_size = Vector2(WIDTH - 90, 26)
	slider.value_changed.connect(func(val: float):
		_cipher_shift = int(val)
		_cipher_label.text = _decode(ct, _cipher_shift)
		shift_lbl.text = "geser %d" % _cipher_shift
	)
	v.add_child(slider)

	var scale_row := UiKit.hbox(10)
	v.add_child(scale_row)
	scale_row.add_child(UiKit.label("0", 12, UiKit.MUTED))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_row.add_child(sp)
	scale_row.add_child(UiKit.label("25", 12, UiKit.MUTED))

	var check := UiKit.primary_button("Periksa Jawaban", UiKit.ACCENT, 17)
	check.pressed.connect(_on_cipher_check)
	_action_row.add_child(check)

func _decode(text: String, shift: int) -> String:
	var out := ""
	for ch in text:
		if ch >= "A" and ch <= "Z":
			var code := (ch.unicode_at(0) - 65 - shift + 26 * 2) % 26
			out += String.chr(65 + code)
		else:
			out += ch
	return out

func _on_cipher_check() -> void:
	if _done:
		return
	if _cipher_shift == int(_c.get("answer_shift", -1)):
		_win()
	else:
		_attempts += 1
		_register_mistake()
		_show_feedback("Pesan belum terbaca sebagai kata yang bermakna. Coba geser satu per satu.", UiKit.DANGER)

# ------------------------------------------------------------------ hasil
## Id wilayah diturunkan dari id tantangan ("hutan-b3" -> "hutan").
func _map_id() -> String:
	var cid := str(_c.get("id", ""))
	if cid.contains("-"):
		return cid.split("-")[0]
	return Game.current_map

## Mencatat jawaban salah ke aturan nyawa. Bila nyawa wilayah habis, panel
## ditutup dan main.gd mengulang wilayah tersebut.
func _register_mistake() -> void:
	var left := Game.note_mistake(_map_id(), str(_c.get("id", "")))
	_refresh_hearts()
	if left <= 0:
		visible = false
		return
	_lives_suffix = "   Nyawa wilayah %d/%d." % [left, Content.LIVES_PER_MAP]

## Menyalakan/mematikan hati sesuai sisa nyawa wilayah.
func _refresh_hearts() -> void:
	if _hearts.is_empty():
		return
	var left := Game.lives_left(_map_id())
	var full := load("res://assets/ui/heart_full.png")
	var empty := load("res://assets/ui/heart_empty.png")
	for i in range(_hearts.size()):
		var h: TextureRect = _hearts[i]
		h.texture = full if i < left else empty

func _show_feedback(text: String, color: Color) -> void:
	if color == UiKit.DANGER:
		Game.sfx("sfx_err")
	elif color == UiKit.GOLD:
		Game.sfx("sfx_click", -11.0)
	if _lives_suffix != "":
		text += _lives_suffix
		_lives_suffix = ""
	_feedback.text = "   " + text
	_feedback.add_theme_color_override("font_color", color)
	_feedback.visible = true

func _win() -> void:
	if _done:
		return
	_done = true
	Game.sfx("sfx_ok")
	_show_feedback("Benar. " + str(_c.get("explain", "")), UiKit.ACCENT)
	for c in _action_row.get_children():
		c.queue_free()
	var btn := UiKit.primary_button("Lanjut  ▸", UiKit.ACCENT, 17)
	btn.pressed.connect(func():
		visible = false
		solved.emit(str(_c.get("id", "")))
	)
	_action_row.add_child(btn)
	btn.grab_focus()

func _on_close() -> void:
	UiKit.set_theme("")
	if _done:
		visible = false
		solved.emit(str(_c.get("id", "")))
	else:
		visible = false
		closed.emit()

func is_open() -> bool:
	return visible
