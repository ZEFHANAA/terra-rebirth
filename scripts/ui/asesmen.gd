extends Control
## Panel asesmen akhir permainan: post-test 20 soal lalu kuesioner SUS.
##
## Mengikuti dokumen penelitian terbaru (Bab III):
##   3.9   post-test 20 soal pilihan ganda (5 soal tiap materi), SUS 10 butir
##   3.10  dikerjakan setelah seluruh map selesai, di Map 6 (The Source)
##   3.11  nilai = (benar / 20) x 100, batas tuntas 70; SUS 0-100, acuan 68,
##         interpretasi Tabel 3.4 (>= 68 dapat diterima, < 68 perlu diperbaiki)
##
## Panel ini sengaja tidak punya pre-test: rancangan penelitian adalah
## one-group posttest-only (Bab III 3.1).

signal finished
signal cancelled

const PANEL_W := 900

var _dim: ColorRect
var _panel: PanelContainer
var _box: VBoxContainer
var _hint: Label

var _stage := "intro"      # intro | posttest | result | sus | done
var _qi := 0
var _post: Array = []
var _sus: Array = []
var _result: Dictionary = {}
var _sus_score := -1.0
var _kode_edit: LineEdit

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.06, 0.9)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel_style(
		Color(0.07, 0.1, 0.155, 0.99), UiKit.ACCENT, 14, 2))
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	_box = UiKit.vbox(12)
	margin.add_child(_box)

	_post = _blank(Content.TEST_ITEMS.size())
	_sus = _blank(Content.SUS_ITEMS.size())

func _blank(n: int) -> Array:
	var a: Array = []
	for i in range(n):
		a.append(-1)
	return a

## Membuka panel. Bila asesmen sudah pernah diselesaikan, langsung ke ringkasan.
func open() -> void:
	visible = true
	_qi = 0
	if Game.post_done and Game.sus_done:
		_result = Game.posttest_result()
		_sus_score = Game.sus_value()
		_stage = "done"
	elif Game.post_done:
		_result = Game.posttest_result()
		_stage = "result"
	else:
		_stage = "intro"
	_render()

func _render() -> void:
	for c in _box.get_children():
		c.queue_free()
	match _stage:
		"intro":
			_page_intro()
		"posttest":
			_page_posttest()
		"result":
			_page_result()
		"sus":
			_page_sus()
		"done":
			_page_done()

# ------------------------------------------------------------------ intro
func _page_intro() -> void:
	_box.add_child(UiKit.kicker("ASESMEN AKHIR · MAP 6 THE SOURCE", UiKit.GOLD, 10))
	_box.add_child(UiKit.title("POST-TEST & KUESIONER SUS", 26, UiKit.TEXT))
	_box.add_child(UiKit.rule())
	_box.add_child(UiKit.label(
		"Kau telah menyelesaikan seluruh wilayah. Sekarang kerjakan post-test 20 soal " \
		+ "(5 soal untuk setiap materi) lalu isi kuesioner SUS 10 pernyataan. " \
		+ "Jawaban tidak memengaruhi nilai mata kuliah apa pun.", 15, UiKit.MUTED, PANEL_W - 60))
	_box.add_child(UiKit.spacer(6))

	var row := UiKit.hbox(12)
	_box.add_child(row)
	row.add_child(UiKit.label("Kode peserta", 15, UiKit.TEXT))
	_kode_edit = LineEdit.new()
	_kode_edit.placeholder_text = "mis. P01"
	_kode_edit.text = Game.player_code
	_kode_edit.custom_minimum_size = Vector2(200, 38)
	_kode_edit.add_theme_font_size_override("font_size", 16)
	row.add_child(_kode_edit)
	row.add_child(UiKit.label("(dipakai peneliti untuk mencocokkan data)", 13, UiKit.MUTED))

	_box.add_child(UiKit.spacer(8))
	_hint = UiKit.label("", 14, UiKit.DANGER, PANEL_W - 60)
	_box.add_child(_hint)
	_kode_edit.text_changed.connect(func(_t): _warn_kode())
	_warn_kode()

	var btns := UiKit.hbox(10)
	_box.add_child(btns)
	var start := UiKit.primary_button("Mulai post-test", UiKit.GOLD, 17)
	start.pressed.connect(_start_posttest)
	btns.add_child(start)
	var cancel := UiKit.button("Kembali", 15, UiKit.MUTED)
	cancel.pressed.connect(func(): _close(false))
	btns.add_child(cancel)

