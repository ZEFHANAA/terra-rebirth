extends Control
## Layar data pengujian: rekap peserta, ekspor CSV, dan pintu masuk asesmen.
##
## Tidak ada pre-test di sini. Rancangan penelitian adalah one-group
## posttest-only (Bab III 3.1), sehingga instrumen yang dipakai hanya
## post-test 20 soal (3.9) dan kuesioner SUS 10 butir (3.9).

signal back_pressed
signal open_asesmen

## Lebar tetap tiap kolom. Header dan baris memakai lebar yang sama supaya
## GridContainer menghitung kolom identik dan judul tepat di atas datanya.
const COL_W := [70, 150, 92, 52, 42, 42, 62, 42, 62, 54]

var _grid: GridContainer
var _info: Label
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)

	var v := UiKit.vbox(12)
	margin.add_child(v)

	var head := UiKit.hbox(14)
	v.add_child(head)
	var hcol := UiKit.vbox(2)
	head.add_child(hcol)
	hcol.add_child(UiKit.kicker("MODE PENGUJIAN", UiKit.GOLD, 10))
	hcol.add_child(UiKit.title("DATA PESERTA", 22, UiKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UiKit.label("Kode peserta diisi saat asesmen dimulai", 13, UiKit.MUTED))
	var back := UiKit.button("Kembali  [Esc]", 14, UiKit.MUTED)
	back.pressed.connect(func(): back_pressed.emit())
	head.add_child(back)

	_info = UiKit.label("", 14, UiKit.MUTED, 1120)
	v.add_child(_info)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.07, 0.1, 0.15, 1.0), UiKit.BORDER, 12, 2))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(pad)

	var col := UiKit.vbox(8)
	pad.add_child(col)

	var heads := ["Kode", "Tanggal", "Durasi (mnt)", "Post", "BD", "SO", "Kripto", "IoT", "Tuntas", "SUS"]
	var head_grid := GridContainer.new()
	head_grid.columns = 10
	head_grid.add_theme_constant_override("h_separation", 26)
	col.add_child(head_grid)
	for i in range(heads.size()):
		var hl := UiKit.label(str(heads[i]), 13, UiKit.ACCENT)
		hl.custom_minimum_size.x = COL_W[i]
		head_grid.add_child(hl)
	col.add_child(UiKit.rule())
	col.add_child(UiKit.label("BD = Basis Data · SO = Sistem Operasi · Kripto = Kriptografi · IoT = Internet of Things · Post = nilai post-test (0–100) · Tuntas = nilai ≥ 70", 12, UiKit.MUTED, 1120))
	col.add_child(UiKit.label("Rancangan pengujian: target 30 responden purposive sampling (Bab III 3.8) · durasi sesi 60 menit untuk Map 1 sampai post-test (Bab III 3.10) · responden yang tidak menuntaskan seluruh map dicatat sebagai data tidak lengkap", 12, UiKit.MUTED, 1120))

	_grid = GridContainer.new()
	_grid.columns = 10
	_grid.add_theme_constant_override("h_separation", 26)
	_grid.add_theme_constant_override("v_separation", 8)
	col.add_child(_grid)

	var row := UiKit.hbox(10)
	v.add_child(row)
	var open_btn := UiKit.primary_button("Buka asesmen (post-test & SUS)", UiKit.GOLD, 15)
	open_btn.pressed.connect(func(): open_asesmen.emit())
	row.add_child(open_btn)
	var csv := UiKit.button("Ekspor CSV", 15)
	csv.pressed.connect(func():
		var path := "user://terra_rekap.csv"
		if Game.export_csv(path):
			_status.add_theme_color_override("font_color", UiKit.ACCENT)
			_status.text = "CSV tersimpan: " + ProjectSettings.globalize_path(path)
		else:
			_status.add_theme_color_override("font_color", UiKit.DANGER)
			_status.text = "Belum ada data untuk diekspor."
	)
	row.add_child(csv)
	var refresh_btn := UiKit.button("Muat ulang", 15, UiKit.MUTED)
	refresh_btn.pressed.connect(refresh)
	row.add_child(refresh_btn)

	_status = UiKit.label("", 14, UiKit.ACCENT, 1120)
	v.add_child(_status)
	refresh()

func refresh() -> void:
	if _grid == null:
		return
	var recs := Game.read_records()
	_info.text = "%d peserta tercatat  ·  berkas: %s  ·  instrumen: post-test %d soal, SUS %d butir, batas tuntas %d" % [
		recs.size(), Game.record_path.get_file(),
		Game.posttest_items().size(), Content.SUS_ITEMS.size(), Content.PASSING_SCORE]
	for c in _grid.get_children():
		c.queue_free()
	if recs.is_empty():
		_grid.add_child(UiKit.label("Belum ada peserta.", 14, UiKit.MUTED))
		return
	for r in recs:
		var per := r.get("materi", {}) as Dictionary
		var cells := [
			str(r.get("kode", "-")),
			str(r.get("tanggal", "-")).replace("T", " "),
			"%.1f" % float(r.get("durasi_menit", 0.0)),
			str(int(r.get("post", 0))),
			str(int(per.get("Basis Data", 0))),
			str(int(per.get("Sistem Operasi", 0))),
			str(int(per.get("Kriptografi", 0))),
			str(int(per.get("Internet of Things", 0))),
			"ya" if bool(r.get("tuntas", false)) else "tidak",
			("—" if float(r.get("sus", -1.0)) < 0.0 else "%.1f" % float(r.get("sus", 0.0))),
		]
		for i in range(cells.size()):
			var col := UiKit.TEXT
			if i == 3:
				col = UiKit.ACCENT if bool(r.get("tuntas", false)) else UiKit.DANGER
			var cl := UiKit.label(str(cells[i]), 14, col)
			cl.custom_minimum_size.x = COL_W[i]
			_grid.add_child(cl)
