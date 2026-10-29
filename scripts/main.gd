extends Control
## Pengatur utama: layar, alur permainan, dan input.

const WORLD_SCRIPT := preload("res://scripts/world.gd")
const DIALOG_SCRIPT := preload("res://scripts/ui/dialog_box.gd")
const PUZZLE_SCRIPT := preload("res://scripts/ui/puzzle_panel.gd")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const TITLE_SCRIPT := preload("res://scripts/screens/title.gd")
const MAP_SCRIPT := preload("res://scripts/screens/map_select.gd")
const RESEARCH_SCRIPT := preload("res://scripts/screens/research.gd")
const ENDING_SCRIPT := preload("res://scripts/screens/ending.gd")
const BADGE_SCRIPT := preload("res://scripts/ui/badge_popup.gd")
const REWARD_SCRIPT := preload("res://scripts/ui/reward_popup.gd")
const SHOP_SCRIPT := preload("res://scripts/ui/shop_panel.gd")
const ASESMEN_SCRIPT := preload("res://scripts/ui/asesmen.gd")
const PAUSE_SCRIPT := preload("res://scripts/ui/pause_menu.gd")
const JOURNAL_SCRIPT := preload("res://scripts/screens/journal.gd")
const BADGES_SCRIPT := preload("res://scripts/screens/badges.gd")

var state := "title"
var current_map := "kota"

var _world_holder: Node2D
var _world: Node2D
var _screens: Control
var _screen_layer: CanvasLayer
var _hud_layer: CanvasLayer
var _modal_layer: CanvasLayer
var _fade: ColorRect
var _toast: Label
var _toast_tw: Tween

var hud: Control
var dialog: Control
var puzzle: Control
var badge_popup: Control
var reward_popup: Control
var shop: Control
var asesmen: Control
var pause_menu: Control
var journal: Control
var badges_screen: Control
var title_screen: Control
var map_screen: Control
var research_screen: Control
var ending_screen: Control

var _pending_badge := ""
var _dialog_intent := ""   # "quest" | "info" | "gate" | "shop" | "object"
var _pending_object := ""
var _npc_quest := ""      # id tantangan puzzle yang ditawarkan NPC

func _ready() -> void:
	_ensure_inputs()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.z_index = -100
	bg.color = Color(0.04, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_world_holder = Node2D.new()
	add_child(_world_holder)

	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = 1
	add_child(_screen_layer)
	_screens = Control.new()
	_screens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_layer.add_child(_screens)

	title_screen = _new_screen(TITLE_SCRIPT)
	map_screen = _new_screen(MAP_SCRIPT)
	research_screen = _new_screen(RESEARCH_SCRIPT)
	ending_screen = _new_screen(ENDING_SCRIPT)

	title_screen.new_game.connect(_on_new_game)
	title_screen.continue_game.connect(_on_continue)
	title_screen.open_maps.connect(func(): _open_maps())
	title_screen.open_research.connect(func(): _open_research())
	title_screen.open_settings.connect(_open_settings_from_title)

	map_screen.map_chosen.connect(_on_map_chosen)
	map_screen.back_pressed.connect(_on_map_back)
	map_screen.open_journal.connect(func(): _open_journal(false))

	research_screen.back_pressed.connect(_on_research_back)
	research_screen.open_asesmen.connect(_open_asesmen)

	ending_screen.open_maps.connect(func(): _open_maps())
	ending_screen.open_research.connect(func(): _open_research())
	ending_screen.back_to_title.connect(_show_title)

	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 2
	add_child(_hud_layer)
	hud = HUD_SCRIPT.new()
	_hud_layer.add_child(hud)
	hud.open_map.connect(func(): _open_maps())
	hud.open_menu.connect(func(): _open_pause())
	hud.open_badges.connect(func(): _open_badges())

	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 3
	add_child(_modal_layer)

	dialog = DIALOG_SCRIPT.new()
	_modal_layer.add_child(dialog)
	dialog.finished.connect(_on_dialog_finished)

	puzzle = PUZZLE_SCRIPT.new()
	_modal_layer.add_child(puzzle)
	puzzle.solved.connect(_on_puzzle_solved)
	Game.map_completed.connect(_on_map_completed)
	Game.map_failed.connect(_on_map_failed)
	Game.lives_changed.connect(func(_id: String, _lives: int): hud.refresh())
	puzzle.closed.connect(func(): pass)

	shop = SHOP_SCRIPT.new()
	_modal_layer.add_child(shop)

	badge_popup = BADGE_SCRIPT.new()
	_modal_layer.add_child(badge_popup)
	badge_popup.closed.connect(_on_badge_closed)

	reward_popup = REWARD_SCRIPT.new()
	_modal_layer.add_child(reward_popup)

	asesmen = ASESMEN_SCRIPT.new()
	_modal_layer.add_child(asesmen)
	asesmen.finished.connect(_on_asesmen_finished)
	asesmen.cancelled.connect(func(): pass)

	# Layar jeda & jurnal misi. Keduanya harus tetap berjalan saat pohon scene
	# dijeda, karena itulah satu-satunya cara menutup layar jeda.
	pause_menu = PAUSE_SCRIPT.new()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.z_index = 20
	_modal_layer.add_child(pause_menu)
	pause_menu.resumed.connect(_close_pause)
	pause_menu.open_journal.connect(func(): _open_journal(true))
	pause_menu.restart_requested.connect(_on_restart_map)
	pause_menu.to_title_requested.connect(_on_pause_to_title)
	pause_menu.settings_closed.connect(_on_settings_closed)

	journal = JOURNAL_SCRIPT.new()
	journal.process_mode = Node.PROCESS_MODE_ALWAYS
	# Ditaruh di lapisan modal supaya menutupi HUD; kalau di lapisan layar, panel
	# "Misi Aktif" akan menembus jurnal. z_index menjaga pesan singkat (toast)
	# tidak muncul di atas jurnal.
	journal.z_index = 19
	_modal_layer.add_child(journal)
	journal.closed.connect(_on_journal_closed)
	journal.open_maps.connect(func():
		journal.visible = false
		get_tree().paused = false
		hud.visible = false
		_open_maps())
	journal.mark_requested.connect(_on_journal_mark)

	badges_screen = BADGES_SCRIPT.new()
	badges_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	badges_screen.z_index = 19
	_modal_layer.add_child(badges_screen)
	badges_screen.closed.connect(_on_badges_closed)
	badges_screen.open_journal.connect(func():
		badges_screen.visible = false
		get_tree().paused = false
		_open_journal(false))

	_toast = UiKit.label("", 20, UiKit.GOLD)
	_toast.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.95))
	_toast.add_theme_constant_override("outline_size", 7)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 120
	_toast.offset_left = -200
	_toast.offset_right = 200
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_modal_layer.add_child(_toast)

	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.03, 0.05, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 3
	add_child(fade_layer)
	fade_layer.add_child(_fade)

	Game.badge_earned.connect(_on_badge_earned)
	_show_title()
	_fade_out()

	# Tangkapan layar/video diambil dari dalam game (viewport), bukan dari X11,
	# karena x11grab di Xvfb kadang menangkap jendela yang belum selesai digambar.
	var shot_path := OS.get_environment("TERRA_SHOT")
	if shot_path != "":
		_auto_shot(shot_path, float(OS.get_environment("TERRA_SHOT_DELAY")))
	var frames_dir := OS.get_environment("TERRA_FRAMES")
	if frames_dir != "":
		_auto_frames(frames_dir, float(OS.get_environment("TERRA_FRAMES_SECS")))
	var demo := OS.get_environment("TERRA_DEMO")
	if demo != "":
		call_deferred("_run_demo", demo)
	if OS.get_environment("TERRA_DUMP") != "":
		_dump_later()

