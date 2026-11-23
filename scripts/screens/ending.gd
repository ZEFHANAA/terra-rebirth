extends Control
## Layar penutup setelah semua wilayah selesai.

signal open_maps
signal open_research
signal back_to_title

var _v: VBoxContainer
var _stats: HBoxContainer
var _title: Label
var _sub: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/maps/source.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.5, 0.55, 0.7)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_v = UiKit.vbox(14)
	center.add_child(_v)

	_title = UiKit.title("TERRA PULIH", 40, UiKit.ACCENT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v.add_child(_title)

	_sub = UiKit.label("Data tersusun, mesin berjalan, sandi terbaca, dan danau kembali terpantau.", 18, UiKit.TEXT, 700)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v.add_child(_sub)
	_v.add_child(UiKit.spacer(10))

	_stats = UiKit.hbox(28)
	_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	_v.add_child(_stats)

	_v.add_child(UiKit.spacer(16))

	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_v.add_child(row)
	var b1 := UiKit.button("Data Peserta", 15, UiKit.GOLD)
	b1.pressed.connect(func(): open_research.emit())
	row.add_child(b1)
	var b2 := UiKit.button("Peta Wilayah", 15)
	b2.pressed.connect(func(): open_maps.emit())
	row.add_child(b2)
	var b3 := UiKit.button("Menu Utama", 15, UiKit.MUTED)
	b3.pressed.connect(func(): back_to_title.emit())
	row.add_child(b3)

	refresh()

func refresh() -> void:
	if _stats == null:
		return
	# Teks ending mengikuti keputusan pemain di The Source.
	if Game.ending_choice == "seal":
		_title.text = "SUMBER DISEGEL"
		_title.add_theme_color_override("font_color", UiKit.GOLD)
		_sub.text = "Kamu memutus aliran data dan menyegel sumber. Kerusakan berhenti, tetapi danau tidak lagi terpantau: tidak ada data yang mengalir untuk memastikan airnya benar-benar pulih."
	elif Game.ending_choice == "flow":
		_title.text = "TERRA PULIH"
		_title.add_theme_color_override("font_color", UiKit.ACCENT)
		_sub.text = "Kamu menyusun ulang protokol dan membiarkan data kembali mengalir. Mesin berjalan, sandi terbaca, dan danau terus terpantau oleh perangkat yang kamu rakit sendiri."
	else:
		_title.text = "TERRA PULIH"
		_sub.text = "Data tersusun, mesin berjalan, sandi terbaca, dan danau kembali terpantau."
	for c in _stats.get_children():
		c.queue_free()
	var res := Game.posttest_result()
	var nilai := "—"
	if not res.is_empty():
		nilai = str(int(res.get("nilai", 0)))
	var sus := "—"
	if Game.sus_done:
		sus = "%.0f" % Game.sus_value()
	var pairs := [
		["TANTANGAN", "%d/%d" % [Game.total_done(), Content.total_challenges()]],
		["BADGE", "%d/%d" % [Game.badges.size(), Content.badge_total()]],
		["NILAI POST-TEST", nilai],
		["SKOR SUS", sus],
	]
	for pair in pairs:
		var col := UiKit.vbox(4)
		var val := UiKit.title(pair[1], 22, UiKit.GOLD)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(val)
		var lab := UiKit.label(pair[0], 12, UiKit.MUTED)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lab)
		_stats.add_child(col)
