extends Control
## Layar peta wilayah: 6 kartu dengan status kunci.

signal map_chosen(map_id: String)
signal back_pressed

var _grid: GridContainer
var _info: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("081310")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Ubin dedaunan samar supaya latar tidak terasa kotak polos.
	var leaves := TextureRect.new()
	if ResourceLoader.exists("res://assets/ui/bg_leaves.png"):
		leaves.texture = load("res://assets/ui/bg_leaves.png")
	leaves.stretch_mode = TextureRect.STRETCH_TILE
	leaves.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leaves.modulate = Color(1, 1, 1, 0.55)
	leaves.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leaves)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var v := UiKit.vbox(12)
	margin.add_child(v)

	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UiKit.ribbon_style())
	v.add_child(band)
	var head := UiKit.hbox(16)
	band.add_child(head)
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
	# Kartu seperti catatan kertas yang dipaku di papan peta.
	if unlocked:
		panel.add_theme_stylebox_override("panel", UiKit.parchment_style(16, 12))
	else:
		panel.add_theme_stylebox_override("panel",
			UiKit.panel_style(Color("b7ab8c"), Color("6d5c42"), 2, 2, false))

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
	var name_lbl := UiKit.title(str(m["name"]).to_upper(), 13, UiKit.INK if unlocked else Color("4c4030"))
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

	var mat := UiKit.label(str(m["material"]), 14, Color("3d6b28") if unlocked else Color("5d5138"))
	v.add_child(mat)

	var desc := UiKit.label(str(m["desc"]), 13, Color("4a3a22") if unlocked else Color("5d5138"), 300)
	v.add_child(desc)

	var prog := UiKit.label("%d / %d tantangan" % [Game.map_done(str(m["id"])), Game.map_total(str(m["id"]))], 13, Color("6b5a3c") if unlocked else Color("5d5138"))
	v.add_child(prog)

	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp2)

	var btn := UiKit.primary_button("Masuk  ▸" if unlocked else "Terkunci", UiKit.ACCENT, 15)
	btn.custom_minimum_size = Vector2(0, 40)
	if unlocked:
		btn.pressed.connect(func(): map_chosen.emit(str(m["id"])))
	else:
		btn.text = "Terkunci  ·  " + Game.unlock_hint(str(m["id"]))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.tex_style("res://assets/ui/btn_wood_press.png", 18))
		btn.add_theme_color_override("font_disabled_color", Color("d9cdb2"))
	v.add_child(btn)
	return panel