## Mode demo untuk pengambilan tangkapan layar (dokumentasi Bab III).
func _run_demo(kind: String) -> void:
	# Demo/tangkapan layar memakai berkas sendiri agar tidak menulis ke data
	# peserta asli maupun menimpa simpanan pemain.
	Game.record_path = "user://records_demo.json"
	Game.save_path = "user://save_demo.json"
	for p in [Game.save_path, Game.record_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	match kind:
		"title":
			pass
		"map":
			_open_maps()
		"world":
			_start_play("hutan")
		"dialog":
			_start_play("hutan")
			await get_tree().create_timer(0.4).timeout
			var m := Content.map_by_id("hutan")
			dialog.open(str(m["npc_name"]), str(m["npc_role"]), m["intro"], str(m.get("npc_sprite", "")))
		"puzzle":
			_start_play("hutan")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m2 := Content.map_by_id("hutan")
			puzzle.open(m2["challenges"][1], 1, (m2["challenges"] as Array).size())
		"cipher":
			Game.badges = ["nature", "core"] as Array[String]
			_start_play("candi")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m3 := Content.map_by_id("candi")
			puzzle.open(m3["challenges"][1], 1, (m3["challenges"] as Array).size())
		"badge":
			_start_play("hutan")
			await get_tree().create_timer(0.3).timeout
			badge_popup.show_badge("nature", "Nature Data Crystal")
		"order":
			Game.badges = ["nature", "core", "cipher"] as Array[String]
			_start_play("danau")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m5 := Content.map_by_id("danau")
			var chs5: Array = m5["challenges"]
			puzzle.open(chs5[1], 1, chs5.size())
		"fill":
			Game.badges = ["nature", "core"] as Array[String]
			_start_play("hutan")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			puzzle.open({
				"id": "demo-fill", "title": "Melengkapi Query", "type": "fill",
				"prompt": "Lengkapi perintah SQL berikut agar baris baru masuk ke tabel sumber_air.",
				"code": "___ INTO sumber_air (nama, ph) VALUES ('Mata Air 7', 6.1)",
				"accept": ["insert", "insert into"],
				"explain": "INSERT INTO menambahkan baris baru ke tabel.",
			}, 0, 1)
		"shop":
			_start_play("kota")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			Game.coins = 120
			shop.open()
		"lensa":
			Game.badges = ["nature", "core", "cipher"] as Array[String]
			_start_play("danau")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			Game.items["lensa"] = 1
			var m4 := Content.map_by_id("danau")
			var chs4: Array = m4["challenges"]
			puzzle.open(chs4[1], 1, chs4.size())
			await get_tree().create_timer(0.3).timeout
			puzzle._on_lensa()
		"pause":
			_start_play("hutan")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			_open_pause()
		"mark":
			_start_play("hutan")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			_world.mark_objective("obj:hutan-cari-1")
			_toast_msg("Ditandai: Papan Data", 4.0)
		"journal":
			_start_play("hutan")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			Game.done["kota-1"] = true
			Game.done["kota-2"] = true
			Game.done["hutan-1"] = true
			Game.done["hutan-2"] = true
			Game.done["hutan-b1"] = true
			Game.map_lives["hutan"] = 2
			_open_journal(false)
		"badges":
			_start_play("hutan")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			Game.badges = ["nature"] as Array[String]
			Game.done["hutan-1"] = true
			_open_badges()
		"settings":
			_show_title()
			await get_tree().create_timer(0.4).timeout
			_open_settings_from_title()
		"asesmen":
			Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
			_start_play("source")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			_open_asesmen()
			asesmen._kode_edit.text = "P01"
			asesmen._stage = "posttest"
			asesmen._qi = 0
			asesmen._render()
		"sus":
			Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
			_start_play("source")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			_open_asesmen()
			asesmen._post = Game.answer_key()
			asesmen._sus = [4, 2, 4, 2, 4, 2, 4, 2, 4, 2]
			asesmen._stage = "sus"
			asesmen._qi = 0
			asesmen._render()
		"hasil":
			Game.player_code = "P01"
			Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
			_start_play("source")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			_open_asesmen()
			asesmen._post = Game.answer_key()
			asesmen._result = Game.grade_posttest(asesmen._post)
			asesmen._sus = [4, 2, 4, 2, 4, 2, 4, 2, 4, 2]
			asesmen._sus_score = Game.sus_score(asesmen._sus)
			asesmen._stage = "done"
			asesmen._render()
		"rekap":
			Game.player_code = "P01"
			# durasi dibuat wajar (18,4 menit) supaya contoh data di layar rekap
			# tidak menampilkan 0,0 menit — nilainya tetap dihitung oleh game.
			Game.session_start = int(Time.get_unix_time_from_system()) - 1104
			Game.submit_posttest(Game.answer_key())
			Game.submit_sus([4, 2, 4, 2, 4, 2, 4, 2, 4, 2])
			_open_research()
		"ending":
			Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
			for m in Content.MAPS:
				for c in m["challenges"]:
					Game.done[c["id"]] = true
			_show_ending()
		"play":
			var pm_id := OS.get_environment("TERRA_MAP")
			if pm_id == "":
				pm_id = "hutan"
			_start_play(pm_id)
			await get_tree().create_timer(0.35).timeout
			dialog.visible = false
		"cari":
			_start_play("hutan")
			await get_tree().create_timer(0.35).timeout
			dialog.visible = false
			var mc := Content.map_by_id("hutan")
			if _world and mc.get("objects", []).size() > 0:
				var oc: Dictionary = mc["objects"][0]
				_world.player.position = _world.tile_center(int(oc["x"]), int(oc["y"])) + Vector2(0, 46)
			await get_tree().create_timer(0.6).timeout
		"belakang":
			_start_play("kota")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			if _world and _world.player:
				_world.player.position = Vector2(793, 240 - 26)
				_world.player._sprite.play("idle")
				_world.player.can_move = false
				_world.camera.position = Vector2(793, 240 - 80)
		"kanan":
			_start_play("kota")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			if _world and _world.player:
				_world.player.position = _world.tile_center(24, 10)
				_world.player._sprite.play("run")
				_world.player._sprite.pause()
				_world.player._sprite.frame = 0
				_world.player.can_move = false
		"depan":
			_start_play("kota")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			if _world and _world.player:
				_world.player.position = _world.tile_center(24, 10)
				_world.player._sprite.play("idle")
				_world.player._sprite.pause()
				_world.player.can_move = false
		"jalan":
			_start_play("kota")
			while true:
				if _world and _world.player:
					_world.player.position = _world.tile_center(24, 10)
					Input.action_press("move_right")
				await get_tree().create_timer(0.5).timeout
		"camx":
			_start_play(OS.get_environment("TERRA_MAP") if OS.get_environment("TERRA_MAP") != "" else "kota")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var cx := float(OS.get_environment("TERRA_PX"))
			if cx <= 0.0:
				cx = 1176.0
			_world.player.position = Vector2(cx, 504)
			_world.player.can_move = false
		"near":
			_start_play("hutan")
			await get_tree().create_timer(0.35).timeout
			dialog.visible = false
			if _world and _world.npc_node:
				_world.player.position = _world.npc_node.position + Vector2(0, 20)
			await get_tree().create_timer(0.4).timeout
		"order":
			Game.badges = ["nature"] as Array[String]
			_start_play("pabrik")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m4 := Content.map_by_id("pabrik")
			puzzle.open(m4["challenges"][1], 1, (m4["challenges"] as Array).size())
		"npc":
			var npc_map := OS.get_environment("TERRA_MAP")
			if npc_map == "":
				npc_map = "pabrik"
			_start_play(npc_map)
			await get_tree().create_timer(0.5).timeout
			var mn := Content.map_by_id(npc_map)
			dialog.open(str(mn["npc_name"]), str(mn["npc_role"]), _intro_lines(mn), str(mn.get("npc_sprite", "")))
		"craft":
			Game.badges = ["nature", "core", "cipher"] as Array[String]
			Game.components = {"sensor": true, "papan": true, "mcu": true, "daya": true}
			_start_play("danau")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var md := Content.map_by_id("danau")
			puzzle.open(md["challenges"][2], 2, (md["challenges"] as Array).size())
			# Tangkapan layar puzzle kabel: pasang dua kabel lebih dulu supaya
			# garis sambungannya terlihat (bukan skor, hanya demo).
			if str(puzzle._c.get("type", "")) == "wire":
				await get_tree().create_timer(0.4).timeout
				for l in (puzzle._c.get("links", []) as Array).slice(0, 2):
					puzzle._on_wire_pin(str((l as Array)[0]))
					puzzle._on_wire_pin(str((l as Array)[1]))
		"boss":
			Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
			_start_play("source")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var ms := Content.map_by_id("source")
			puzzle.open(_with_boss(ms["challenges"][0], ms), 0, (ms["challenges"] as Array).size())
		"pilih":
			_show_ending_choice()
		"shop":
			Game.coins = 140
			_start_play("kota")
			await get_tree().create_timer(0.6).timeout
			Game.buy_item("sensor")
			shop.open()
		"rekam":
			await _demo_rekam()
		"terbaru":
			await _demo_terbaru()
		"tour":
			await _demo_tour()
		"full":
			await _demo_full()
		"tabrak":
			_start_play("kota")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var np: Vector2 = _world.npc_node.position
			_world.player.position = np + Vector2(-150, 0)
			await get_tree().create_timer(0.2).timeout
			Input.action_press("move_right")
			await get_tree().create_timer(2.5).timeout
			Input.action_release("move_right")
			await get_tree().create_timer(0.2).timeout
			print("TABRAK x=", _world.player.position.x, " npc=", np.x, " gap=", np.x - _world.player.position.x, " prompt=", _world._prompt_target)
		"objek":
			_start_play("hutan")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			var onode: Node2D = null
			for o in _world.objects:
				if str(o["id"]) == "hutan-cari-1":
					onode = o["node"]
			print("OBJ node=", onode, " active=", _world._object_active(_world.objects[0]))
			if onode:
				_world.player.position = onode.position + Vector2(0, 60)
			await get_tree().create_timer(0.6).timeout
			print("PROMPT=", _world._prompt_target)
			await _demo_act("interact")
			await get_tree().create_timer(1.2).timeout
			print("DIALOG=", dialog.visible, " PUZZLE=", puzzle.visible)
		"research":
			_open_research()
		"riset":
			# Data contoh untuk tangkapan layar; berkas peserta asli tidak disentuh.
			Game.record_path = "user://records_demo.json"
			var contoh := [
				["P01", 34.0, 80, 4, 4, 4, 4, true, 82.5],
				["P02", 41.0, 60, 3, 3, 3, 3, false, 70.0],
				["P03", 28.0, 90, 5, 5, 4, 4, true, 87.5],
				["P04", 37.0, 70, 4, 3, 3, 4, true, -1.0],
				["P05", 45.0, 50, 2, 3, 2, 3, false, -1.0],
			]
			for c in contoh:
				var kode := str(c[0])
				Game.upsert_record(kode, {
					"kode": kode,
					"tanggal": "2026-11-12T10:" + kode.substr(1),
					"durasi_menit": float(c[1]), "post": int(c[2]),
					"materi": {
						"Basis Data": int(c[3]), "Sistem Operasi": int(c[4]),
						"Kriptografi": int(c[5]), "Internet of Things": int(c[6]),
					},
					"tuntas": bool(c[7]), "sus": float(c[8]),
				})
			_open_research()
		_:
			pass

# ------------------------------------------------------ demo rekaman (video)
## Cuplikan build terbaru: TOKO, audio, NPC menoleh, dermaga, portal terkunci/terbuka.
func _demo_terbaru() -> void:
	# Satu lokasi setiap video: transisi peta terjadi lewat menu Peta, bukan teleport.
	await get_tree().create_timer(1.0).timeout
	Game.coins = 140
	_start_play("kota")
	await get_tree().create_timer(0.8).timeout
	# Jalan kaki alami dari spawn kota menuju Pedagang.
	await _demo_walk_to(14, 18)
	await get_tree().create_timer(1.5).timeout
	await _demo_act("interact")
	await get_tree().create_timer(1.2).timeout
	while dialog.visible:
		if dialog.is_typing():
			await get_tree().create_timer(0.2).timeout
		else:
			await _demo_act("interact")
			await get_tree().create_timer(0.4).timeout
	await get_tree().create_timer(1.0).timeout
	shop.open()
	Game.sfx("sfx_coin")
	await get_tree().create_timer(6.0).timeout
	shop.visible = false
	await get_tree().create_timer(2.0).timeout
	# Portal kota tetap terkunci karena quest belum selesai.
	# Rute lewat selatan plaza: baris 21 dipenuhi pagar kolam (tile 27-32),
	# jadi belok ke baris 23 dulu baru naik ke gerbang di timur.
	for wp in [[20, 23], [36, 23], [50, 23], [55, 22], [56, 20]]:
		await _demo_walk_to(int(wp[0]), int(wp[1]))
	await get_tree().create_timer(3.0).timeout
	await _demo_act("interact")          # toast: gerbang terkunci
	await get_tree().create_timer(2.4).timeout
	# Selesaikan dua quest kota — portal terbuka di depan mata (update live).
	Game.complete_challenge("kota-1", "kota")
	Game.complete_challenge("kota-2", "kota")
	_on_map_completed("kota")
	await get_tree().create_timer(4.0).timeout
	# Masuk lewat gerbang yang sudah terbuka (transisi asli ke Hutan).
	await _demo_act("interact")
	await get_tree().create_timer(4.5).timeout
	# Eksplorasi sebentar di Hutan Pengetahuan, lalu selesai.
	await _demo_walk_to(18, 14)
	await get_tree().create_timer(1.6).timeout
	get_tree().quit()

## Menjalankan satu wilayah dari awal sampai selesai dengan input tiruan,
## supaya bisa direkam lewat Xvfb + ffmpeg tanpa operator.
func _demo_rekam() -> void:
	await get_tree().create_timer(2.0).timeout
	if title_screen.get("start_btn") != null:
		await _demo_click(title_screen.start_btn)
	await get_tree().create_timer(1.2).timeout

	# --- berjalan sendiri ke NPC pemberi tugas (menunjukkan eksplorasi)
	var q := _demo_quest_tile()
	await _demo_walk_to(int(q.x), int(q.y))
	await get_tree().create_timer(0.9).timeout
	await _demo_act("interact")
	await get_tree().create_timer(0.8).timeout

	# --- dialog pembuka: tunggu sampai selesai mengetik, lalu maju
	var guard := 0
	while dialog.visible and guard < 12:
		guard += 1
		var waited := 0.0
		while dialog.is_typing() and waited < 6.0:
			await get_tree().create_timer(0.2).timeout
			waited += 0.2
		await get_tree().create_timer(1.6).timeout
		await _demo_act("interact")
		await get_tree().create_timer(0.7).timeout

	# --- dua tantangan kota
	for step in range(2):
		await get_tree().create_timer(2.4).timeout
		await _demo_answer()
		await get_tree().create_timer(2.6).timeout
		await _demo_click_lanjut()
		await get_tree().create_timer(1.8).timeout

	await get_tree().create_timer(3.2).timeout
	await _demo_act("open_map")
	await get_tree().create_timer(5.0).timeout

# ------------------------------------------------------ tur dua wilayah (video)
## Merekam alur lengkap: judul → hub → dialog → dua tantangan → peta → hutan →
## temukan objek → tantangan → kembali ke peta.
func _demo_tour() -> void:
	await get_tree().create_timer(1.6).timeout
	if title_screen.get("start_btn") != null:
		await _demo_click(title_screen.start_btn)
	await get_tree().create_timer(1.4).timeout

	var q := _demo_quest_tile()
	await _demo_path_walk(int(q.x), int(q.y))
	await get_tree().create_timer(0.8).timeout
	await _demo_act("interact")
	await _demo_dialog_all()

	for i in range(2):
		await get_tree().create_timer(2.2).timeout
		await _demo_answer()
		await get_tree().create_timer(2.4).timeout
		await _demo_click_lanjut()
		await get_tree().create_timer(1.6).timeout

	await get_tree().create_timer(2.0).timeout
	await _demo_act("open_map")
	await get_tree().create_timer(2.4).timeout
	await _demo_click_map("HUTAN")
	await get_tree().create_timer(3.6).timeout

	var obj := _demo_nearest_object()
	if obj != Vector2i(-1, -1):
		await _demo_path_walk(obj.x, obj.y)
		await get_tree().create_timer(0.8).timeout
		await _demo_act("interact")
		await _demo_dialog_all()
		await get_tree().create_timer(1.4).timeout
		await _demo_answer()
		await get_tree().create_timer(2.6).timeout
		await _demo_click_lanjut()
		await get_tree().create_timer(1.6).timeout

	await get_tree().create_timer(1.2).timeout
	await _demo_act("open_map")
	await get_tree().create_timer(4.0).timeout

# ------------------------------------------------ permainan penuh (video)
## Menjalankan seluruh permainan: 6 wilayah sampai selesai, lalu post-test,
## SUS, dan penutup cerita — tanpa operator. Dipakai untuk merekam video.
func _demo_full() -> void:
	await _dw(1.6)
	Game.reset()
	if title_screen.get("start_btn") != null:
		await _demo_click(title_screen.start_btn)
	await _dw(1.2)

	var order := ["kota", "hutan", "pabrik", "candi", "danau", "source"]
	var only := OS.get_environment("TERRA_ONLY")
	if only != "":
		order = only.split(",")
		for b in ["nature", "core", "cipher", "aqua"]:
			if not Game.badges.has(b):
				Game.badges.append(b)
		_start_play(order[0])
		await _dw(1.5)
		await _demo_play_map(order[0])
		await _demo_asesmen()
		return
	for i in range(order.size()):
		var mid: String = order[i]
		if i > 0:
			# Bab III 3.6.4: komponen perangkat dibeli di Kota Unggul sebelum Map 5.
			if mid == "danau":
				await _demo_beli_komponen()
			await _demo_goto_map(mid)
		print("[demo] mulai wilayah ", mid)
		await _demo_play_map(mid)
		print("[demo] selesai wilayah ", mid, " — badge ", Game.badges.size())
		await _dw(1.0)
	await _demo_asesmen()
	print("[demo] SELESAI: badge=", Game.badges.size(), " tuntas=", Game.post_done, " sus=", Game.sus_done)

## Demo: kembali ke Kota Unggul dan membeli empat komponen perangkat IoT.
## Menampilkan alur Tabel 2.4/2.6 / Bab III 3.6.4 di dalam video.
func _demo_beli_komponen() -> void:
	if Game.all_components():
		return
	await _demo_goto_map("kota")
	# jalan ke Pedagang lalu bicara, supaya toko tidak muncul tiba-tiba
	var ped := {}
	for n in Content.npcs_of(Content.map_by_id("kota")):
		if str(n.get("action", "")) == "shop":
			ped = n
			break
	if not ped.is_empty():
		await _demo_path_walk(int(ped.get("x", 16)), int(ped.get("y", 10)))
		await _dw(0.6)
		await _demo_act("interact")
		await _dw(0.9)
		await _demo_dialog_all()
		await _dw(0.6)
	if not shop.visible:
		shop.open()
	await _dw(1.4)
	for id in Game.COMPONENT_IDS:
		if Game.has_component(str(id)):
			continue
		shop._buy(str(id))
		await _dw(1.1)
	await _dw(0.9)
	shop.visible = false
	await _dw(0.7)

## Pindah wilayah lewat layar Peta.
func _demo_goto_map(mid: String) -> void:
	var nm := str(Content.map_by_id(mid).get("name", mid)).to_upper()
	await _dw(1.2)
	if badge_popup != null and badge_popup.visible:
		await _demo_press_in(badge_popup, "Lanjut")
		await _dw(0.9)
	await _demo_act("open_map")
	await _dw(1.6)
	await _demo_click_map(nm)
	await _dw(2.4)
## Menyelesaikan satu wilayah: bicara NPC, cari objek, jawab semua tantangan.
func _demo_play_map(mid: String) -> void:
	var guard := 0
	while guard < 600:
		guard += 1
		if Game.is_map_cleared(mid):
			break
		if badge_popup != null and badge_popup.visible:
			await _demo_press_in(badge_popup, "Lanjut")
			await _dw(0.9)
			continue
		if puzzle.visible:
			await _demo_solve_current()
			await _dw(1.1)
			await _demo_click_lanjut()
			await _dw(0.9)
			continue
		if dialog.visible:
			await _demo_dialog_all()
			await _dw(0.4)
			continue
		var tgt := _demo_next_target(mid)
		if tgt.is_empty():
			await _dw(0.5)
			continue
		var tp: Vector2 = tgt["pos"]
		var tt := _demo_tile_of(tp)
		var appr := _demo_approach_tile(tt.x, tt.y)
		await _demo_path_walk(appr.x, appr.y)
		await _dw(0.3)
		# maju sedikit ke arah objek agar masuk radius interaksi
		var dv: Vector2 = tp - _world.player.position
		var key := "move_right" if dv.x > 0.0 else "move_left"
		if absf(dv.y) > absf(dv.x):
			key = "move_down" if dv.y > 0.0 else "move_up"
		Input.action_press(key)
		await _dw(0.35)
		_release_move_keys()
		await _dw(0.3)
		await _demo_act("interact")
		await _dw(0.9)
	await _dw(1.0)
	if badge_popup != null and badge_popup.visible:
		await _demo_press_in(badge_popup, "Lanjut")
		await _dw(1.0)

## Tujuan berikutnya: objek yang belum diambil, atau NPC pemberi tugas.
func _demo_next_target(mid: String) -> Dictionary:
	if _world == null:
		return {}
	for o in _world.objects:
		if not _world._object_active(o):
			continue
		var d: Dictionary = o.get("data", {})
		var ch := str(d.get("challenge", ""))
		if ch != "" and Game.done.has(ch):
			continue
		var on: Node2D = o.get("node")
		if on != null:
			return {"pos": on.position, "kind": "objek"}
	var quest_ids: Array = []
	for cn in Content.npcs_of(Content.map_by_id(mid)):
		if str(cn.get("action", "quest")) == "quest":
			quest_ids.append(str(cn.get("id", "")))
	for n in _world.npcs:
		if not quest_ids.is_empty() and not quest_ids.has(str(n.get("id", ""))):
			continue
		var nn: Node2D = n.get("node")
		if nn == null:
			continue
		return {"pos": nn.position, "kind": "npc"}
	return {}

## Tile di samping objek/NPC yang bisa dipijak (objek punya tabrakan sendiri).
func _demo_approach_tile(tx: int, ty: int) -> Vector2i:
	var solid: Array = _world.meta.get("solid", [])
	if solid.is_empty():
		return Vector2i(tx, ty)
	var h := solid.size()
	var w := (solid[0] as Array).size()
	var start := _demo_tile_of(_world.player.position)
	var best := Vector2i(tx, ty)
	var best_d := 1e9
	for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var c: Vector2i = Vector2i(tx, ty) + d
		if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
			continue
		if int((solid[c.y] as Array)[c.x]) != 0:
			continue
		if _world.prop_block.has(c):
			continue
		var dist := Vector2(c - start).length()
		if dist < best_d:
			best_d = dist
			best = c
	return best

## Menjawab tantangan yang sedang terbuka sesuai jenisnya (klik seperti pemain).
func _demo_solve_current() -> void:
	if not puzzle.visible:
		return
	var t := str(puzzle._c.get("type", "mcq"))
	match t:
		"mcq":
			var btns: Array = []
			for c in puzzle._body.get_children():
				if c is Button:
					btns.append(c)
			var a := int(puzzle._c.get("answer", 0))
			if a >= 0 and a < btns.size():
				await _demo_click(btns[a])
		"build":
			for p in puzzle._parts_select:
				var ob: OptionButton = p["node"]
				for i in range(ob.item_count):
					if ob.get_item_text(i) == str(p["answer"]):
						ob.select(i)
						break
				await _dw(0.25)
			await _demo_press_action("Jalankan Query")
		"order":
			for want in puzzle._c.get("items", []):
				for c in puzzle._pool_box.get_children():
					if c is Button and not c.is_queued_for_deletion() and str((c as Button).text) == str(want):
						await _demo_click(c)
						break
				await _dw(0.15)
			await _demo_press_action("Periksa Urutan")
		"craft":
			for want in puzzle._c.get("slots", []):
				for entry in puzzle._craft_pool_btns:
					var b: Button = entry["btn"]
					if str(entry["item"]) == str(want) and not b.disabled:
						await _demo_click(b)
						break
				await _dw(0.15)
			await _demo_press_action("Periksa Rakit")
		"wire":
			# Sambungkan kabel sesuai daftar sambungan benar, lalu nyalakan.
			for l in puzzle._c.get("links", []):
				var pa: Button = puzzle._wire_pins[str((l as Array)[0])]
				var pb: Button = puzzle._wire_pins[str((l as Array)[1])]
				await _demo_click(pa)
				await _dw(0.25)
				await _demo_click(pb)
				await _dw(0.3)
			await _demo_press_action("Nyalakan Perangkat")
		"cipher":
			var sh := int(puzzle._c.get("answer_shift", 0))
			var sl := _demo_find_slider(puzzle._body)
			if sl != null:
				for v in range(0, sh + 1):
					sl.value = v
					await _dw(0.14)
			await _demo_press_action("Periksa Jawaban")

func _demo_find_slider(n: Node) -> HSlider:
	if n is HSlider:
		return n
	for c in n.get_children():
		var r := _demo_find_slider(c)
		if r != null:
			return r
	return null

## Semua tombol pilihan (punya ButtonGroup) di dalam sebuah node, urut tampil.
func _demo_group_buttons(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and (n as Button).button_group != null:
			out.append(n)
		var kids := n.get_children()
		for i in range(kids.size() - 1, -1, -1):
			stack.append(kids[i])
	return out

func _demo_press_action(needle: String) -> void:
	for c in puzzle._action_row.get_children():
		if c is Button and not c.is_queued_for_deletion() and str((c as Button).text).findn(needle) >= 0:
			await _demo_click(c)
			return

func _demo_press_in(root: Node, needle: String) -> bool:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Button and not (n as Button).disabled and str((n as Button).text).findn(needle) >= 0:
			await _demo_click(n as Button)
			return true
		for c in n.get_children():
			stack.append(c)
	return false

## Mengisi post-test (jawaban benar), SUS, lalu penutup cerita.
func _demo_asesmen() -> void:
	var guard := 0
	while (asesmen == null or not asesmen.visible) and guard < 40:
		guard += 1
		await _dw(0.3)
	if asesmen == null:
		return
	if not asesmen.visible:
		_open_asesmen()
		await _dw(1.0)
	if asesmen._kode_edit != null:
		asesmen._kode_edit.text = "P01"
	await _dw(0.8)
	await _demo_press_in(asesmen, "Mulai")
	await _dw(1.0)

	var pg := 0
	while asesmen._stage == "posttest" and pg < 40:
		pg += 1
		var a := int(Game.posttest_items()[int(asesmen._qi)]["a"])
		var opts: Array = []
		for c in asesmen._box.get_children():
			if c is Button and (c as Button).button_group != null:
				opts.append(c)
		if a < opts.size():
			await _demo_click(opts[a])
		await _dw(0.45)
		if not await _demo_press_in(asesmen, "Berikutnya"):
			await _demo_press_in(asesmen, "Kumpulkan post-test")
		await _dw(0.6)

	await _dw(1.2)
	await _demo_press_in(asesmen, "SUS")
	await _dw(1.0)

	var sg := 0
	while asesmen._stage == "sus" and sg < 20:
		sg += 1
		var val := 4 if int(asesmen._qi) % 2 == 0 else 2
		var sopt := _demo_group_buttons(asesmen._box)
		if val - 1 < sopt.size():
			await _demo_click(sopt[val - 1])
		await _dw(0.4)
		if not await _demo_press_in(asesmen, "Berikutnya"):
			await _demo_press_in(asesmen, "Kumpulkan SUS")
		await _dw(0.6)

	await _dw(1.6)
	await _demo_press_in(asesmen, "Lihat penutup cerita")
	await _dw(1.6)
	# pilih keputusan akhir (tombol pertama pada panel keputusan)
	await _demo_press_in(_modal_layer, "Putus aliran data")
	await _dw(2.0)

## Jeda singkat agar rekaman tetap enak ditonton.
func _dw(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

## Menekan tombol "Masuk" pada kartu wilayah tertentu.
func _demo_click_map(map_name: String) -> void:
	for card in map_screen._grid.get_children():
		var hit := false
		for n in card.find_children("*", "Label", true, false):
			if str((n as Label).text).to_upper().findn(map_name.to_upper()) >= 0:
				hit = true
				break
		if hit:
			for n in card.find_children("*", "Button", true, false):
				if not (n as Button).disabled:
					await _demo_click(n as Button)
					return

## Menekan tombol yang teksnya mengandung `needle`.
func _demo_click_text(needle: String) -> void:
	var stack: Array = [map_screen]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Button and str((n as Button).text).findn(needle) >= 0 and not (n as Button).disabled:
			await _demo_click(n as Button)
			return
		for c in n.get_children():
			stack.append(c)

## Objek terdekat dari posisi pemain pada peta yang sedang dimuat.
func _demo_nearest_object() -> Vector2i:
	if _world == null or _world.player == null:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_d := 1e9
	for o in _world.objects:
		var node: Node2D = o.get("node")
		if node == null:
			continue
		var d: float = node.position.distance_to(_world.player.position)
		if d < best_d:
			best_d = d
			best = _demo_tile_of(node.position)
	return best

func _demo_tile_of(p: Vector2) -> Vector2i:
	var t := 48.0
	if _world != null:
		t = float(_world._tile_size())
	return Vector2i(int(floor(p.x / t)), int(floor(p.y / t)))

## Berjalan mengikuti jalur BFS agar tidak tersangkut collision.
func _demo_path_walk(tx: int, ty: int) -> void:
	if _world == null or _world.player == null:
		return
	var solid: Array = _world.meta.get("solid", [])
	if solid.is_empty():
		await _demo_walk_to(tx, ty)
		return
	var h := solid.size()
	var w := (solid[0] as Array).size()
	var start := _demo_tile_of(_world.player.position)
	var goal := Vector2i(tx, ty)
	if start == goal:
		return
	var prev := {}
	var seen := {start: true}
	var queue: Array = [start]
	var found := false
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == goal:
			found = true
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cur + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			if seen.has(n):
				continue
			if int((solid[n.y] as Array)[n.x]) == 1:
				continue
			if _world.prop_block.has(n):
				continue
			seen[n] = true
			prev[n] = cur
			queue.append(n)
	if not found:
		await _demo_walk_to(tx, ty)
		return
	var path: Array = []
	var node := goal
	var guard := 0
	while node != start and guard < 2000:
		guard += 1
		path.push_front(node)
		node = prev[node]
	for step in path:
		await _demo_walk_to(step.x, step.y, false)

## Menghabiskan dialog yang sedang terbuka (menunggu efek mengetik).
func _demo_dialog_all() -> void:
	var guard := 0
	while dialog.visible and guard < 14:
		guard += 1
		var waited := 0.0
		while dialog.is_typing() and waited < 6.0:
			await get_tree().create_timer(0.2).timeout
			waited += 0.2
		await get_tree().create_timer(1.2).timeout
		await _demo_act("interact")
		await get_tree().create_timer(0.6).timeout

## Tile NPC pemberi tugas pada peta yang sedang dimuat.
func _demo_quest_tile() -> Vector2:
	var m := Content.map_by_id(current_map)
	for n in Content.npcs_of(m):
		if str(n.get("action", "quest")) == "quest":
			return Vector2(int(n.get("x", 20)), int(n.get("y", 10)))
	return Vector2(20, 10)

## Menekan tombol arah seperti pemain sungguhan sampai mendekati target.
func _demo_walk_to(tx: int, ty: int, pause := true) -> void:
	if _world == null or _world.player == null:
		return
	var target: Vector2 = _world.tile_center(tx, ty)
	# Batas iterasi mengikuti jarak: 120 frame hanya cukup untuk ±2 detik jalan,
	# jadi jarak jauh butuh anggaran frame yang lebih besar.
	var dist: float = _world.player.position.distance_to(target)
	var guard := 0
	var guard_max := int(dist / 190.0 * 70.0) + 240
	var last: Vector2 = _world.player.position
	var stuck := 0
	while _world.player.position.distance_to(target) > 36.0 and guard < guard_max:
		guard += 1
		var d: Vector2 = target - _world.player.position
		_release_move_keys()
		if absf(d.x) > 5.0:
			Input.action_press("move_right" if d.x > 0.0 else "move_left")
		if absf(d.y) > 5.0:
			Input.action_press("move_down" if d.y > 0.0 else "move_up")
		await get_tree().physics_frame
		if _world.player.position.distance_to(last) < 0.8:
			stuck += 1
		else:
			stuck = 0
			last = _world.player.position
		if stuck > 10:
			# tersangkut di sudut: geser tegak lurus sebentar
			_release_move_keys()
			if absf(d.x) >= absf(d.y):
				Input.action_press("move_down" if d.y >= 0.0 else "move_up")
			else:
				Input.action_press("move_right" if d.x >= 0.0 else "move_left")
			for i in range(8):
				await get_tree().physics_frame
			stuck = 0
			last = _world.player.position
	_release_move_keys()
	if pause:
		await get_tree().create_timer(0.2).timeout

func _release_move_keys() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)

func _demo_click(c: Control) -> void:
	var p: Vector2 = c.get_global_rect().get_center()
	Input.warp_mouse(p)
	await get_tree().process_frame
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	get_viewport().push_input(mv)
	await get_tree().create_timer(0.25).timeout
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.pressed = true
	d.position = p
	d.global_position = p
	get_viewport().push_input(d)
	await get_tree().create_timer(0.12).timeout
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	u.position = p
	u.global_position = p
	get_viewport().push_input(u)
	await get_tree().create_timer(0.25).timeout

func _demo_act(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	get_viewport().push_input(ev)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	get_viewport().push_input(up)
	await get_tree().process_frame

func _demo_answer() -> void:
	if not puzzle.visible:
		return
	var ans := int(puzzle._c.get("answer", 0))
	var btns: Array = []
	for c in puzzle._body.get_children():
		if c is Button:
			btns.append(c)
	if ans < btns.size():
		await _demo_click(btns[ans])

func _demo_click_lanjut() -> void:
	if not puzzle.visible:
		return
	# Utamakan tombol "Lanjut"; tombol periksa bisa masih menunggu queue_free().
	for c in puzzle._action_row.get_children():
		if c is Button and not c.is_queued_for_deletion() and str(c.text).findn("Lanjut") >= 0:
			await _demo_click(c)
			return
	for c in puzzle._action_row.get_children():
		if c is Button and not c.is_queued_for_deletion():
			await _demo_click(c)
			return

func _new_screen(script: Script) -> Control:
	var c: Control = script.new()
	_screens.add_child(c)
	c.visible = false
	return c

func _ensure_inputs() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
		"open_map": [KEY_M],
		"open_journal": [KEY_J],
	}
	for action in map.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

# ------------------------------------------------------------------ layar
func _hide_all() -> void:
	_hide_toast()
	# Panel tantangan bisa tertutup tanpa lewat tombol tutup; kembalikan tema dasar
	# supaya HUD, dialog, dan peta tidak ikut memakai bahan wilayah terakhir.
	UiKit.set_theme("")
	title_screen.visible = false
	map_screen.visible = false
	research_screen.visible = false
	ending_screen.visible = false
	if asesmen != null:
		asesmen.visible = false
	if pause_menu != null:
		pause_menu.visible = false
	if journal != null:
		journal.visible = false
	if badges_screen != null:
		badges_screen.visible = false
	# Jangan pernah meninggalkan pohon scene dalam keadaan dijeda saat pindah
	# layar, karena semua animasi dan masukan akan berhenti.
	get_tree().paused = false
	hud.visible = false

func _show_title() -> void:
	state = "title"
	_hide_all()
	title_screen.visible = true
	_world_holder.visible = false
	Game.set_prompt("")
	_fade_out()

func _open_maps() -> void:
	var prev := state
	state = "map"
	_hide_all()
	map_screen.visible = true
	map_screen.refresh()

	map_screen.set_meta("prev", prev)

func _on_map_back() -> void:
	if str(map_screen.get_meta("prev", "title")) == "playing":
		state = "playing"
		_hide_all()
		hud.visible = true
		_world_holder.visible = true
	else:
		_show_title()

func _on_map_chosen(id: String) -> void:
	_load_map(id)
	state = "playing"
	_hide_all()
	hud.visible = true
	_world_holder.visible = true

func _open_research() -> void:
	var prev := state
	state = "research"
	_hide_all()
	research_screen.visible = true
	research_screen.set_meta("prev", prev)
	if research_screen.has_method("refresh"):
		research_screen.refresh()

## Membuka asesmen akhir (post-test 20 soal + SUS) sebagai modal di dalam game.
func _open_asesmen() -> void:
	if asesmen == null:
		return
	dialog.visible = false
	puzzle.visible = false
	_hide_toast()
	asesmen.open()

func _on_asesmen_finished() -> void:
	_show_ending_choice()

func _on_research_back() -> void:
	if str(research_screen.get_meta("prev", "title")) == "playing":
		state = "playing"
		_hide_all()
		hud.visible = true
		_world_holder.visible = true
	else:
		_show_title()

func _show_ending() -> void:
	state = "ending"
	_hide_all()
	ending_screen.visible = true
	if ending_screen.has_method("refresh"):
		ending_screen.refresh()

# ------------------------------------------------------------------ alur
func _on_new_game() -> void:
	Game.reset()
	_start_play("kota")

func _on_continue() -> void:
	if Game.load_game():
		_start_play(Game.current_map)

func _start_play(map_id: String) -> void:
	state = "playing"
	_hide_all()
	hud.visible = true
	_world_holder.visible = true
	_load_map(map_id)
	_fade_out()

func _load_map(id: String) -> void:
	current_map = id
	Game.current_map = id
	Game.play_bgm("bgm_final" if id == "source" else "bgm_explore")
	if _world and is_instance_valid(_world):
		_world.queue_free()
	_world = WORLD_SCRIPT.new()
	_world_holder.add_child(_world)
	_world.build(id)
	_world.talk_to_npc.connect(_on_talk_npc)
	_world.inspect_object.connect(_on_inspect_object)
	_world.enter_portal.connect(_on_enter_portal)
	_world.objective_changed.connect(_on_objective)
	hud.set_map(Content.map_by_id(id))
	Game.set_prompt("")
	Game.save_game()

	await get_tree().process_frame
	var m := Content.map_by_id(id)
	if Game.is_map_cleared(id):
		_toast_msg("Wilayah selesai — cari gerbang bercahaya di tepi peta", 2.6)
	else:
		var target := _first_object_label(m)
		if target != "":
			_toast_msg("Cari %s — tanda ? di peta. Bicara ke NPC untuk materi." % target, 3.4)

## Objek pertama pada peta dipakai sebagai penunjuk arah quest.
func _first_object_label(m: Dictionary) -> String:
	for o in m.get("objects", []):
		return str(o.get("label", ""))
	return ""

func _open_dialog(n: Dictionary, lines: Array, intent: String) -> void:
	_dialog_intent = intent
	dialog.open(str(n.get("name", "NPC")), str(n.get("role", "")), lines, str(n.get("sprite", "")))

## Panah tujuan: tampil hanya saat bermain bebas (tanpa panel terbuka).
func _on_objective(info: Dictionary) -> void:
	if hud == null or _world == null or not is_instance_valid(_world):
		return
	var busy := state != "playing"
	if puzzle != null and is_instance_valid(puzzle) and puzzle.visible:
		busy = true
	if dialog != null and is_instance_valid(dialog) and dialog.visible:
		busy = true
	if busy or info.is_empty():
		hud.set_objective(Vector2.ZERO, Vector2.ZERO, "")
		return
	hud.set_objective(info["pos"], _world.player.position, str(info["name"]))

func _on_talk_npc(npc_id: String) -> void:
	var m := Content.map_by_id(current_map)
	var n := Content.npc_by_id(m, npc_id)
	if n.is_empty():
		return
	var action := str(n.get("action", "quest"))
	# Setiap NPC membuka ceritanya sendiri sebelum urusan lain.
	_npc_quest = ""
	var lines: Array = []
	for s in n.get("story", []):
		lines.append(str(s))
	var ctx: Array = n.get("dialog", [])
	var tawaran := ""
	if n.has("challenge") and not Game.done.has(str(n["challenge"])):
		tawaran = "Aku butuh bantuanmu. Selesaikan puzzle di dekatku — kalau gagal, nyawamu habis."
	if action == "shop":
		lines.append_array(ctx)
		_open_dialog(n, lines, "shop")
		return
	if action == "gate":
		lines.append_array(_gate_lines())
		_open_dialog(n, lines, "gate")
		return
	if action == "info":
		lines.append_array(ctx)
		if tawaran != "":
			_npc_quest = str(n["challenge"])
			lines.append(tawaran)
		_open_dialog(n, lines, "npcquest" if _npc_quest != "" else "info")
		return
	if not ctx.is_empty():
		lines.append("%s. %s" % [str(n.get("role", "")), str(ctx[0])])
	lines.append_array(_lesson_lines(m))
	if tawaran != "":
		_npc_quest = str(n["challenge"])
		lines.append(tawaran)
	else:
		lines.append("Quest lain bisa dimulai dari benda bertanda ? di peta.")
	_open_dialog(n, lines, "npcquest" if _npc_quest != "" else "info")

## Pelajaran muncul hanya saat berbicara dengan NPC pengajar.
func _lesson_lines(m: Dictionary) -> Array:
	var lines: Array = ["Materi %s — pilih soal dan contoh pada objek bertanda ? di peta." % str(m.get("material", "wilayah"))]
	for ch in m.get("challenges", []):
		if ch.has("lesson"):
			lines.append("%s: %s" % [str(ch.get("title", "Konsep")), str(ch["lesson"].get("text", ""))])
		elif ch.has("explain"):
			lines.append("%s: %s" % [str(ch.get("title", "Konsep")), str(ch.get("explain", ""))])
	return lines

## Dialog konteks wilayah. Materi pembelajaran tetap khusus lewat NPC pengajar.
func _intro_lines(m: Dictionary) -> Array:
	if str(m.get("id", "")) != "danau":
		return m["intro"]
	if Game.all_components():
		return [
			"Kamu sudah membawa keempat komponen perangkat dari toko Kota Unggul — lengkap.",
			"Pasang semuanya di tantangan merakit: papan rangkaian sebagai dasar, sensor pH sebagai masukan, mikrokontroler sebagai pengolah data, dan sumber daya agar perangkat menyala.",
			"Setelah perangkat hidup, kita baca data sensor lalu kirimkan ke dasbor."
		]
	if Game.component_count() > 0:
		var nama: Array[String] = []
		for id in Game.missing_components():
			nama.append(Game.component_name(str(id)))
		return [
			"Perangkatmu belum lengkap (%d dari %d komponen)." % [Game.component_count(), Game.COMPONENT_TOTAL],
			"Yang masih kurang: %s. Semuanya dijual Pedagang di Kota Unggul." % ", ".join(nama),
			"Setelah keempat komponen lengkap, kembali ke sini dan rakit perangkatnya."
		]
	return m["intro"]

func _on_inspect_object(obj_id: String) -> void:
	var m := Content.map_by_id(current_map)
	var o := {}
	for it in m.get("objects", []):
		if str(it["id"]) == obj_id:
			o = it
			break
	if o.is_empty():
		return
	_pending_object = obj_id
	_dialog_intent = "object"
	dialog.open(str(o.get("label", "Temuan")), "Objek ditemukan", o.get("text", []))

## Setelah dialog objek: buka tantangan terkait.
func _resolve_object() -> void:
	var m := Content.map_by_id(current_map)
	var o := {}
	for it in m.get("objects", []):
		if str(it["id"]) == _pending_object:
			o = it
			break
	_pending_object = ""
	if o.is_empty():
		return
	if bool(o.get("puzzle", false)):
		_open_next_puzzle_challenge()
		return
	if bool(o.get("bank", false)):
		_open_next_bank_challenge()
	elif o.has("challenge"):
		var challenge := _challenge_by_id(str(o["challenge"]))
		if str(challenge.get("type", "")) in ["craft", "wire"] and not Game.all_components():
			_toast_msg("Komponen belum lengkap — beli di toko Kota Unggul.", 3.0)
			return
		_open_challenge(str(o["challenge"]))

func _challenge_by_id(cid: String) -> Dictionary:
	for ch in Content.map_by_id(current_map).get("challenges", []):
		if str(ch.get("id", "")) == cid:
			return ch
	return {}

## Terminal objek memulai satu soal bank; pemain harus kembali ke terminal
## untuk setiap soal berikutnya, bukan otomatis berpindah quest.
func _open_next_bank_challenge() -> void:
	var m := Content.map_by_id(current_map)
	for i in range(m["challenges"].size()):
		var ch: Dictionary = m["challenges"][i]
		if ch.has("bank_materi") and not Game.done.has(str(ch["id"])):
			puzzle.open(_with_boss(ch, m), i, m["challenges"].size())
			return
	_toast_msg("Semua soal terminal di wilayah ini selesai.", 2.5)

func _open_next_puzzle_challenge() -> void:
	var m := Content.map_by_id(current_map)
	for i in range(m["challenges"].size()):
		var ch: Dictionary = m["challenges"][i]
		if ch.has("puzzle_bank") and not Game.done.has(str(ch["id"])):
			puzzle.open(_with_boss(ch, m), i, m["challenges"].size())
			return
	_toast_msg("Semua puzzle di wilayah ini selesai.", 2.5)

func _open_challenge(cid: String) -> void:
	_toast.modulate.a = 0.0
	var m := Content.map_by_id(current_map)
	var chs: Array = m["challenges"]
	for i in range(chs.size()):
		if str(chs[i]["id"]) == cid:
			puzzle.open(_with_boss(chs[i], m), i, chs.size())
			return

## Menambahkan status HP boss pada tantangan di map final.
func _with_boss(ch: Dictionary, m: Dictionary) -> Dictionary:
	if not m.has("boss"):
		return ch
	var out := ch.duplicate(true)
	var total := (m["challenges"] as Array).size()
	out["boss_hp"] = total - Game.map_done(str(m["id"]))
	out["boss_max"] = total
	out["boss_name"] = str((m["boss"] as Dictionary).get("name", "BOSS"))
	return out

## Kalimat penjaga gerbang menyesuaikan syarat wilayah berikutnya.
func _gate_lines() -> Array:
	var nxt := Game.next_map_id(current_map)
	if not Game.is_map_cleared(current_map):
		return [
			"Gerbang ini hanya terbuka bagi yang sudah membuktikan diri.",
			"Selesaikan dulu seluruh tantangan wilayah ini, lalu kembali ke sini."
		]
	if nxt == "":
		return ["Tidak ada jalan setelah ini. Yang tersisa hanya sumbernya sendiri."]
	if Game.map_unlocked(nxt):
		var nm := Content.map_by_id(nxt)
		return [
			"Kamu memenuhi syarat. Gerbang menuju %s sudah terbuka." % str(nm.get("name", "")),
			"Jalan ke tepi peta, di sana ada portal bercahaya."
		]
	return [
		"Wilayah berikutnya: %s." % str(Content.map_by_id(nxt).get("name", "")),
		"Syaratnya %s." % Game.unlock_hint(nxt),
		"Penuhi dulu, baru gerbang ini mau membuka."
	]

func _on_dialog_finished() -> void:
	if state != "playing":
		return
	var intent := _dialog_intent
	_dialog_intent = ""
	if intent == "shop":
		shop.open()
		return
	if intent == "object":
		_resolve_object()
		return
	if intent == "npcquest":
		var cid := _npc_quest
		_npc_quest = ""
		if cid != "" and not Game.done.has(cid):
			_open_challenge(cid)
		return
	if intent == "outro":
		var nxt := Game.next_map_id(current_map)
		if nxt != "" and Game.map_unlocked(nxt):
			_toast_msg("%s telah terbuka. Lanjutkan dari Peta Wilayah." % str(Content.map_by_id(nxt).get("name", "")), 3.0)

func _on_puzzle_solved(challenge_id: String) -> void:
	var was_cleared := Game.is_map_cleared(current_map)
	var coins_before := Game.coins
	Game.complete_challenge(challenge_id, current_map)
	if reward_popup != null and Game.coins > coins_before:
		reward_popup.show_reward(Game.coins - coins_before)
	_toast.text = "Quest selesai — %d/%d tantangan" % [Game.map_done(current_map), Game.map_total(current_map)]
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 0.0, 1.2).set_delay(0.5)

	if Game.is_map_cleared(current_map) and not was_cleared:
		if current_map == "source":
			# Map terakhir tidak memberi badge (Tabel 2.6): lanjut ke post-test.
			await get_tree().create_timer(1.2).timeout
			_open_asesmen()
		return  # badge popup akan muncul lewat signal
	await get_tree().create_timer(0.35).timeout
	if state == "playing" and not Game.is_map_cleared(current_map):
		_toast_msg("Quest selesai. Lanjutkan lewat objek bertanda ? di peta.", 2.6)

## Nyawa habis: seluruh progres dan badge dihapus, tetapi uang, item, dan
## komponen yang sudah dibeli tetap tersimpan. Pemain mulai lagi dari Kota Unggul.
func _on_map_failed(map_id: String) -> void:
	if puzzle != null and is_instance_valid(puzzle):
		puzzle.visible = false
	_toast_msg("Nyawa habis — semua progres dan badge direset. Uang dan barang tetap tersimpan.", 4.0)
	await get_tree().create_timer(2.0).timeout
	if state == "playing":
		_start_play("kota")
		await get_tree().process_frame
		_toast_msg("Mulai lagi dari Kota Unggul. Bicara ke NPC pengajar untuk materi, lalu cari objek bertanda ?.", 3.6)

func _on_map_completed(map_id: String) -> void:
	if _world and is_instance_valid(_world) and _world.portal_node:
		_world.portal_node.locked = false
	_toast.text = "Wilayah selesai — portal terbuka"
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 0.0, 2.4).set_delay(1.2)

