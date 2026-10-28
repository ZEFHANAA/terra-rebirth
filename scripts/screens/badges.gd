extends Control
## Koleksi badge: daftar empat badge, asal wilayahnya, syaratnya, dan status.
##
## HUD hanya menulis "BADGE 0/4" tanpa keterangan; layar ini menjawab pertanyaan
## "badge apa saja yang ada dan bagaimana mendapatkannya". Datanya diambil dari
## `Content.MAPS` (badge, badge_name, nama wilayah, jumlah tantangan) dan
## `Game.badges` (yang sudah didapat). Layar ini tidak mengubah progres apa pun.

signal closed
signal open_journal

const ICON := {
	"nature": "res://assets/ui/badge_nature.png",
	"core": "res://assets/ui/badge_core.png",
	"cipher": "res://assets/ui/badge_cipher.png",
	"aqua": "res://assets/ui/badge_aqua.png",
}
const ORDER := ["nature", "core", "cipher", "aqua"]
const CARD_W := 470

var _grid: GridContainer
var _count: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var bg := ColorRect.new()
	bg.color = Color("081310")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var leaves := TextureRect.new()
	if ResourceLoader.exists("res://assets/ui/bg_leaves.png"):
		leaves.texture = load("res://assets/ui/bg_leaves.png")
	leaves.stretch_mode = TextureRect.STRETCH_TILE
	leaves.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leaves.modulate = Color(1, 1, 1, 0.45)
	leaves.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leaves)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := UiKit.vbox(14)
	margin.add_child(root)

	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UiKit.ribbon_style())
	root.add_child(band)
	var head := UiKit.hbox(16)
	band.add_child(head)
	var hcol := UiKit.vbox(2)
	head.add_child(hcol)
	hcol.add_child(UiKit.kicker("KOLEKSI BADGE", UiKit.GOLD, 10))
	hcol.add_child(UiKit.title("EMPAT KUNCI TERRA", 20, UiKit.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_count = UiKit.label("", 15, UiKit.MUTED)
	head.add_child(_count)
	var back := UiKit.button("Tutup  [Esc]", 14, UiKit.MUTED)
	back.pressed.connect(_on_close)
	head.add_child(back)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 14)
	root.add_child(_grid)

	root.add_child(UiKit.label(
		"Badge diberikan setelah seluruh tantangan satu wilayah selesai. "
		+ "Badge hanya penanda kemajuan — tidak menambah kemampuan bertarung.",
		13, UiKit.MUTED, 980))

## Dipanggil main sebelum layar ditampilkan.
func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_count.text = "%d / %d didapat" % [Game.badges.size(), ORDER.size()]
	for id in ORDER:
		_grid.add_child(_card(id))

## Satu kartu badge. Wilayah dicari lewat `badge` di data peta, jadi menambah
## badge baru cukup menambah satu baris di `Content.MAPS`.
func _card(id: String) -> Control:
	var map := {}
	for raw in Content.MAPS:
		if str(raw.get("badge", "")) == id:
			map = raw
			break
	var milik := Game.badges.has(id)
	var nama := str(map.get("badge_name", id))
	var wilayah := str(map.get("name", "—"))
	# Jumlah tantangan diambil dari `Game.map_total` karena data peta hanya
	# memuat tantangan tetap; slot bank soal dan puzzle ditambahkan di runtime.
	var total := Game.map_total(str(map.get("id", "")))
	var selesai := Game.map_done(str(map.get("id", "")))

	var row := UiKit.hbox(14)
	var icon := TextureRect.new()
	if ResourceLoader.exists(str(ICON.get(id, ""))):
		icon.texture = load(str(ICON.get(id, "")))
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.modulate = Color(1, 1, 1, 1) if milik else Color(1, 1, 1, 0.28)
	row.add_child(icon)

	var col := UiKit.vbox(3)
	col.custom_minimum_size.x = CARD_W - 100
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(UiKit.title(nama.to_upper(), 13, UiKit.GOLD if milik else UiKit.MUTED))
	# Pemisah memakai garis, bukan titik tengah: pada ukuran 9 px titik tengah
	# terbaca seperti tanda titik biasa.
	col.add_child(UiKit.kicker("%s  —  %d tantangan" % [wilayah.to_upper(), total], UiKit.MUTED, 9))
	var syarat := ("Sudah dikumpulkan." if milik
		else "Selesaikan %d/%d tantangan %s." % [selesai, total, wilayah])
	col.add_child(UiKit.label(syarat, 13, UiKit.TEXT if milik else UiKit.MUTED, CARD_W - 110))

	var kartu := UiKit.card(row, UiKit.ACCENT if milik else Color(0, 0, 0, 0))
	kartu.custom_minimum_size.x = CARD_W
	return kartu

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()

func _on_close() -> void:
	visible = false
	closed.emit()
