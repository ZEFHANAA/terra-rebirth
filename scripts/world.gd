extends Node2D
## Membangun satu peta: latar, tabrakan, NPC, gerbang, dan pemain.

signal talk_to_npc(npc_id: String)
signal enter_portal
signal objective_changed(info: Dictionary)
signal inspect_object(obj_id: String)

const SPAWNS := Content.SPAWNS

var map_id := "kota"
var meta: Dictionary = {}
var player: CharacterBody2D
var npc_node: Node2D
var npcs: Array = []
var objects: Array = []
var portal_node: Node2D
var camera: Camera2D
var _prompt_target := ""
## Tujuan yang ditandai dari jurnal misi ("obj:<id>" atau "npc:<id>").
## Selama terisi, HUD menunjuk ke sasaran ini, bukan ke objek terdekat.
var marked := ""
var _focus: Node2D
var _t := 0.0
var prop_block: Dictionary = {}
var prop_fade: Array = []
var actors: Node2D          # wadah ber-y-sort: pemain, NPC, objek, pohon, gedung

func build(id: String) -> void:
	map_id = id
	meta = _load_meta(id)
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	add_child(actors)
	_build_background(id)
	_build_props()
	_build_collisions()
	_build_npcs()
	_build_objects()
	_build_portal()
	_build_player()
	_build_camera()
	_build_focus()

func _load_meta(id: String) -> Dictionary:
	var path := "res://assets/maps/%s.json" % id
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if typeof(data) == TYPE_DICTIONARY else {}

func _tile_size() -> int:
	return int(meta.get("tile", 16))

func tile_center(tx: int, ty: int) -> Vector2:
	var t := _tile_size()
	return Vector2(tx * t + t * 0.5, ty * t + t * 0.5)

func _build_background(id: String) -> void:
	var spr := Sprite2D.new()
	var tex: Texture2D = load("res://assets/maps/%s.png" % id)
	spr.texture = tex
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = -50   # di atas latar aplikasi (z=-100), di bawah semua aktor
	add_child(spr)

func _build_props() -> void:
	## Pohon, semak, dan gedung digambar sebagai sprite terpisah supaya pemain
	## bisa lewat di belakangnya (urutan kedalaman mengikuti posisi kaki).
	if OS.get_environment("TERRA_NOPROPS") != "":
		return
	var path := "res://assets/maps/%s.props.json" % map_id
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_ARRAY:
		return
	for it in data:
		var tex: Texture2D = load("res://assets/sprites/props/%s.png" % str(it.get("n", "tree_big")))
		if tex == null:
			continue
		var h := float(it.get("h", 120.0))
		var sc := h / float(tex.get_height())
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spr.centered = true
		spr.offset = Vector2(0, -tex.get_height() * 0.5)
		spr.scale = Vector2(sc, sc)
		spr.flip_h = bool(it.get("f", false))
		spr.position = Vector2(float(it.get("x", 0.0)), float(it.get("y", 0.0)))
		actors.add_child(spr)
		_add_prop_body(str(it.get("n", "tree_big")), spr.position)
		if str(it.get("n", "")) in ["tree_big", "bush"]:
			prop_fade.append(spr)

## Bodi tabrakan kecil di pangkal pohon/gedung supaya pemain tidak menembusnya.
func _add_prop_body(kind: String, pos: Vector2) -> void:
	var size := Vector2.ZERO
	var off := 0.0
	# Pohon & semak sengaja tanpa tabrakan: kalau diberi tabrakan, jalur di Hutan
	# jadi terputus dan pemain tersangkut. Sebagai gantinya kanopi dibuat tembus
	# pandang lewat _fade_canopy().
	match kind:
		"lamp":
			size = Vector2(16, 10)
			off = -4.0
		"bldg_shop", "bldg_house", "bldg_office":
			size = Vector2(110, 46)
			off = -18.0
		_:
			return
	var body := StaticBody2D.new()
	body.position = pos + Vector2(0, off)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	add_child(body)
	# tandai tile yang tertutup supaya pencari jalan demo tidak menabrak
	var t := _tile_size()
	var x0 := int(floor((pos.x - size.x * 0.5) / t))
	var x1 := int(floor((pos.x + size.x * 0.5) / t))
	var y0 := int(floor((pos.y + off - size.y * 0.5) / t))
	var y1 := int(floor((pos.y + off + size.y * 0.5) / t))
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			prop_block[Vector2i(tx, ty)] = true

