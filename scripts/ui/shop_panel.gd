extends Control
## Panel toko pedagang di Kota Unggul. Menjual barang dengan uang (Bab II 2.5).

signal closed

const WIDTH := 620

var _coins: Label
var _list: VBoxContainer
var _note: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.03, 0.84)
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
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var root := UiKit.vbox(12)
	margin.add_child(root)

	var head := UiKit.hbox(12)
	root.add_child(head)
	head.add_child(UiKit.title("PEDAGANG KOTA", 15, UiKit.GOLD))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var close_btn := UiKit.button("Tutup", 13, UiKit.MUTED)
	close_btn.pressed.connect(_on_close)
	head.add_child(close_btn)

	_coins = UiKit.label("Uang: 0", 14, UiKit.GOLD)
	root.add_child(_coins)

	root.add_child(UiKit.spacer(2))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = UiKit.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_note = UiKit.label("", 13, UiKit.MUTED, WIDTH - 70)
	root.add_child(_note)

	Game.coins_changed.connect(func(_c: int): refresh())
	Game.items_changed.connect(refresh)

func open() -> void:
	visible = true
	_note.text = "Uang diperoleh dari setiap puzzle di Hutan, Pabrik, Candi, dan Danau — 10 uang per puzzle, sekali saja."
	_note.add_theme_color_override("font_color", UiKit.MUTED)
	refresh()

func refresh() -> void:
	if _list == null:
		return
	_coins.text = "Uang: %d" % Game.coins
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(UiKit.label("KOMPONEN PERANGKAT PEMANTAU AIR — WAJIB UNTUK MAP 5", 11, UiKit.MUTED, WIDTH - 70))
	for id in Game.COMPONENT_IDS:
		_list.add_child(_row(str(id), Game.SHOP[id]))
	_list.add_child(UiKit.label("ITEM BANTU", 11, UiKit.MUTED, WIDTH - 70))
	for id in Game.SHOP.keys():
		if Game.is_component_item(str(id)):
			continue
		_list.add_child(_row(str(id), Game.SHOP[id]))

func _row(item_id: String, it: Dictionary) -> Control:
	var box := PanelContainer.new()
	var sb := UiKit.panel_style(UiKit.PANEL_2, UiKit.BORDER, 10, 2, false)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	box.add_theme_stylebox_override("panel", sb)
	var h := UiKit.hbox(12)
	box.add_child(h)

	var komponen := Game.is_component_item(item_id)
	var dimiliki := komponen and Game.has_component(item_id)

	var info := UiKit.vbox(0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiKit.label(str(it["name"]) + ("  (dimiliki)" if dimiliki else ""),
		13, UiKit.ACCENT if dimiliki else UiKit.TEXT))
	var ket := str(it["desc"])
	if not komponen:
		ket += " · dimiliki: %d" % Game.item_count(item_id)
	info.add_child(UiKit.label(ket, 10, UiKit.MUTED, 430))

	var right := UiKit.vbox(2)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(right)
	right.add_child(UiKit.label("%d uang" % int(it["price"]), 13, UiKit.GOLD))

	var btn := UiKit.small_button("Dimiliki" if dimiliki else "Beli", 12)
	btn.custom_minimum_size.x = 92
	btn.disabled = dimiliki or not Game.can_afford(item_id)
	btn.pressed.connect(func(): _buy(item_id))
	right.add_child(btn)
	return box

func _buy(item_id: String) -> void:
	var it: Dictionary = Game.SHOP[item_id]
	if Game.buy_item(item_id):
		Game.sfx("sfx_coin")
		if Game.is_component_item(item_id):
			_note.text = "%s dibeli. Komponen perangkat: %d/%d." % [
				str(it["name"]), Game.component_count(), Game.COMPONENT_TOTAL]
		else:
			_note.text = "Kamu membeli %s. Buka tantangan lalu tekan tombol Pakai Lensa." % str(it["name"])
		_note.add_theme_color_override("font_color", UiKit.ACCENT)
	else:
		Game.sfx("sfx_err")
		if Game.coins < int(it["price"]):
			_note.text = "Uang belum cukup. Setiap puzzle di Hutan, Pabrik, Candi, dan Danau memberi 10 uang."
		else:
			_note.text = "Uangmu disisakan untuk komponen perangkat. Beli komponen yang belum dimiliki lebih dahulu."
		_note.add_theme_color_override("font_color", UiKit.DANGER)
	refresh()

func _on_close() -> void:
	visible = false
	closed.emit()
