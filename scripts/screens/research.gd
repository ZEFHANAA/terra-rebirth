extends Control
## Mode riset: pre-test, post-test, kuesioner SUS, dan rekap data.

signal back_pressed

const TABS := ["Pre-Test", "Post-Test", "SUS", "Rekap"]

var _tab := 0
var _tab_row: HBoxContainer
var _content: MarginContainer
var _code_edit: LineEdit
var _answers: Dictionary = {"pre": [], "post": []}
var _sus: Array = []
var _result: Dictionary = {"pre": -1, "post": -1, "sus": -1.0}
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var v := UiKit.vbox(14)
	margin.add_child(v)

	var head := UiKit.hbox(14)
	v.add_child(head)
	head.add_child(UiKit.title("MODE RISET", 20, UiKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UiKit.label("Kode peserta", 14, UiKit.MUTED))
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "mis. P01"
	_code_edit.text = Game.player_code
	_code_edit.custom_minimum_size = Vector2(130, 36)
	_code_edit.add_theme_font_size_override("font_size", 15)
	head.add_child(_code_edit)
	var back := UiKit.button("Kembali  [Esc]", 14, UiKit.MUTED)
	back.pressed.connect(func(): back_pressed.emit())
	head.add_child(back)

	_tab_row = UiKit.hbox(8)
	v.add_child(_tab_row)
	for i in range(TABS.size()):
		var b := UiKit.button(TABS[i], 15)
		var idx := i
		b.pressed.connect(func(): _set_tab(idx))
		_tab_row.add_child(b)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.07, 0.1, 0.15, 1.0), UiKit.BORDER, 12, 2))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(panel)

	_content = MarginContainer.new()
	_content.add_theme_constant_override("margin_left", 22)
	_content.add_theme_constant_override("margin_right", 22)
	_content.add_theme_constant_override("margin_top", 16)
	_content.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(_content)

	_status = UiKit.label("", 14, UiKit.ACCENT)
	v.add_child(_status)

	_answers["pre"] = _empty(Content.TEST_ITEMS.size())
	_answers["post"] = _empty(Content.TEST_ITEMS.size())
	_sus = _empty(Content.SUS_ITEMS.size())
	_set_tab(0)

func _empty(n: int) -> Array:
	var a: Array = []
	for i in range(n):
		a.append(-1)
	return a

func _set_tab(i: int) -> void:
	_tab = i
	for k in range(_tab_row.get_child_count()):
		var b: Button = _tab_row.get_child(k)
		b.add_theme_stylebox_override("normal", UiKit.panel_style(
			UiKit.PANEL_2.lightened(0.1) if k == i else UiKit.PANEL_2,
			UiKit.ACCENT if k == i else UiKit.BORDER, 8, 2))
	_render()

func _clear() -> void:
	for c in _content.get_children():
		c.queue_free()

func _render() -> void:
	_clear()
	match _tab:
		0:
			_test_form("pre", "Pre-Test", "Kerjakan sebelum memainkan game. 8 soal, 2 soal per bidang.")
		1:
			_test_form("post", "Post-Test", "Kerjakan setelah menyelesaikan seluruh wilayah.")
		2:
			_sus_form()
		3:
			_rekap()

func _test_form(key: String, title: String, desc: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var v := UiKit.vbox(14)
	v.custom_minimum_size.x = 1080
	scroll.add_child(v)

	v.add_child(UiKit.title(title.to_upper(), 14, UiKit.GOLD))
	v.add_child(UiKit.label(desc, 15, UiKit.MUTED, 1040))

	for qi in range(Content.TEST_ITEMS.size()):
		var item: Dictionary = Content.TEST_ITEMS[qi]
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.05, 0.07, 0.11, 1.0), UiKit.BORDER, 8, 1))
		v.add_child(box)
		var bv := UiKit.vbox(6)
		box.add_child(bv)
		bv.add_child(UiKit.label("%d. %s" % [qi + 1, str(item["q"])], 15, UiKit.TEXT, 1000))
		var group := ButtonGroup.new()
		for oi in range((item["o"] as Array).size()):
			var rb := CheckBox.new()
			rb.text = str(item["o"][oi])
			rb.button_group = group
			rb.add_theme_font_size_override("font_size", 14)
			rb.button_pressed = _answers[key][qi] == oi
			var qidx := qi
			var oidx := oi
			rb.toggled.connect(func(on: bool):
				if on:
					_answers[key][qidx] = oidx
			)
			bv.add_child(rb)

	var submit := UiKit.button("Kumpulkan %s" % title, 16)
	submit.pressed.connect(func(): _submit_test(key))
	v.add_child(submit)

func _submit_test(key: String) -> void:
	var ans: Array = _answers[key]
	for i in range(ans.size()):
		if int(ans[i]) < 0:
			_status.text = "Masih ada soal yang belum dijawab."
			_status.add_theme_color_override("font_color", UiKit.DANGER)
			return
	var correct := 0
	for i in range(ans.size()):
		if int(ans[i]) == int(Content.TEST_ITEMS[i]["a"]):
			correct += 1
	var score := int(round(float(correct) / float(ans.size()) * 100.0))
	_result[key] = score
	_status.add_theme_color_override("font_color", UiKit.ACCENT)
	_status.text = "%s selesai: %d/%d benar (nilai %d)." % [key.capitalize(), correct, ans.size(), score]
	_persist()

