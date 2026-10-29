extends Control
## Layar judul.

signal new_game
signal continue_game
signal open_maps
signal open_research
signal open_settings

var start_btn: Button

const VERSION_TAG := "v0.7"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/title_bg.png")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.09, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	# Panel gelap di kiri supaya teks selalu terbaca di atas ilustrasi apa pun.
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([
		Color(0.035, 0.05, 0.08, 0.97),
		Color(0.035, 0.05, 0.08, 0.86),
		Color(0.035, 0.05, 0.08, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.42, 0.72])
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	grad.texture = gt
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grad)

	# Vignette halus di tepi atas dan bawah.
	for top in [true, false]:
		var v := TextureRect.new()
		var vt := GradientTexture2D.new()
		var vg := Gradient.new()
		vg.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0)])
		vg.offsets = PackedFloat32Array([0.0, 1.0])
		vt.gradient = vg
		vt.fill_from = Vector2(0.5, 0.0 if top else 1.0)
		vt.fill_to = Vector2(0.5, 1.0 if top else 0.0)
		v.texture = vt
		if top:
			v.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			v.offset_bottom = 150
		else:
			v.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			v.offset_top = -150
		add_child(v)

	# ------------------------------------------------------------- kolom kiri
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	box.offset_left = 104
	box.offset_top = 128
	box.custom_minimum_size.x = 600
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var tag_row := UiKit.hbox(10)
	box.add_child(tag_row)
	tag_row.add_child(UiKit.chip("GAME EDUKASI", UiKit.ACCENT, Color(0.31, 0.82, 0.65, 0.10)))

	box.add_child(UiKit.spacer(6))
	box.add_child(UiKit.title("TERRA", 52, Color.WHITE))
	box.add_child(UiKit.title("REBIRTH", 52, UiKit.ACCENT))

	box.add_child(UiKit.body("Enam wilayah, empat materi informatika, satu Terra yang harus dipulihkan.", 19, UiKit.TEXT, 540))

	var rule := ColorRect.new()
	rule.color = Color(1, 1, 1, 0.12)
	rule.custom_minimum_size = Vector2(84, 2)
	box.add_child(rule)
	box.add_child(UiKit.spacer(8))

	var b1 := UiKit.primary_button("Mulai Perjalanan", UiKit.GOLD, 19)
	start_btn = b1
	b1.custom_minimum_size = Vector2(340, 54)
	b1.pressed.connect(func(): new_game.emit())
	box.add_child(b1)

	var b2 := UiKit.button("Lanjutkan", 18)
	b2.custom_minimum_size = Vector2(340, 48)
	b2.disabled = not Game.has_save()
	b2.pressed.connect(func(): continue_game.emit())
	box.add_child(b2)

	box.add_child(UiKit.spacer(4))
	# Dulu "Peta Wilayah" berbagi baris dengan "Mode Riset". Sekarang sendirian,
	# jadi dimasukkan langsung ke kolom supaya lebarnya sama dengan tombol lain.
	var b3 := UiKit.button("Peta Wilayah", 15)
	b3.custom_minimum_size = Vector2(340, 44)
	b3.pressed.connect(func(): open_maps.emit())
	box.add_child(b3)

	# Pengaturan suara juga bisa dibuka sebelum bermain, supaya pemain tidak
	# harus masuk ke peta dulu hanya untuk mengecilkan musik.
	var b5 := UiKit.button("Pengaturan", 15, UiKit.MUTED)
	b5.custom_minimum_size = Vector2(340, 44)
	b5.pressed.connect(func(): open_settings.emit())
	box.add_child(b5)

	# ------------------------------------------------------------- pahlawan
	var glow := TextureRect.new()
	var gt2 := GradientTexture2D.new()
	var g2 := Gradient.new()
	g2.colors = PackedColorArray([Color(0.31, 0.82, 0.65, 0.22), Color(0.31, 0.82, 0.65, 0.0)])
	g2.offsets = PackedFloat32Array([0.0, 1.0])
	gt2.gradient = g2
	gt2.fill = GradientTexture2D.FILL_RADIAL
	gt2.fill_from = Vector2(0.5, 0.5)
	gt2.fill_to = Vector2(0.5, 0.0)
	gt2.width = 512
	gt2.height = 512
	glow.texture = gt2
	glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Tepi kanan dijaga di dalam layar (1280) supaya tidak ada elemen keluar jendela.
	glow.offset_left = 128
	glow.offset_right = 640
	glow.offset_top = -300
	glow.offset_bottom = 212
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(glow)

	# Bayangan kontak di bawah karakter.
	var shadow := TextureRect.new()
	var st := GradientTexture2D.new()
	var sg := Gradient.new()
	sg.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0)])
	sg.offsets = PackedFloat32Array([0.0, 1.0])
	st.gradient = sg
	st.fill = GradientTexture2D.FILL_RADIAL
	st.fill_from = Vector2(0.5, 0.5)
	st.fill_to = Vector2(1.0, 0.5)
	st.width = 256
	st.height = 64
	shadow.texture = st
	shadow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shadow.offset_left = 268
	shadow.offset_right = 492
	shadow.offset_top = 124
	shadow.offset_bottom = 158
	add_child(shadow)

	var hero_tex: Texture2D = load("res://assets/sprites/mc/portrait.png")
	var hero := TextureRect.new()
	hero.texture = hero_tex
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hero.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hero.offset_left = 205
	hero.offset_right = 555
	hero.offset_top = -158
	hero.offset_bottom = 138
	add_child(hero)

	# ------------------------------------------------------------- deretan badge
	var brow := UiKit.hbox(12)
	brow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	brow.offset_left = 168
	brow.offset_right = 592
	brow.offset_top = 178
	brow.offset_bottom = 222
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(brow)
	for b in ["nature", "core", "cipher", "aqua"]:
		var ic := TextureRect.new()
		ic.texture = load("res://assets/ui/badge_%s.png" % b)
		ic.custom_minimum_size = Vector2(36, 36)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.modulate = Color(1, 1, 1, 0.45)
		brow.add_child(ic)

	# ------------------------------------------------------------- kaki layar
	# Identitas kelompok dan daftar tombol tidak lagi ditulis di judul: judul
	# tinggal judul, tombol, dan nomor versi kecil di pojok.
	var foot := UiKit.label(VERSION_TAG, 12, Color(0.62, 0.70, 0.80, 0.55))
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	foot.offset_left = 104
	foot.offset_top = -44
	add_child(foot)
