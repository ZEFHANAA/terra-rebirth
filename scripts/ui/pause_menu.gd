extends Control
## Layar jeda: berhenti sebentar tanpa keluar game.
##
## Isinya pengaturan yang paling sering dicari penguji (volume musik, volume efek,
## kecepatan teks) serta jalan pintas ke jurnal misi, mengulang wilayah, dan
## kembali ke menu utama. Panel ini hanya membaca/menulis setelan di `Game`,
## tidak menyentuh progres kecuali tombol "Ulangi Wilayah" ditekan.

signal resumed
## Ditutup dalam mode pengaturan (dibuka dari layar judul, tanpa menjeda apa pun).
signal settings_closed
signal open_journal
signal restart_requested(map_id: String)
signal to_title_requested

const WIDTH := 560

var _map_id := ""
var _map_label: Label
var _title: Label
var _footer: Label
var _jurnal: Button
var _menu: Button
var _resume: Button
## true = panel dipakai sebagai layar pengaturan biasa (dari judul), bukan jeda.
var _settings_only := false
var _kontrol: VBoxContainer
var _bgm: HSlider
var _sfx: HSlider
var _speed: HSlider
var _bgm_v: Label
var _sfx_v: Label
var _speed_v: Label
var _restart: Button
var _confirming := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.03, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.frame_style(28, 22))
	panel.custom_minimum_size = Vector2(WIDTH, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var root := UiKit.vbox(12)
	margin.add_child(root)

	var head := UiKit.hbox(10)
	root.add_child(head)
	_title = UiKit.title("JEDA", 15, UiKit.GOLD)
	head.add_child(_title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_map_label = UiKit.kicker("", UiKit.MUTED, 10)
	head.add_child(_map_label)

	root.add_child(UiKit.rule())

	_bgm = _add_slider(root, "Musik", Game.SILENT_DB, 0.0, 1.0, _on_bgm)
	_bgm_v = _last_value_label
	_sfx = _add_slider(root, "Efek Suara", Game.SILENT_DB, 0.0, 1.0, _on_sfx)
	_sfx_v = _last_value_label
	_speed = _add_slider(root, "Kecepatan Teks", 0.5, 2.0, 0.1, _on_speed)
	_speed_v = _last_value_label

	root.add_child(UiKit.rule())

	# Daftar tombol dulu ditulis di kaki layar judul. Di jeda lebih berguna:
	# bisa dibuka kapan saja saat pemain lupa, bukan cuma sekilas sebelum main.
	# Panah dan J sebelumnya tidak pernah disebut di mana pun.
	_kontrol = UiKit.vbox(2)
	root.add_child(_kontrol)
	_kontrol.add_child(UiKit.kicker("KONTROL", UiKit.MUTED, 9))
	_kontrol.add_child(UiKit.label(
		"WASD / panah  jalan      ·      E  interaksi      ·      J  jurnal",
		12, UiKit.TEXT, WIDTH - 60))
	_kontrol.add_child(UiKit.label(
		"M  peta      ·      Esc  menu",
		12, UiKit.TEXT, WIDTH - 60))

	root.add_child(UiKit.rule())

	_resume = UiKit.primary_button("Lanjutkan", UiKit.ACCENT, 16)
	_resume.pressed.connect(_on_resume)
	root.add_child(_resume)

	_jurnal = UiKit.button("Jurnal Misi  [J]", 15, UiKit.BLUE)
	_jurnal.pressed.connect(func():
		visible = false
		open_journal.emit())
	root.add_child(_jurnal)

	_restart = UiKit.button("Ulangi Wilayah Ini", 15, UiKit.GOLD)
	_restart.pressed.connect(_on_restart)
	root.add_child(_restart)

	_menu = UiKit.button("Kembali ke Menu Utama", 15, UiKit.DANGER)
	_menu.pressed.connect(func():
		Game.save_game()
		visible = false
		to_title_requested.emit())
	root.add_child(_menu)

	_footer = UiKit.label(
		"Setelan suara dan kecepatan teks tersimpan bersama simpanan permainan.",
		12, UiKit.MUTED, WIDTH - 60)
	root.add_child(_footer)

var _last_value_label: Label

## Satu baris penggeser: judul, nilai, lalu slider. Nilai disimpan di
## `_last_value_label` supaya pemanggil bisa menyimpan rujukannya.
func _add_slider(parent: Control, judul: String, lo: float, hi: float,
		step: float, cb: Callable) -> HSlider:
	var box := UiKit.vbox(2)
	parent.add_child(box)
	var head := UiKit.hbox(8)
	box.add_child(head)
	head.add_child(UiKit.label(judul, 14, UiKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var val := UiKit.label("", 13, UiKit.MUTED)
	head.add_child(val)
	_last_value_label = val

	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.custom_minimum_size = Vector2(0, 24)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(cb)
	box.add_child(s)
	return s

func _db_percent(db: float) -> int:
	return int(round(pow(10.0, db / 20.0) * 100.0))

## Ujung kiri ditulis "Mati", bukan "0%", supaya jelas game benar-benar bisu.
func _vol_text(db: float) -> String:
	if db <= Game.SILENT_DB + 1.0:
		return "Mati"
	return "%d%%" % _db_percent(db)

func _on_bgm(v: float) -> void:
	Game.set_bgm_db(v)
	_bgm_v.text = _vol_text(Game.bgm_db)

func _on_sfx(v: float) -> void:
	Game.set_sfx_db(v)
	_sfx_v.text = _vol_text(Game.sfx_db)
	Game.sfx("sfx_click", -9.0)

func _on_speed(v: float) -> void:
	Game.set_text_speed(v)
	_speed_v.text = "%.1fx" % Game.text_speed

## Dipanggil main sebelum panel ditampilkan saat bermain.
func open(map_id: String) -> void:
	_map_id = map_id
	_settings_only = false
	visible = true
	_confirming = false
	_title.text = "JEDA"
	_map_label.visible = true
	_jurnal.visible = true
	_restart.visible = true
	_menu.visible = true
	_resume.text = "Lanjutkan"
	_kontrol.visible = true
	_footer.text = "Setelan suara dan kecepatan teks tersimpan di berkas setelan."
	var m := Content.map_by_id(map_id)
	_map_label.text = str(m.get("name", map_id)).to_upper()
	_restart.text = "Ulangi Wilayah Ini"
	_restart.add_theme_color_override("font_color", UiKit.TEXT)
	_sync()

## Mode pengaturan biasa (dibuka dari layar judul): hanya tiga penggeser dan
## tombol kembali. Tidak menjeda pohon scene karena di judul belum ada yang
## berjalan, dan tidak menyimpan progres — hanya berkas setelan.
func open_settings() -> void:
	_map_id = ""
	_settings_only = true
	visible = true
	_confirming = false
	_title.text = "PENGATURAN"
	_map_label.visible = false
	_jurnal.visible = false
	_restart.visible = false
	_menu.visible = false
	_resume.text = "Kembali"
	_kontrol.visible = false
	_footer.text = "Setelan berlaku untuk semua wilayah dan tersimpan otomatis."
	_sync()

func _sync() -> void:
	_bgm.set_value_no_signal(Game.bgm_db)
	_sfx.set_value_no_signal(Game.sfx_db)
	_speed.set_value_no_signal(Game.text_speed)
	_bgm_v.text = _vol_text(Game.bgm_db)
	_sfx_v.text = _vol_text(Game.sfx_db)
	_speed_v.text = "%.1fx" % Game.text_speed

## Esc menutup layar jeda. Ditangani di sini karena pohon scene sedang dijeda,
## sehingga main tidak lagi menerima masukan.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
		get_viewport().set_input_as_handled()

func _on_resume() -> void:
	visible = false
	if _settings_only:
		Game.save_settings()
		settings_closed.emit()
		return
	Game.save_settings()
	Game.save_game()
	resumed.emit()

## Dua kali tekan: yang pertama meminta penegasan, yang kedua benar-benar
## mengulang wilayah. Progres wilayah direset, tetapi uang/barang tetap.
func _on_restart() -> void:
	if not _confirming:
		_confirming = true
		_restart.text = "Yakin? Progres wilayah ini direset"
		_restart.add_theme_color_override("font_color", UiKit.DANGER)
		return
	visible = false
	_confirming = false
	restart_requested.emit(_map_id)