## Kanopi pohon dibuat tembus pandang saat pemain lewat di belakangnya,
## supaya karakter tidak "hilang" di balik daun.
func _fade_canopy(delta: float) -> void:
	if player == null:
		return
	var px := player.position
	for spr in prop_fade:
		var sp: Sprite2D = spr
		var d: Vector2 = sp.position - px
		var inside := absf(d.x) < 62.0 and d.y < 14.0 and d.y > -160.0
		var target := 0.42 if (inside and sp.position.y > px.y) else 1.0
		if not is_equal_approx(sp.modulate.a, target):
			sp.modulate.a = move_toward(sp.modulate.a, target, delta * 4.0)

func _build_collisions() -> void:
	var solid: Array = meta.get("solid", [])
	if solid.is_empty():
		return
	var t := _tile_size()
	var body := StaticBody2D.new()
	add_child(body)
	for y in range(solid.size()):
		var x := 0
		var row: Array = solid[y]
		while x < row.size():
			if int(row[x]) == 1:
				var start := x
				while x < row.size() and int(row[x]) == 1:
					x += 1
				var cs := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * t, t)
				cs.shape = shape
				cs.position = Vector2(start * t + (x - start) * t * 0.5, y * t + t * 0.5)
				body.add_child(cs)
			else:
				x += 1

static var _shadow_tex: Texture2D = null

## Bayangan kontak lembut agar karakter tidak terlihat melayang.
func _shadow_texture() -> Texture2D:
	if _shadow_tex != null:
		return _shadow_tex
	var img := Image.create(76, 30, false, Image.FORMAT_RGBA8)
	for y in range(30):
		for x in range(76):
			var dx := (x - 37.5) / 37.5
			var dy := (y - 14.5) / 14.5
			var r := sqrt(dx * dx + dy * dy)
			var a := clampf(1.0 - r, 0.0, 1.0)
			# inti lebih pekat, tepi tetap lembut -> bayangan kontak lebih terasa
			img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.78 * pow(a, 1.5)))
	_shadow_tex = ImageTexture.create_from_image(img)
	return _shadow_tex

func _add_shadow(pos: Vector2, sx: float = 1.0) -> void:
	var sh := Sprite2D.new()
	sh.texture = _shadow_texture()
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sh.position = pos
	sh.scale = Vector2(sx, sx)
	sh.z_index = -10
	add_child(sh)

## Label nama dengan latar pil gelap supaya tidak perlu outline tebal.
func _name_plate(text: String, color: Color) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_override("font", UiKit.pixel_font())
	lb.add_theme_font_size_override("font_size", 13)
	lb.add_theme_color_override("font_color", color)
	var sb := UiKit.panel_style(Color(0.045, 0.06, 0.09, 0.82), Color(0.35, 0.45, 0.55, 0.35), 3, 1)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	lb.add_theme_stylebox_override("normal", sb)
	lb.z_index = 20
	return lb

func _build_npcs() -> void:
	var m := Content.map_by_id(map_id)
	var list: Array = Content.npcs_of(m)
	var meta_npc: Dictionary = meta.get("npc", {})
	for n in list:
		var spr := AnimatedSprite2D.new()
		var tex: Texture2D = load("res://assets/sprites/npc_%s.png" % str(n.get("sprite", "kepala")))
		spr.sprite_frames = _npc_frames(tex)
		spr.play("idle_down")
		# Sheet NPC lama berukuran 96x144 per frame, sheet baru 24x32. Sprite
		# baru diperbesar supaya tinggi tubuhnya sama dengan NPC lain.
		var sk := 144.0 / _npc_frame_size(tex).y
		spr.scale = Vector2(sk, sk)
		spr.offset = Vector2(0, -56.0 / sk)
		if OS.get_environment("TERRA_NPCDBG") != "":
			print("NPC ", n.get("name"), " frames=", spr.sprite_frames.get_frame_count("idle_down"),
				" speed=", spr.sprite_frames.get_animation_speed("idle_down"),
				" playing=", spr.is_playing(), " region=", spr.sprite_frames.get_frame_texture("idle_down", 1).region)
		var tx := int(n.get("x", meta_npc.get("x", 10)))
		var ty := int(n.get("y", meta_npc.get("y", 10)))
		spr.position = tile_center(tx, ty)
		spr.offset = Vector2(0, -56)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		actors.add_child(spr)
		_add_shadow(spr.position + Vector2(0, 14), 0.95)

		# tabrakan kaki NPC: pemain tidak bisa menembus tubuh NPC
		var nbody := StaticBody2D.new()
		nbody.position = spr.position
		var ncs := CollisionShape2D.new()
		var nshape := RectangleShape2D.new()
		nshape.size = Vector2(72, 40)
		ncs.shape = nshape
		ncs.position = Vector2(0, -10)
		nbody.add_child(ncs)
		add_child(nbody)

		# nama di bawah kaki agar pemain tahu siapa yang diajak bicara
		var lb := _name_plate(str(n.get("name", "NPC")), UiKit.TEXT)
		add_child(lb)
		lb.reset_size()
		lb.position = _clamp_label(spr.position + Vector2(-lb.size.x * 0.5, 18), lb.size.x)

		# penanda di atas NPC pengajar materi
		var mark: Label = null
		if str(n.get("action", "")) == "materi":
			mark = Label.new()
			mark.text = "!"
			mark.add_theme_font_override("font", UiKit.pixel_font())
			mark.add_theme_font_size_override("font_size", 22)
			mark.add_theme_color_override("font_color", UiKit.GOLD)
			mark.add_theme_color_override("font_outline_color", Color(0.04, 0.07, 0.11))
			mark.add_theme_constant_override("outline_size", 5)
			mark.z_index = 21
			add_child(mark)
			mark.reset_size()
			mark.position = spr.position + Vector2(-mark.size.x * 0.5, -190)

		npcs.append({"id": str(n.get("id", "utama")), "name": str(n.get("name", "NPC")),
			"action": str(n.get("action", "quest")), "node": spr, "mark": mark})
		if npc_node == null:
			npc_node = spr

