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
var _sum: HBoxContainer
var _sum_materi: Label

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

	# Ringkasan angka yang biasanya ditanyakan saat sidang (rata-rata nilai,
	# ketuntasan, SUS, durasi). Dihitung dari baris tabel di bawahnya, bukan
	# data baru.
	_sum = UiKit.hbox(8)
	v.add_child(_sum)
	_sum_materi = UiKit.label("", 13, UiKit.MUTED, 1120)
	v.add_child(_sum_materi)

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

## Menghitung ringkasan dari daftar rekaman. Dipisah dari `refresh()` supaya
## bisa diuji tanpa menyentuh berkas data peserta.
## SUS hanya dirata-ratakan dari peserta yang mengisi (nilai < 0 = belum diisi),
## karena menghitung yang kosong sebagai 0 akan menurunkan hasil secara palsu.
static func ringkas(recs: Array) -> Dictionary:
	var n := recs.size()
	var hasil := {
		"n": n, "post": 0.0, "tuntas": 0, "tuntas_pct": 0,
		"sus": 0.0, "sus_n": 0, "durasi": 0.0,
		"materi": {"Basis Data": 0.0, "Sistem Operasi": 0.0, "Kriptografi": 0.0, "Internet of Things": 0.0},
	}
	if n == 0:
		return hasil
	var post := 0.0
	var sus := 0.0
	var durasi := 0.0
	for r in recs:
		var rec := r as Dictionary
		post += float(rec.get("post", 0))
		durasi += float(rec.get("durasi_menit", 0.0))
		if bool(rec.get("tuntas", false)):
			hasil["tuntas"] = int(hasil["tuntas"]) + 1
		var s := float(rec.get("sus", -1.0))
		if s >= 0.0:
			hasil["sus"] = float(hasil["sus"]) + s
			hasil["sus_n"] = int(hasil["sus_n"]) + 1
		var per := rec.get("materi", {}) as Dictionary
		for k in (hasil["materi"] as Dictionary).keys():
			hasil["materi"][k] = float(hasil["materi"][k]) + float(per.get(k, 0))
	hasil["post"] = post / float(n)
	hasil["durasi"] = durasi / float(n)
	hasil["tuntas_pct"] = int(round(100.0 * float(hasil["tuntas"]) / float(n)))
	if int(hasil["sus_n"]) > 0:
		hasil["sus"] = float(hasil["sus"]) / float(hasil["sus_n"])
	for k in (hasil["materi"] as Dictionary).keys():
		hasil["materi"][k] = float(hasil["materi"][k]) / float(n)
	return hasil

## Satu kartu ringkasan: angka besar di atas, keterangan kecil di bawah.
func _stat(judul: String, nilai: String, catatan := "") -> Control:
	var box := UiKit.vbox(1)
	box.custom_minimum_size.x = 214
	box.add_child(UiKit.title(nilai, 19, UiKit.GOLD))
	box.add_child(UiKit.kicker(judul.to_upper(), UiKit.MUTED, 9))
	# Keterangan cakupan ditaruh di baris sendiri: kalau digabung ke judul,
	# teksnya melebihi lebar kartu dan terpotong.
	if catatan != "":
		box.add_child(UiKit.label(catatan, 10, UiKit.MUTED, 188))
	return UiKit.card(box)

func _isi_ringkasan(recs: Array) -> void:
	for c in _sum.get_children():
		c.queue_free()
	if recs.is_empty():
		_sum.add_child(_stat("Peserta", "0"))
		_sum.add_child(_stat("Rata-rata post-test", "—"))
		_sum.add_child(_stat("Tuntas", "—"))
		_sum.add_child(_stat("Rata-rata SUS", "—"))
		_sum.add_child(_stat("Rata-rata durasi", "—"))
		_sum_materi.text = ""
		return
	var s := ringkas(recs)
	_sum.add_child(_stat("Peserta", str(int(s["n"]))))
	_sum.add_child(_stat("Rata-rata post-test", "%.1f" % float(s["post"])))
	_sum.add_child(_stat("Tuntas", "%d/%d (%d%%)" % [int(s["tuntas"]), int(s["n"]), int(s["tuntas_pct"])]))
	var sus_n := int(s["sus_n"])
	_sum.add_child(_stat("Rata-rata SUS", "—" if sus_n == 0 else "%.1f" % float(s["sus"]),
		"belum ada yang mengisi" if sus_n == 0 else "%d dari %d peserta mengisi" % [sus_n, int(s["n"])]))
	_sum.add_child(_stat("Rata-rata durasi", "%.0f mnt" % float(s["durasi"])))
	var m := s["materi"] as Dictionary
	_sum_materi.text = ("Rata-rata benar per materi (maks 5 soal)  —  Basis Data %.1f  ·  Sistem Operasi %.1f  ·  Kriptografi %.1f  ·  IoT %.1f"
		% [float(m["Basis Data"]), float(m["Sistem Operasi"]), float(m["Kriptografi"]), float(m["Internet of Things"])])

func refresh() -> void:
	if _grid == null:
		return
	var recs := Game.read_records()
	_isi_ringkasan(recs)
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