func _on_badge_earned(badge_id: String, badge_name: String) -> void:
	_pending_badge = badge_id
	await get_tree().create_timer(0.6).timeout
	badge_popup.show_badge(badge_id, badge_name)

func _on_badge_closed() -> void:
	_pending_badge = ""
	_show_outro()

## Penutup wilayah: hanya sekali per wilayah, agar alur cerita tetap utuh
## tanpa mengulang dialog setiap kali pemain kembali.
func _show_outro() -> void:
	var lines := Content.outro_of(current_map)
	if lines.is_empty() or Game.outro_seen.has(current_map):
		return
	Game.outro_seen[current_map] = true
	Game.save_game()
	var m := Content.map_by_id(current_map)
	dialog.open(str(m.get("npc_name", "Pemandu")), "Penutup wilayah", lines, str(m.get("npc_sprite", "")))
	_dialog_intent = "outro"

## Keputusan pemain di akhir menentukan teks ending (sesuai Bab II 2.6).
func _show_ending_choice() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.075, 0.105, 0.16, 0.99), UiKit.DANGER, 14, 2))
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)

	var v := UiKit.vbox(12)
	panel.add_child(v)
	v.add_child(UiKit.title("KEPUTUSAN TERAKHIR", 16, UiKit.DANGER))
	v.add_child(UiKit.label("Sumber sudah lumpuh. Yang tersisa adalah keputusanmu: memutus aliran datanya, atau menyusun ulang protokol agar danau tetap terpantau.", 15, UiKit.TEXT, 660))

	var b1 := UiKit.button("Putus aliran data dan segel sumber", 15)
	b1.pressed.connect(func(): _choose_ending("seal", [dim, center]))
	v.add_child(b1)
	var b2 := UiKit.button("Susun ulang protokol agar data tetap mengalir", 15, UiKit.BLUE)
	b2.pressed.connect(func(): _choose_ending("flow", [dim, center]))
	v.add_child(b2)

