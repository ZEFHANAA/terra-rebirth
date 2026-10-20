extends Control
## Panel toko pedagang di Kota Unggul. Menjual barang dengan Keping Data.

signal closed

const WIDTH := 620

var _coins: Label
var _list: VBoxContainer
var _note: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.075, 0.105, 0.16, 0.99), UiKit.BORDER, 14, 2))
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

	_coins = UiKit.label("Keping Data: 0", 14, UiKit.GOLD)
	root.add_child(_coins)

	root.add_child(UiKit.spacer(2))
	_list = UiKit.vbox(10)
	root.add_child(_list)

	_note = UiKit.label("", 13, UiKit.MUTED, WIDTH - 70)
	root.add_child(_note)

	Game.coins_changed.connect(func(_c: int): refresh())
	Game.items_changed.connect(refresh)

func open() -> void:
	visible = true
	_note.text = ""
	refresh()

func refresh() -> void:
	if _list == null:
		return
	_coins.text = "Keping Data: %d" % Game.coins
	for c in _list.get_children():
		c.queue_free()
	for id in Game.SHOP.keys():
		_list.add_child(_row(str(id), Game.SHOP[id]))

func _row(item_id: String, it: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.PANEL_2, UiKit.BORDER, 10, 2))
	var h := UiKit.hbox(14)
	box.add_child(h)

	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiKit.label(str(it["name"]), 16, UiKit.TEXT))
	info.add_child(UiKit.label(str(it["desc"]), 12, UiKit.MUTED, 330))
	info.add_child(UiKit.label("Dimiliki: %d" % Game.item_count(item_id), 12, UiKit.BLUE))

	var right := UiKit.vbox(6)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(right)
	right.add_child(UiKit.label("%d keping" % int(it["price"]), 14, UiKit.GOLD))

	var btn := UiKit.button("Beli", 14)
	btn.disabled = not Game.can_afford(item_id)
	btn.pressed.connect(func(): _buy(item_id))
	right.add_child(btn)
	return box

func _buy(item_id: String) -> void:
	if Game.buy_item(item_id):
		_note.text = "Kau membeli %s. Buka tantangan lalu tekan tombol Pakai Lensa." % str(Game.SHOP[item_id]["name"])
		_note.add_theme_color_override("font_color", UiKit.ACCENT)
	else:
		_note.text = "Keping data belum cukup. Selesaikan tantangan untuk mendapat 10 keping setiap kali."
		_note.add_theme_color_override("font_color", UiKit.DANGER)
	refresh()

func _on_close() -> void:
	visible = false
	closed.emit()
