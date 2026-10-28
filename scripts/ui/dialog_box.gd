extends Control
## Kotak dialog NPC dengan efek mengetik.

signal finished

var _lines: Array = []
var _idx := 0
var _reveal := 0.0
var _typing := false
var _total := 0

var _name: Label
var _role: Label
var _text: RichTextLabel
var _hint: Label
var _panel: PanelContainer
var _portrait: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var bottom := MarginContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -216
	bottom.offset_left = 64
	bottom.offset_right = -64
	bottom.offset_bottom = -30
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.frame_style(26, 20))
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.add_child(_panel)

	var row := UiKit.hbox(16)
	_panel.add_child(row)

	# Potret NPC di sisi kiri.
	var portrait_box := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("0f1d14")
	psb.border_color = Color("6f9a4a")
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(2)
	psb.content_margin_left = 10
	psb.content_margin_right = 10
	psb.content_margin_top = 10
	psb.content_margin_bottom = 10
	portrait_box.add_theme_stylebox_override("panel", psb)
	row.add_child(portrait_box)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.custom_minimum_size = Vector2(112, 158)
	portrait_box.add_child(_portrait)

	# Kolom teks.
	var v := UiKit.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)

	var head := UiKit.hbox(10)
	v.add_child(head)
	_name = UiKit.title("", 12, UiKit.GOLD)
	head.add_child(_name)
	_role = UiKit.label("", 14, UiKit.MUTED)
	head.add_child(_role)
	head.add_child(UiKit.expander())

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.custom_minimum_size.y = 96
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 19)
	_text.add_theme_constant_override("line_separation", 6)
	_text.add_theme_color_override("default_color", UiKit.TEXT)
	v.add_child(_text)

	_hint = UiKit.label("", 13, UiKit.MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_hint)


func open(npc_name: String, role: String, lines: Array, sprite_key: String = "") -> void:
	_lines = lines
	_idx = 0
	_name.text = npc_name.to_upper()
	_role.text = "· " + role
	_set_portrait(sprite_key)
	visible = true
	_show_line()


func _set_portrait(sprite_key: String) -> void:
	var path := "res://assets/sprites/mc/portrait.png"
	if sprite_key != "":
		path = "res://assets/sprites/npc_%s.png" % sprite_key
	if not ResourceLoader.exists(path):
		path = "res://assets/sprites/mc/portrait.png"
	var tex: Texture2D = load(path)
	if path.ends_with("portrait.png"):
		# Potret MC berupa satu gambar utuh (bukan spritesheet).
		_portrait.texture = tex
		return
	# Ambil SATU frame dari sheet, bukan seluruh sheet. Sheet hero 384x576
	# (frame 96x144); sheet NPC baru 72x128 (3 kolom x 4 baris, frame 24x32).
	var fw := 96.0
	var fh := 144.0
	if tex.get_width() < 384:
		fw = float(tex.get_width()) / 3.0
		fh = float(tex.get_height()) / 4.0
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(0, 0, fw, fh)
	_portrait.texture = at


func _show_line() -> void:
	if _idx >= _lines.size():
		_close()
		return
	var txt: String = str(_lines[_idx])
	_text.text = txt
	_text.visible_characters = 0
	_total = txt.length()
	_reveal = 0.0
	_typing = true
	_hint.text = ""


func _process(delta: float) -> void:
	if not visible or not _typing:
		return
	_reveal += delta * 62.0
	_text.visible_characters = int(_reveal)
	if _reveal >= _total:
		_typing = false
		_text.visible_characters = -1
		_hint.text = "[E] lanjut  ▸"


func is_typing() -> bool:
	return _typing


func advance() -> void:
	if not visible:
		return
	Game.sfx("sfx_click", -11.0)
	if _typing:
		_typing = false
		_text.visible_characters = -1
		_hint.text = "[E] lanjut  ▸"
		return
	_idx += 1
	_show_line()


func _close() -> void:
	visible = false
	finished.emit()