func _choose_ending(id: String, nodes: Array) -> void:
	Game.set_ending_choice(id)
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	_show_ending()

func _on_enter_portal() -> void:
	if not Game.is_map_cleared(current_map):
		Game.sfx("sfx_err")
		_toast.text = "Gerbang terkunci — selesaikan semua tantangan wilayah ini"
		_toast.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_property(_toast, "modulate:a", 0.0, 1.8).set_delay(1.0)
		return
	var nxt := Game.next_map_id(current_map)
	if nxt == "":
		Game.sfx("sfx_portal")
		# Map 6 selesai: kerjakan post-test & SUS lebih dahulu (Bab III 3.10).
		if not Game.assessment_complete():
			_open_asesmen()
		else:
			_show_ending_choice()
		return
	if not Game.map_unlocked(nxt):
		_toast.text = "Terkunci — " + Game.unlock_hint(nxt)
		_toast.modulate.a = 1.0
		var tw2 := create_tween()
		tw2.tween_property(_toast, "modulate:a", 0.0, 1.8).set_delay(1.0)
		return
	_fade_in_then(func(): _load_map(nxt))
	Game.sfx("sfx_portal")

## Pesan singkat di tengah atas. Disembunyikan saat pindah layar supaya tidak
## menembus Peta Wilayah, menu, atau layar akhir.
func _toast_msg(text: String, dur: float) -> void:
	if _toast == null:
		return
	if state == "title" or state == "map" or state == "research" or state == "ending":
		return
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, dur).set_delay(0.6)

