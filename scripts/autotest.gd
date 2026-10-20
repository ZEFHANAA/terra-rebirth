extends Node
## Uji integrasi otomatis: menjalankan alur permainan tanpa interaksi manual.
## Jalankan: godot --headless --path . res://scenes/AutoTest.tscn

var main: Node
var fails := 0
var checks := 0

func _ready() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await run()
	print("\n=== HASIL: %d cek, %d gagal ===" % [checks, fails])
	get_tree().quit(1 if fails > 0 else 0)

func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", label)
	else:
		fails += 1
		print("  FAIL ", label)

func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func press_e() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_E
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var up := InputEventKey.new()
	up.physical_keycode = KEY_E
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame

func run() -> void:
	print("== Mulai uji ==")
	Game.reset()
	main._on_new_game()
	await wait(0.6)

	check(main.state == "playing", "state masuk ke playing")
	check(not main.dialog.visible, "dialog tidak terbuka otomatis (harus dekati NPC)")
	check(main._world.npcs.size() == 4, "Kota Unggul punya 4 NPC")
	check(main._quest_npc_name(Content.map_by_id("kota")) == "Kepala Kota", "NPC pemberi tugas terdaftar")

	# --- bicara ke Kepala Kota, lalu selesaikan dialog
	main._on_talk_npc("kepala")
	await wait(0.25)
	check(main.dialog.visible, "dialog terbuka setelah bicara dengan NPC")
	for i in range(9):
		await press_e()
		await wait(0.12)
	check(not main.dialog.visible, "dialog tertutup setelah lanjut")
	check(main.puzzle.visible, "tantangan pertama terbuka setelah dialog")

	# --- pedagang: dialog lalu toko, bisa membeli item
	main.puzzle._on_close()
	await wait(0.2)
	Game.coins = 50
	Game.coins_changed.emit(Game.coins)
	main._on_talk_npc("pedagang")
	await wait(0.25)
	for i in range(6):
		await press_e()
		await wait(0.1)
	await wait(0.3)
	check(main.shop.visible, "toko terbuka setelah dialog pedagang")
	main.shop._buy("lensa")
	await wait(0.15)
	check(Game.item_count("lensa") == 1, "Lensa Analisis terbeli")
	check(Game.coins == 30, "keping berkurang sesuai harga")
	main.shop.visible = false

	# --- penjaga gerbang memberi syarat wilayah berikutnya
	main._on_talk_npc("gerbang")
	await wait(0.25)
	check(main.dialog.visible, "penjaga gerbang bisa diajak bicara")
	main.dialog.visible = false
	main._dialog_intent = ""

	# --- objek pencarian di Hutan membuka tantangan
	Game.xp = 999
	main._load_map("hutan")
	await wait(0.3)
	check(main._world.objects.size() == 3, "Hutan punya 3 objek pencarian")
	main._on_inspect_object("hutan-cari-1")
	await wait(0.25)
	check(main.dialog.visible, "objek menampilkan temuan")
	for i in range(5):
		await press_e()
		await wait(0.12)
	await wait(0.2)
	check(main.puzzle.visible, "tantangan terbuka setelah memeriksa objek")
	main.puzzle._on_close()
	main.dialog.visible = false
	main._dialog_intent = ""
	await wait(0.2)

	# --- komponen Danau & gating perakitan
	main._load_map("danau")
	await wait(0.3)
	main._on_inspect_object("danau-kom-1")
	await wait(0.2)
	for i in range(4):
		await press_e()
		await wait(0.1)
	await wait(0.2)
	check(Game.has_component("sensor"), "komponen sensor tersimpan")
	Game.done["danau-1"] = true
	main._open_next_challenge()
	await wait(0.3)
	check(not main.puzzle.visible, "perakitan terkunci sebelum komponen lengkap")

	# --- selesaikan seluruh tantangan tiap peta
	Game.components = {"sensor": true, "mcu": true, "wifi": true}
	for m in Content.MAPS:
		var mid: String = m["id"]
		Game.xp = 999
		Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
		main._load_map(mid)
		await wait(0.3)
		main.dialog.visible = false
		for ci in range((m["challenges"] as Array).size()):
			var ch: Dictionary = m["challenges"][ci]
			main._open_next_challenge()
			await wait(0.15)
			if not main.puzzle.visible:
				check(false, "puzzle terbuka untuk %s" % ch["id"])
				continue
			_solve(ch)
			await wait(0.15)
			# klik tombol Lanjut di panel
			if main.puzzle._action_row.get_child_count() > 0:
				main.puzzle._action_row.get_child(0).pressed.emit()
			await wait(0.2)
		check(Game.done.has(str((m["challenges"] as Array)[0]["id"])), "tantangan %s tercatat" % mid)

	# --- aturan badge & level
	Game.reset()
	Game.xp = 0
	Game.complete_challenge("kota-1", "kota")
	check(Game.coins == 10, "tantangan memberi 10 keping data")
	check(Game.badges.is_empty(), "badge belum diberikan di tengah peta")
	Game.complete_challenge("kota-2", "kota")
	check(Game.xp == 60, "XP bertambah 30 per tantangan")
	check(Game.level() == 2, "level naik ke 2 pada 60 XP")
	check(Game.map_unlocked("hutan"), "hutan terbuka di level 2")
	check(not Game.map_unlocked("pabrik"), "pabrik masih terkunci tanpa badge nature")

	Game.complete_challenge("hutan-1", "hutan")
	Game.complete_challenge("hutan-2", "hutan")
	check(Game.badges.is_empty(), "badge hutan belum diberikan sebelum tantangan akhir")
	Game.complete_challenge("hutan-3", "hutan")
	check(Game.badges.has("nature"), "badge nature diberikan setelah tantangan akhir")
	check(Game.map_unlocked("pabrik"), "pabrik terbuka setelah badge nature")

	# --- boss & ending bercabang
	Game.xp = 999
	main._load_map("source")
	await wait(0.3)
	main._open_next_challenge()
	await wait(0.3)
	check(main.puzzle.visible and int(main.puzzle._c.get("boss_hp", 0)) == 3, "boss The Source tampil dengan HP 3")
	main.puzzle._on_close()

	Game.badges = ["nature", "core", "cipher", "aqua", "guardian"] as Array[String]
	main._choose_ending("flow", [])
	check(Game.ending_choice == "flow", "keputusan ending tersimpan")
	check(main.ending_screen._title.text == "TERRA PULIH", "ending mengikuti keputusan pemain")
	main._show_title()
	await wait(0.2)

	# --- penyimpanan
	Game.save_game()
	var xp_before := Game.xp
	Game.reset()
	Game.load_game()
	check(Game.xp == xp_before, "simpan & muat mengembalikan XP")

	print("== Selesai ==")

func _solve(ch: Dictionary) -> void:
	var t := str(ch.get("type", "mcq"))
	match t:
		"mcq":
			var ans := int(ch.get("answer", 0))
			main.puzzle._on_mcq(ans, Button.new())
		"build":
			var i := 0
			for part in ch["parts"]:
				var ob: OptionButton = main.puzzle._parts_select[i]["node"]
				for k in range(ob.item_count):
					if ob.get_item_text(k) == str(part["answer"]):
						ob.selected = k
				i += 1
			main.puzzle._on_sql_check()
		"order":
			main.puzzle._order_answer = (ch["items"] as Array).duplicate()
			main.puzzle._order_pool.clear()
			main.puzzle._on_order_check()
		"cipher":
			main.puzzle._cipher_shift = int(ch["answer_shift"])
			main.puzzle._on_cipher_check()
		"craft":
			main.puzzle._craft_slots = (ch["slots"] as Array).duplicate()
			main.puzzle._on_craft_check()
