extends Control
## Layar peta wilayah: 6 kartu dengan status kunci.

signal map_chosen(map_id: String)
signal back_pressed

var _grid: GridContainer
var _info: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var v := UiKit.vbox(12)
	margin.add_child(v)

	var head := UiKit.hbox(16)
	v.add_child(head)
	var hcol := UiKit.vbox(2)
	head.add_child(hcol)
	hcol.add_child(UiKit.kicker("PETA WILAYAH", UiKit.GOLD, 10))
	hcol.add_child(UiKit.title("ENAM WILAYAH TERRA", 20, UiKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_info = UiKit.label("", 15, UiKit.MUTED)
	head.add_child(_info)
	var back := UiKit.button("Kembali  [Esc]", 14, UiKit.MUTED)
	back.pressed.connect(func(): back_pressed.emit())
	head.add_child(back)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_grid)

func refresh() -> void:
	_info.text = "%d/%d tantangan  ·  %d/%d badge" % [Game.total_done(), Content.total_challenges(), Game.badges.size(), Content.badge_total()]
	for c in _grid.get_children():
		c.queue_free()
	for i in range(Content.MAPS.size()):
		_grid.add_child(_card(Content.MAPS[i], i))

func _card(m: Dictionary, idx: int) -> Control:
	var unlocked := Game.map_unlocked(str(m["id"]))
	var cleared := Game.is_map_cleared(str(m["id"]))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(348, 0)
	panel.clip_contents = true
	var border := UiKit.BORDER
	if cleared:
		border = UiKit.ACCENT
	elif unlocked:
		border = UiKit.GOLD
	var sb := UiKit.panel_style(Color(0.08, 0.11, 0.16, 1.0), border, 12, 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var v := UiKit.vbox(8)
	panel.add_child(v)

	# Potongan peta sebagai gambar kartu.
	var thumb := TextureRect.new()
	var tp := "res://assets/maps/thumb_%s.png" % str(m["id"])
	if not ResourceLoader.exists(tp):
		tp = "res://assets/maps/%s.png" % str(m["id"])
	if ResourceLoader.exists(tp):
		thumb.texture = load(tp)
	thumb.custom_minimum_size = Vector2(0, 54)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	thumb.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.6, 0.68, 1)
	v.add_child(thumb)

	var top := UiKit.hbox(10)
	v.add_child(top)
	var num := UiKit.title("%02d" % (idx + 1), 13, UiKit.MUTED)
	top.add_child(num)
	var name_lbl := UiKit.title(str(m["name"]).to_upper(), 12, UiKit.TEXT if unlocked else UiKit.MUTED)
	top.add_child(name_lbl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	if str(m.get("badge", "")) != "":
		var ic := TextureRect.new()
		ic.texture = load("res://assets/ui/badge_%s.png" % str(m["badge"]))
		ic.custom_minimum_size = Vector2(26, 26)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.modulate = Color(1, 1, 1, 1) if Game.has_badge(str(m["badge"])) else Color(1, 1, 1, 0.18)
		top.add_child(ic)

	var mat := UiKit.label(str(m["material"]), 14, UiKit.ACCENT if unlocked else UiKit.MUTED)
	v.add_child(mat)

	var desc := UiKit.label(str(m["desc"]), 13, UiKit.TEXT if unlocked else UiKit.MUTED, 300)
	v.add_child(desc)

	var prog := UiKit.label("%d / %d tantangan" % [Game.map_done(str(m["id"])), Game.map_total(str(m["id"]))], 13, UiKit.MUTED)
	v.add_child(prog)

	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp2)

	var btn := UiKit.primary_button("Masuk  ▸" if unlocked else "Terkunci", UiKit.ACCENT if unlocked else UiKit.PANEL_3, 15)
	btn.custom_minimum_size = Vector2(0, 40)
	if unlocked:
		btn.pressed.connect(func(): map_chosen.emit(str(m["id"])))
	else:
		btn.text = "Terkunci  ·  " + Game.unlock_hint(str(m["id"]))
		btn.disabled = true
	v.add_child(btn)
	return panel