## Peringatan bila kode peserta sudah pernah dipakai (data akan ditimpa).
func _warn_kode() -> void:
	if _hint == null or _kode_edit == null:
		return
	var k := _kode_edit.text.strip_edges()
	if k != "" and _kode_exists(k):
		_hint.add_theme_color_override("font_color", UiKit.GOLD)
		_hint.text = "Kode %s sudah ada di rekap — baris lama akan ditimpa. Pakai kode lain bila ini peserta berbeda." % k
	else:
		_hint.add_theme_color_override("font_color", UiKit.DANGER)
		_hint.text = ""

func _kode_exists(k: String) -> bool:
	for r in Game.read_records():
		if str(r.get("kode", "")) == k:
			return true
	return false

func _start_posttest() -> void:
	var kode := _kode_edit.text.strip_edges() if _kode_edit != null else ""
	if kode == "":
		_hint.text = "Isi kode peserta terlebih dahulu agar data dapat dicocokkan."
		return
	Game.player_code = kode
	Game.save_game()
	_post = _blank(Content.TEST_ITEMS.size())
	_qi = 0
	_stage = "posttest"
	_render()

# --------------------------------------------------------------- post-test
func _page_posttest() -> void:
	var total := Content.TEST_ITEMS.size()
	var item: Dictionary = Content.TEST_ITEMS[_qi]

	var head := UiKit.hbox(12)
	_box.add_child(head)
	head.add_child(UiKit.kicker("POST-TEST", UiKit.GOLD, 10))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UiKit.label("Soal %d dari %d" % [_qi + 1, total], 14, UiKit.MUTED))
	head.add_child(UiKit.chip(str(item["m"]), UiKit.BLUE))

	_box.add_child(UiKit.rule())

	var q := UiKit.label("%d. %s" % [_qi + 1, str(item["q"])], 18, UiKit.TEXT, PANEL_W - 70)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(q)

	var group := ButtonGroup.new()
	var opts: Array = item["o"]
	for oi in range(opts.size()):
		var b := Button.new()
		b.text = "%s.  %s" % [char(65 + oi), str(opts[oi])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(PANEL_W - 70, 40)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = int(_post[_qi]) == oi
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_stylebox_override("normal", UiKit.panel_style(Color(0.06, 0.09, 0.13), UiKit.BORDER, 8, 1))
		b.add_theme_stylebox_override("hover", UiKit.panel_style(Color(0.09, 0.13, 0.19), UiKit.ACCENT, 8, 1))
		b.add_theme_stylebox_override("pressed", UiKit.panel_style(Color(0.1, 0.24, 0.2), UiKit.ACCENT, 8, 2))
		var idx := oi
		b.toggled.connect(func(on: bool):
			if on:
				_post[_qi] = idx
				_hint.text = ""
		)
		_box.add_child(b)

	_box.add_child(UiKit.spacer(4))
	_hint = UiKit.label("", 14, UiKit.DANGER)
	_box.add_child(_hint)

	var nav := UiKit.hbox(10)
	_box.add_child(nav)
	var prev := UiKit.button("← Sebelumnya", 15, UiKit.MUTED)
	prev.disabled = _qi == 0
	prev.pressed.connect(func():
		_qi -= 1
		_render()
	)
	nav.add_child(prev)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(sp2)
	if _qi + 1 < total:
		var nxt := UiKit.primary_button("Berikutnya →", UiKit.ACCENT, 16)
		nxt.pressed.connect(func():
			_qi += 1
			_render()
		)
		nav.add_child(nxt)
	else:
		var submit := UiKit.primary_button("Kumpulkan post-test", UiKit.GOLD, 16)
		submit.pressed.connect(_submit_posttest)
		nav.add_child(submit)

func _submit_posttest() -> void:
	for i in range(_post.size()):
		if int(_post[i]) < 0:
			_qi = i
			_render()
			_hint.text = "Masih ada soal yang belum dijawab."
			return
	_result = Game.submit_posttest(_post)
	_stage = "result"
	_render()

# ------------------------------------------------------------------ hasil
func _page_result() -> void:
	var nilai := int(_result.get("nilai", 0))
	var tuntas := bool(_result.get("tuntas", false))
	_box.add_child(UiKit.kicker("HASIL POST-TEST", UiKit.GOLD, 10))
	_box.add_child(UiKit.title("NILAI %d" % nilai, 34, UiKit.ACCENT if tuntas else UiKit.DANGER))
	_box.add_child(UiKit.label(
		"%d benar dari %d soal. Batas ketuntasan %d." % [
			int(_result.get("benar", 0)), int(_result.get("total", 0)), Content.PASSING_SCORE],
		15, UiKit.TEXT, PANEL_W - 60))
	_box.add_child(UiKit.label(
		"Status: " + ("tuntas" if tuntas else "belum mencapai batas ketuntasan"),
		15, UiKit.ACCENT if tuntas else UiKit.DANGER))
	_box.add_child(UiKit.rule())

	var per := _result.get("per_materi", {}) as Dictionary
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	_box.add_child(grid)
	grid.add_child(UiKit.label("Materi", 14, UiKit.ACCENT))
	grid.add_child(UiKit.label("Benar", 14, UiKit.ACCENT))
	grid.add_child(UiKit.label("Total", 14, UiKit.ACCENT))
	for mt in Content.MATERI:
		var d: Dictionary = per.get(mt, {})
		grid.add_child(UiKit.label(str(mt), 15, UiKit.TEXT))
		grid.add_child(UiKit.label(str(int(d.get("benar", 0))), 15, UiKit.TEXT))
		grid.add_child(UiKit.label(str(int(d.get("total", 0))), 15, UiKit.MUTED))

	_box.add_child(UiKit.spacer(8))
	var go := UiKit.primary_button("Lanjut ke kuesioner SUS →", UiKit.GOLD, 17)
	go.pressed.connect(func():
		_qi = 0
		_sus = _blank(Content.SUS_ITEMS.size())
		_stage = "sus"
		_render()
	)
	_box.add_child(go)

# -------------------------------------------------------------------- SUS
func _page_sus() -> void:
	var total := Content.SUS_ITEMS.size()
	var head := UiKit.hbox(12)
	_box.add_child(head)
	head.add_child(UiKit.kicker("SYSTEM USABILITY SCALE", UiKit.GOLD, 10))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UiKit.label("Pernyataan %d dari %d" % [_qi + 1, total], 14, UiKit.MUTED))
	_box.add_child(UiKit.rule())

	var q := UiKit.label("%d. %s" % [_qi + 1, str(Content.SUS_ITEMS[_qi])], 19, UiKit.TEXT, PANEL_W - 70)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(q)
	_box.add_child(UiKit.label("1 = sangat tidak setuju · 5 = sangat setuju", 13, UiKit.MUTED))
	_box.add_child(UiKit.spacer(6))

	var group := ButtonGroup.new()
	var row := UiKit.hbox(10)
	_box.add_child(row)
	for s in range(1, 6):
		var b := Button.new()
		b.text = str(s)
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(96, 52)
		b.button_pressed = int(_sus[_qi]) == s
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_stylebox_override("normal", UiKit.panel_style(Color(0.06, 0.09, 0.13), UiKit.BORDER, 8, 1))
		b.add_theme_stylebox_override("hover", UiKit.panel_style(Color(0.09, 0.13, 0.19), UiKit.ACCENT, 8, 1))
		b.add_theme_stylebox_override("pressed", UiKit.panel_style(Color(0.1, 0.24, 0.2), UiKit.ACCENT, 8, 2))
		var val := s
		b.toggled.connect(func(on: bool):
			if on:
				_sus[_qi] = val
				_hint.text = ""
		)
		row.add_child(b)

	_box.add_child(UiKit.spacer(6))
	_hint = UiKit.label("", 14, UiKit.DANGER)
	_box.add_child(_hint)

	var nav := UiKit.hbox(10)
	_box.add_child(nav)
	var prev := UiKit.button("← Sebelumnya", 15, UiKit.MUTED)
	prev.disabled = _qi == 0
	prev.pressed.connect(func():
		_qi -= 1
		_render()
	)
	nav.add_child(prev)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(sp2)
	if _qi + 1 < total:
		var nxt := UiKit.primary_button("Berikutnya →", UiKit.ACCENT, 16)
		nxt.pressed.connect(func():
			_qi += 1
			_render()
		)
		nav.add_child(nxt)
	else:
		var submit := UiKit.primary_button("Kumpulkan SUS", UiKit.GOLD, 16)
		submit.pressed.connect(_submit_sus)
		nav.add_child(submit)