func _hide_toast() -> void:
	if _toast == null:
		return
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast.text = ""
	_toast.modulate.a = 0.0

func _fade_in_then(cb: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.18)
	tw.tween_callback(cb)
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)

func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)

# ------------------------------------------------------------- jeda & jurnal
## Layar jeda hanya masuk akal saat bermain. Panel tantangan/dialog/toko yang
## sedang terbuka ditutup lebih dulu lewat Esc, baru layar jeda.
func _open_pause() -> void:
	if state != "playing" or _world == null:
		return
	if dialog.visible or puzzle.visible or shop.visible or asesmen.visible:
		return
	_hide_toast()
	pause_menu.open(current_map)
	# HUD ikut disembunyikan: kalau tidak, angka badge/uang/nyawa mengapung di
	# atas lapisan gelap panel jeda dan terbaca seolah masih bermain.
	hud.visible = false
	get_tree().paused = true

func _close_pause() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	hud.visible = state == "playing"

func _open_journal(from_pause: bool) -> void:
	if journal.visible:
		return
	if not from_pause and (dialog.visible or puzzle.visible or shop.visible):
		return
	_hide_toast()
	journal.open(current_map if state == "playing" else "kota")
	hud.visible = false
	get_tree().paused = true

func _on_journal_closed() -> void:
	get_tree().paused = false
	hud.visible = state == "playing"