## Ukuran satu frame pada sheet NPC.
## Sheet lama: 384x576 -> 4 kolom x 4 baris, frame 96x144.
## Sheet baru: 72x128  -> 3 kolom x 4 baris, frame 24x32.
func _npc_frame_size(tex: Texture2D) -> Vector2:
	if tex.get_width() >= 384:
		return Vector2(96, 144)
	return Vector2(float(tex.get_width()) / 3.0, float(tex.get_height()) / 4.0)

func _npc_frames(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("idle_down")
	var fr := _npc_frame_size(tex)
	# dua frame (kolom 0 dan 2) supaya NPC ikut "bernapas", tidak seperti gambar mati
	for col in [0, 2]:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fr.x, 0, fr.x, fr.y)
		sf.add_frame("idle_down", at)
	sf.set_animation_speed("idle_down", 1.6)
	sf.set_animation_loop("idle_down", true)
	return sf

## Objek yang bisa diperiksa: papan data, catatan, komponen perangkat.
func _build_objects() -> void:
	var m := Content.map_by_id(map_id)
	for o in m.get("objects", []):
		var spr := Sprite2D.new()
		spr.texture = load("res://assets/sprites/obj_%s.png" % str(o.get("icon", "sign")))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# +8 pada posisi (dan -10 pada offset) membuat objek selalu tergambar
		# di depan pohon/gedung di dekatnya, tanpa mengubah posisi tampilannya.
		spr.position = tile_center(int(o["x"]), int(o["y"])) + Vector2(0, 6)
		spr.offset = Vector2(0, -8)
		actors.add_child(spr)
		_add_shadow(spr.position + Vector2(0, 3), 0.7)

		var lb := _name_plate(str(o.get("label", "Objek")), UiKit.BLUE)
		add_child(lb)
		lb.reset_size()
		lb.position = _clamp_label(spr.position + Vector2(-lb.size.x * 0.5, -26), lb.size.x)

		var mark := Label.new()
		mark.text = "?"
		mark.add_theme_font_override("font", UiKit.pixel_font())
		mark.add_theme_font_size_override("font_size", 19)
		mark.add_theme_color_override("font_color", UiKit.BLUE)
		mark.add_theme_color_override("font_outline_color", Color(0.04, 0.07, 0.11))
		mark.add_theme_constant_override("outline_size", 5)
		mark.z_index = 21
		add_child(mark)
		mark.reset_size()
		mark.position = spr.position + Vector2(-mark.size.x * 0.5, -42)

		objects.append({"id": str(o["id"]), "label": str(o.get("label", "Objek")),
			"node": spr, "mark": mark, "data": o})