func _submit_sus() -> void:
	for i in range(_sus.size()):
		if int(_sus[i]) < 1:
			_qi = i
			_render()
			_hint.text = "Masih ada pernyataan yang belum dinilai."
			return
	_sus_score = Game.submit_sus(_sus)
	_stage = "done"
	_render()

# ------------------------------------------------------------------- akhir
func _page_done() -> void:
	var nilai := int(_result.get("nilai", 0))
	_box.add_child(UiKit.kicker("ASESMEN SELESAI", UiKit.GOLD, 10))
	_box.add_child(UiKit.title("DATA TERSIMPAN", 28, UiKit.ACCENT))
	_box.add_child(UiKit.rule())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 8)
	_box.add_child(grid)
	var rows := [
		["Kode peserta", Game.player_code if Game.player_code != "" else "—"],
		["Nilai post-test", "%d / 100" % nilai],
		["Batas ketuntasan", "%d — %s" % [Content.PASSING_SCORE,
			"tuntas" if bool(_result.get("tuntas", false)) else "belum tuntas"]],
		["Skor SUS", "%.1f / 100" % _sus_score],
		["Acuan SUS", "%d — %s" % [int(Content.SUS_REFERENCE),
			"di atas acuan" if _sus_score >= Content.SUS_REFERENCE else "di bawah acuan"]],
		["Interpretasi usability", "dapat diterima" if _sus_score >= Content.SUS_REFERENCE else "perlu diperbaiki"],
		["Durasi bermain", "%.1f menit" % Game.playtime_minutes()],
	]
	for r in rows:
		grid.add_child(UiKit.label(str(r[0]), 15, UiKit.MUTED))
		grid.add_child(UiKit.label(str(r[1]), 15, UiKit.TEXT))

	var per := _result.get("per_materi", {}) as Dictionary
	var parts: Array = []
	for mt in Content.MATERI:
		var d: Dictionary = per.get(mt, {})
		parts.append("%s %d/%d" % [mt, int(d.get("benar", 0)), int(d.get("total", 0))])
	_box.add_child(UiKit.spacer(6))
	_box.add_child(UiKit.label("Benar per materi:  " + "  ·  ".join(parts), 14, UiKit.TEXT, PANEL_W - 60))

	_box.add_child(UiKit.spacer(10))
	_box.add_child(UiKit.label(
		"Skor SUS bukan persentase keberhasilan game, melainkan posisi skor pada skala 0-100 " \
		+ "yang dibandingkan dengan nilai acuan 68 (Tabel 3.4: >= 68 dapat diterima, < 68 perlu diperbaiki).", 13, UiKit.MUTED, PANEL_W - 60))

	var go := UiKit.primary_button("Lihat penutup cerita", UiKit.GOLD, 17)
	go.pressed.connect(func(): _close(true))
	_box.add_child(go)

func _close(ok: bool) -> void:
	visible = false
	if ok:
		finished.emit()
	else:
		cancelled.emit()