## "Tandai" hanya menaruh penanda di peta; tidak mengubah progres apa pun.
func _on_journal_mark(kind: String, id: String, label: String) -> void:
	get_tree().paused = false
	if _world == null:
		return
	hud.visible = state == "playing"
	var target := ("obj:" if kind == "benda" else "npc:") + id
	if _world.mark_objective(target):
		_toast_msg("Ditandai: %s" % label, 2.6)
	else:
		_toast_msg("Sasaran itu sudah selesai.", 2.4)

## Koleksi badge dibuka dari angka badge di HUD. Sama seperti jurnal, layar ini
## menjeda permainan supaya pemain tidak diserang saat membaca.
func _open_badges() -> void:
	if state != "playing" or puzzle.visible or dialog.visible or shop.visible:
		return
	_hide_toast()
	badges_screen.open()
	hud.visible = false
	get_tree().paused = true

func _on_badges_closed() -> void:
	get_tree().paused = false
	hud.visible = state == "playing"

## Pengaturan dari layar judul: panel yang sama, mode tanpa tombol aksi, dan
## tanpa menjeda pohon scene (di judul belum ada yang berjalan).
func _open_settings_from_title() -> void:
	pause_menu.open_settings()

func _on_settings_closed() -> void:
	get_tree().paused = false