## Penanda tujuan dari jurnal: belah ketupat keemasan yang berdenyut di atas
## benda/NPC yang dipilih pemain.
func _build_focus() -> void:
	# Digambar sebagai poligon, bukan huruf, supaya tidak bergantung pada glyph
	# yang tersedia di font pixel.
	var root := Node2D.new()
	root.z_index = 22
	root.visible = false
	var tepi := Polygon2D.new()
	tepi.polygon = PackedVector2Array([Vector2(0, -13), Vector2(13, 0), Vector2(0, 13), Vector2(-13, 0)])
	tepi.color = Color(0.10, 0.06, 0.02, 0.85)
	root.add_child(tepi)
	var isi := Polygon2D.new()
	isi.polygon = PackedVector2Array([Vector2(0, -9), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0)])
	isi.color = UiKit.GOLD
	root.add_child(isi)
	add_child(root)
	_focus = root

func _build_portal() -> void:
	var info: Dictionary = meta.get("portal", {})
	if info.is_empty():
		return
	var p := Node2D.new()
	p.set_script(load("res://scripts/portal.gd"))
	p.position = tile_center(int(info["x"]), int(info["y"])) + Vector2(0, -2)
	p.locked = not Game.is_map_cleared(map_id)
	portal_node = p
	actors.add_child(portal_node)

func _build_player() -> void:
	var p := CharacterBody2D.new()
	p.set_script(load("res://scripts/player.gd"))
	var spawn: Vector2 = SPAWNS.get(map_id, Vector2(20, 18))
	p.position = tile_center(int(spawn.x), int(spawn.y)) + Vector2(0, -6)
	player = p
	actors.add_child(p)

	var sh := Sprite2D.new()
	sh.texture = _shadow_texture()
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sh.position = Vector2(0, 12)
	sh.z_index = -1
	sh.z_as_relative = true
	p.add_child(sh)

func _build_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Cam"
	cam.zoom = Vector2(1.0, 1.0)
	cam.position = Vector2(_map_w() * 0.5, _map_h() * 0.5)
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	camera = cam

## Kamera mengikuti pemain supaya karakter selalu di tengah layar.
func _update_camera() -> void:
	if camera == null or player == null:
		return
	var half := get_viewport_rect().size * 0.5 / camera.zoom
	var want := player.position + Vector2(0, -24)
	camera.position = Vector2(
		clampf(want.x, half.x, maxf(half.x, _map_w() - half.x)),
		clampf(want.y, half.y, maxf(half.y, _map_h() - half.y)))

func _map_w() -> float:
	return float(int(meta.get("w", 40)) * _tile_size())

func _map_h() -> float:
	return float(int(meta.get("h", 22)) * _tile_size())

## Objek terdekat yang bisa diajak interaksi: "npc:<id>", "portal", atau "".
func _process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	_update_camera()
	_fade_canopy(delta)
	_animate_marks()
	objective_changed.emit(next_objective())
	var target := ""
	var best := 88.0
	for n in npcs:
		var node: Node2D = n["node"]
		var d := player.position.distance_to(node.position + Vector2(0, 46))
		# NPC menoleh ke sisi tempat pemain berdiri supaya terasa hidup.
		var face_left: bool = player.position.x < node.position.x - 4.0
		if node is AnimatedSprite2D and node.flip_h != face_left:
			node.flip_h = face_left
		if d < best:
			best = d
			target = "npc:" + str(n["id"])
	for o in objects:
		if not _object_active(o):
			continue
		var onode: Node2D = o["node"]
		var od := player.position.distance_to(onode.position + Vector2(0, 4))
		if od < best:
			best = od
			target = "obj:" + str(o["id"])
	if portal_node:
		var pd: float = player.position.distance_to(portal_node.position)
		portal_node.near = pd < 150.0
		if pd < best:
			target = "portal"
	if target != _prompt_target:
		_prompt_target = target
		_emit_prompt(target)

## Penanda "!" naik-turun halus, dan hilang bila wilayah sudah selesai.
func _animate_marks() -> void:
	var cleared := Game.is_map_cleared(map_id)
	var bob := sin(_t * 3.0) * 2.0
	for n in npcs:
		var mark = n.get("mark")
		if mark == null:
			continue
		mark.visible = not cleared
		if mark.visible:
			var base: Vector2 = n["node"].position
			mark.position = base + Vector2(-mark.size.x * 0.5, -134 + bob)
	for o in objects:
		var active := _object_active(o)
		(o["node"] as Node2D).visible = active
		var om = o["mark"]
		om.visible = active
		if active:
			var obase: Vector2 = o["node"].position
			om.position = obase + Vector2(-om.size.x * 0.5, -56 + bob)
	if _focus != null:
		var t := _marked_target()
		if t.is_empty():
			_focus.visible = false
		else:
			_focus.visible = true
			var p: Vector2 = t["pos"]
			_focus.position = p + Vector2(0, -92 + bob * 1.6)
			_focus.modulate.a = 0.65 + 0.35 * sin(_t * 4.0)