func _sus_form() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var v := UiKit.vbox(10)
	v.custom_minimum_size.x = 1080
	scroll.add_child(v)
	v.add_child(UiKit.title("SYSTEM USABILITY SCALE", 14, UiKit.GOLD))
	v.add_child(UiKit.label("1 = sangat tidak setuju · 5 = sangat setuju", 14, UiKit.MUTED))

	for i in range(Content.SUS_ITEMS.size()):
		var row := UiKit.hbox(12)
		v.add_child(row)
		var q := UiKit.label("%d. %s" % [i + 1, str(Content.SUS_ITEMS[i])], 15, UiKit.TEXT, 720)
		row.add_child(q)
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
		var group := ButtonGroup.new()
		for s in range(1, 6):
			var b := Button.new()
			b.text = str(s)
			b.toggle_mode = true
			b.button_group = group
			b.custom_minimum_size = Vector2(44, 36)
			b.add_theme_font_size_override("font_size", 14)
			b.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.PANEL_2, UiKit.BORDER, 6, 1))
			b.add_theme_stylebox_override("pressed", UiKit.panel_style(Color(0.1, 0.3, 0.24), UiKit.ACCENT, 6, 2))
			b.add_theme_stylebox_override("hover", UiKit.panel_style(UiKit.PANEL_2.lightened(0.1), UiKit.ACCENT, 6, 1))
			b.button_pressed = _sus[i] == s
			var qi := i
			var sv := s
			b.toggled.connect(func(on: bool):
				if on:
					_sus[qi] = sv
			)
			row.add_child(b)

	var submit := UiKit.button("Kumpulkan SUS", 16)
	submit.pressed.connect(_submit_sus)
	v.add_child(submit)

func _submit_sus() -> void:
	for v in _sus:
		if int(v) < 0:
			_status.text = "Masih ada pernyataan yang belum dinilai."
			_status.add_theme_color_override("font_color", UiKit.DANGER)
			return
	var total := 0.0
	for i in range(_sus.size()):
		var val := int(_sus[i])
		if i % 2 == 0:
			total += float(val - 1)
		else:
			total += float(5 - val)
	var score := total * 2.5
	_result["sus"] = score
	_status.add_theme_color_override("font_color", UiKit.ACCENT)
	_status.text = "Skor SUS: %.1f dari 100." % score
	_persist()

func _persist() -> void:
	Game.player_code = _code_edit.text.strip_edges()
	if Game.player_code == "":
		_status.text = "Isi kode peserta terlebih dahulu agar data tersimpan."
		_status.add_theme_color_override("font_color", UiKit.DANGER)
		return
	var pre := int(_result["pre"])
	var post := int(_result["post"])
	var ngain := 0.0
	if pre >= 0 and post >= 0:
		ngain = float(post - pre) / max(1.0, 100.0 - float(pre))
	var rec := {
		"kode": Game.player_code,
		"waktu": Time.get_datetime_string_from_system(),
		"pre": pre, "post": post,
		"ngain": snappedf(ngain, 0.01),
		"sus": float(_result["sus"]),
		"xp": Game.xp,
		"selesai": Game.total_done()
	}
	Game.upsert_record(Game.player_code, rec)
	Game.save_game()

func _rekap() -> void:
	var v := UiKit.vbox(12)
	_content.add_child(v)
	v.add_child(UiKit.title("REKAP DATA PESERTA", 14, UiKit.GOLD))
	var recs := Game.read_records()
	v.add_child(UiKit.label("%d peserta tercatat. Data tersimpan di %s" % [recs.size(), ProjectSettings.globalize_path(Game.RECORD_PATH)], 14, UiKit.MUTED, 1040))

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for h in ["Kode", "Pre", "Post", "N-gain", "SUS", "XP"]:
		grid.add_child(UiKit.label(h, 14, UiKit.ACCENT))
	for r in recs:
		grid.add_child(UiKit.label(str(r.get("kode", "-")), 14, UiKit.TEXT))
		grid.add_child(UiKit.label(str(r.get("pre", "-")), 14, UiKit.TEXT))
		grid.add_child(UiKit.label(str(r.get("post", "-")), 14, UiKit.TEXT))
		grid.add_child(UiKit.label("%.2f" % float(r.get("ngain", 0)), 14, UiKit.TEXT))
		grid.add_child(UiKit.label("%.1f" % float(r.get("sus", 0)), 14, UiKit.TEXT))
		grid.add_child(UiKit.label(str(r.get("xp", 0)), 14, UiKit.TEXT))

	var btn := UiKit.button("Ekspor CSV", 15)
	btn.pressed.connect(func():
		var path := "user://terra_rekap.csv"
		if Game.export_csv(path):
			_status.add_theme_color_override("font_color", UiKit.ACCENT)
			_status.text = "CSV tersimpan: " + ProjectSettings.globalize_path(path)
		else:
			_status.text = "Belum ada data untuk diekspor."
	)
	v.add_child(btn)