func _on_restart_map(map_id: String) -> void:
	get_tree().paused = false
	Game.restart_map(map_id)
	_toast_msg("Wilayah diulang. Uang, barang, dan badge tetap tersimpan.", 3.2)
	_fade_in_then(func(): _load_map(map_id))

func _on_pause_to_title() -> void:
	get_tree().paused = false
	_show_title()

# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	# Mode Riset dipakai untuk mengambil data pengujian, bukan fitur pemain.
	# Tombolnya tidak dipasang di menu utama; dibuka dengan Ctrl+R dari judul
	# atau layar peta supaya pemain biasa tidak tersandung ke layar data.
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.ctrl_pressed and k.physical_keycode == KEY_R:
			if state == "title" or state == "map":
				_open_research()
				get_viewport().set_input_as_handled()
			return
	if asesmen != null and asesmen.visible:
		return
	if event.is_action_pressed("interact"):
		if dialog.visible:
			dialog.advance()
			get_viewport().set_input_as_handled()
			return
		if state == "playing" and _world and not puzzle.visible and not shop.visible:
			if _world.try_interact():
				get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("open_map") and state == "playing" and not puzzle.visible and not dialog.visible:
		_open_maps()
		return

	if event.is_action_pressed("open_journal") and state == "playing" and not puzzle.visible and not dialog.visible:
		_open_journal(false)
		return

	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			_close_pause()
			return
		if journal.visible:
			journal.visible = false
			get_tree().paused = false
			return
		if badges_screen.visible:
			badges_screen._on_close()
			return
		if shop.visible:
			shop.visible = false
			return
		if puzzle.visible:
			puzzle._on_close()
		elif state == "map" or state == "research":
			if state == "map":
				_on_map_back()
			else:
				_on_research_back()
		elif state == "playing":
			_open_pause()


func _auto_shot(path: String, delay: float) -> void:
	if delay <= 0.0:
		delay = 4.0
	await get_tree().create_timer(delay).timeout
	if _world and _world.player:
		print("SHOT player=", _world.player.position)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT ", path, " ", img.get_size())
	get_tree().quit()


func _auto_frames(dir: String, secs: float) -> void:
	if secs <= 0.0:
		secs = 72.0
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.6).timeout
	var fps := 15.0
	var total := int(secs * fps)
	for i in range(total):
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/f_%05d.png" % [dir, i])
		await get_tree().create_timer(1.0 / fps).timeout
	print("FRAMES ", total)
	get_tree().quit()


func _dump_later() -> void:
	await get_tree().create_timer(6.5).timeout
	_walk(get_tree().root, 0)


func _walk(n: Node, d: int) -> void:
	if n is Control:
		var c := n as Control
		var r := c.get_global_rect()
		if c.is_visible_in_tree() and r.size.x > 300.0:
			print("DUMPC ", " ".repeat(d), n.name, " ", c.get_class(), " rect=", r, " a=", c.modulate.a,
				" color=", (c as ColorRect).color if c is ColorRect else "-")
	for ch in n.get_children():
		_walk(ch, d + 1)