func _object_entry(obj_id: String) -> Dictionary:
	for o in objects:
		if str(o["id"]) == obj_id:
			return o
	return {}

## Objek disembunyikan bila tantangannya sudah selesai.
## Objek/NPC terdekat yang belum selesai — dipakai HUD untuk panah tujuan.
func next_objective() -> Dictionary:
	# Penanda dari jurnal misi menang atas objek terdekat, supaya pemain
	# benar-benar diarahkan ke misi yang ia pilih.
	if marked != "":
		var t := _marked_target()
		if t.is_empty():
			clear_mark()
		elif (t["pos"] as Vector2).distance_to(player.position) < 130.0:
			clear_mark()
		else:
			return t
	var best := {}
	var best_d := 1e9
	for o in objects:
		if not _object_active(o):
			continue
		var node := o["node"] as Node2D
		if node == null:
			continue
		var d: float = node.position.distance_to(player.position)
		if d < best_d:
			best_d = d
			best = {"pos": node.position, "name": str(o["label"])}
	for n in npcs:
		if str(n.get("action", "quest")) != "quest":
			continue
		var node2 := n["node"] as Node2D
		if node2 == null:
			continue
		var d2: float = node2.position.distance_to(player.position)
		if d2 < best_d:
			best_d = d2
			best = {"pos": node2.position, "name": str(n.get("name", "NPC"))}
	return best

## Menaruh penanda pada satu objek/NPC. Mengembalikan false bila sasaran tidak
## ada atau misinya sudah selesai.
func mark_objective(target: String) -> bool:
	if target == "":
		return false
	if _marked_target_of(target).is_empty():
		return false
	marked = target
	return true

func clear_mark() -> void:
	marked = ""
	if _focus != null:
		_focus.visible = false

## Sasaran penanda aktif, dalam bentuk {"pos", "name"}; kosong bila sasaran
## sudah tidak ada (mis. misinya selesai dan objeknya disembunyikan).
func _marked_target() -> Dictionary:
	return _marked_target_of(marked)

func _marked_target_of(target: String) -> Dictionary:
	if target.begins_with("obj:"):
		var o := _object_entry(target.substr(4))
		if o.is_empty() or not _object_active(o):
			return {}
		var onode := o["node"] as Node2D
		if onode == null:
			return {}
		return {"pos": onode.position, "name": str(o["label"])}
	if target.begins_with("npc:"):
		var n := _npc_entry(target.substr(4))
		if n.is_empty():
			return {}
		var nnode := n["node"] as Node2D
		if nnode == null:
			return {}
		return {"pos": nnode.position, "name": str(n.get("name", "NPC"))}
	return {}

func _object_active(o: Dictionary) -> bool:
	var data: Dictionary = o["data"]
	if data.has("challenge") and Game.done.has(str(data["challenge"])):
		return false
	return true

## Menjaga label tetap di dalam batas peta agar tidak terpotong tepi layar.
func _clamp_label(pos: Vector2, w: float) -> Vector2:
	var x := clampf(pos.x, 2.0, _map_w() - w - 2.0)
	var y := clampf(pos.y, 2.0, _map_h() - 30.0)
	return Vector2(x, y)

func _npc_entry(npc_id: String) -> Dictionary:
	for n in npcs:
		if str(n["id"]) == npc_id:
			return n
	return {}

func _emit_prompt(target: String) -> void:
	var label := ""
	if target.begins_with("obj:"):
		var o := _object_entry(target.substr(4))
		if not o.is_empty():
			label = "[E] Periksa %s" % str(o["label"])
	elif target.begins_with("npc:"):
		var n := _npc_entry(target.substr(4))
		if not n.is_empty():
			label = "[E] Bicara dengan %s" % str(n["name"])
	elif target == "portal":
		label = "[E] Masuk gerbang"
	Game.set_prompt(label)

func try_interact() -> bool:
	if _prompt_target.begins_with("obj:"):
		inspect_object.emit(_prompt_target.substr(4))
		return true
	if _prompt_target.begins_with("npc:"):
		talk_to_npc.emit(_prompt_target.substr(4))
		return true
	if _prompt_target == "portal":
		enter_portal.emit()
		return true
	return false
