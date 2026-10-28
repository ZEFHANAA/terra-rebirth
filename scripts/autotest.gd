extends Node
## Uji integrasi otomatis: menjalankan alur permainan tanpa interaksi manual.
## Jalankan: godot --headless --path . res://scenes/AutoTest.tscn
##
## Yang diuji adalah aturan yang tertulis di dokumen penelitian:
##   - badge hanya diberikan setelah SELURUH quest satu map selesai (2.5)
##   - badge map sebelumnya adalah syarat masuk map berikutnya (Tabel 2.5)
##   - tidak ada level/XP sebagai syarat progres
##   - post-test 20 soal, 5 soal tiap materi, nilai = benar/20 x 100, tuntas 70 (3.9, 3.11)
##   - SUS 10 butir, skor 0-100, acuan 68 (3.9, 3.11)

var main: Node
var fails := 0
var checks := 0

func _ready() -> void:
	# Uji memakai berkas sendiri: data peserta asli (records_terra.json) dan
	# simpanan pemain tidak boleh dihapus/ditimpa hanya karena tes dijalankan.
	Game.record_path = "user://records_autotest.json"
	Game.save_path = "user://save_autotest.json"
	for p in [Game.save_path, Game.record_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await run()
	print("\n=== HASIL: %d cek, %d gagal ===" % [checks, fails])
	# bersihkan berkas uji supaya tidak menumpuk di folder pengguna
	for p in [Game.save_path, Game.record_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
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

## Meniru pemain: quest hanya bisa dibuka lewat objek/tempat di peta.
func open_via_object(challenge_id: String) -> void:
	var m := Content.map_by_id(main.current_map)
	var target := {}
	for o in m.get("objects", []):
		if str(o.get("challenge", "")) == challenge_id:
			target = o
			break
	if target.is_empty():
		var want_bank := challenge_id.contains("-b")
		var want_puzzle := challenge_id.contains("-p")
		for o in m.get("objects", []):
			if want_puzzle and bool(o.get("puzzle", false)):
				target = o
				break
			if want_bank and bool(o.get("bank", false)):
				target = o
				break
	if target.is_empty():
		check(false, "objek pemicu quest %s tersedia" % challenge_id)
		return
	main._on_inspect_object(str(target["id"]))
	await wait(0.2)
	var guard := 0
	while main.dialog.visible and guard < 12:
		await press_e()
		await wait(0.1)
		guard += 1
	await wait(0.25)

func run() -> void:
	print("== Mulai uji ==")
	check(Game.record_path != "user://records_terra.json" and Game.save_path != "user://save_terra.json",
		"uji memakai berkas terpisah (data peserta asli aman)")
	Game.reset()
	main._on_new_game()
	await wait(0.6)

	check(main.state == "playing", "state masuk ke playing")
	check(not main.dialog.visible, "dialog tidak terbuka otomatis (harus dekati NPC)")
	check(main._world.npcs.size() == 4, "Kota Unggul tetap punya 4 NPC")
	check((Content.map_by_id("kota")["objects"] as Array).size() == 2, "Kota punya 2 objek pemicu quest")
	for raw_map in Content.MAPS:
		var mid: String = raw_map["id"]
		if mid != "kota":
			check((Content.npcs_of(raw_map) as Array).size() == 3, "%s punya 3 NPC" % mid)
		check(not (Content.map_by_id(mid).get("objects", []) as Array).is_empty(), "%s punya pemicu quest berupa objek" % mid)
		for npc in Content.npcs_of(raw_map):
			check(str(npc.get("action", "")) != "quest", "%s: NPC bukan pemicu quest" % mid)
			if str(npc.get("action", "")) == "materi":
				check(main._lesson_lines(raw_map).size() > 1, "%s: NPC pengajar %s membawa materi" % [mid, npc.get("id")])
			else:
				check(not (npc.get("dialog", []) as Array).is_empty(), "%s: NPC %s punya dialog" % [mid, npc.get("id")])

	# --- NPC memberi materi, objek yang membuka quest
	main._on_talk_npc("kepala")
	await wait(0.25)
	check(main.dialog.visible, "dialog materi terbuka setelah bicara dengan NPC")
	var city_lines: Array = main.dialog._lines
	var ada_materi := false
	for l in city_lines:
		if str(l).begins_with("Materi "):
			ada_materi = true
	check(city_lines.size() > 2 and ada_materi, "NPC Kota bercerita dulu, materi tetap disampaikan")
	for i in range(30):
		if not main.dialog.visible:
			break
		await press_e()
		await wait(0.08)
	check(not main.dialog.visible, "dialog tertutup setelah lanjut")
	check(not main.puzzle.visible, "dialog NPC tidak membuka quest")
	main._on_inspect_object("kota-papan")
	await wait(0.25)
	for i in range(10):
		if not main.dialog.visible:
			break
		await press_e()
		await wait(0.1)
	await wait(0.25)
	check(main.puzzle.visible, "quest terbuka dari objek peta")
	check(main.puzzle._lesson_done, "panel quest tidak menampilkan materi terpisah dari NPC")

	# --- pedagang: komponen perangkat dibeli di Kota Unggul (Tabel 2.4/2.6)
	main.puzzle._on_close()
	await wait(0.2)
	Game.coins = 100
	Game.coins_changed.emit(Game.coins)
	check(not Game.can_afford("lensa"), "item bantu ditahan selama uang belum cukup untuk komponen")
	check(Game.can_afford("sensor"), "komponen tetap bisa dibeli walau uang terbatas")
	main._on_talk_npc("pedagang")
	await wait(0.25)
	for i in range(12):
		if not main.dialog.visible:
			break
		await press_e()
		await wait(0.1)
	await wait(0.3)
	check(main.shop.visible, "toko terbuka setelah dialog pedagang")
	main.shop._buy("sensor")
	await wait(0.15)
	check(Game.has_component("sensor"), "sensor pH tercatat dimiliki setelah dibeli")
	check(Game.coins == 65, "uang berkurang sesuai harga komponen (100-35)")
	check(Game.item_count("sensor") == 0, "komponen tidak masuk daftar barang sekali pakai")
	main.shop.visible = false

	# --- penjaga gerbang memberi syarat wilayah berikutnya
	main._on_talk_npc("gerbang")
	await wait(0.25)
	check(main.dialog.visible, "penjaga gerbang bisa diajak bicara")
	main.dialog.visible = false
	main._dialog_intent = ""

	# --- objek pencarian di Hutan membuka tantangan
	main._load_map("hutan")
	await wait(0.3)
	check(main._world.objects.size() == 5, "Hutan punya 3 quest + terminal soal + benda rusak")
	check((Content.npcs_of(Content.map_by_id("hutan")) as Array).size() == 3, "Hutan punya 3 NPC")
	var lessons := " ".join(main._lesson_lines(Content.map_by_id("hutan")))
	check(lessons.findn("primary key") >= 0 and lessons.findn("foreign key") >= 0, "materi Basis Data disajikan NPC pengajar")
	main._on_inspect_object("hutan-cari-1")
	await wait(0.25)
	check(main.dialog.visible, "objek menampilkan temuan")
	for i in range(8):
		if not main.dialog.visible:
			break
		await press_e()
		await wait(0.12)
	await wait(0.25)
	check(main.puzzle.visible, "tantangan terbuka setelah memeriksa objek")
	main.puzzle._on_close()
	main.dialog.visible = false
	main._dialog_intent = ""
	await wait(0.2)

	# --- komponen Map 5 dibeli di toko, bukan ditemukan di peta (Bab III 3.6.4)
	main._load_map("danau")
	await wait(0.3)
	check((Content.map_by_id("danau").get("objects", []) as Array).size() == 6,
		"Danau punya 4 pemicu quest + terminal soal + benda rusak")
	var danau_component_obj := false
	for o in Content.map_by_id("danau").get("objects", []):
		if o.has("component"):
			danau_component_obj = true
	check(not danau_component_obj, "Danau tidak lagi menyediakan komponen di peta")
	Game.done["danau-1"] = true
	Game.done["danau-2"] = true
	await open_via_object("danau-3")
	check(not main.puzzle.visible, "perakitan terkunci sebelum komponen lengkap")
	Game.coins = 200
	Game.buy_item("sensor")
	Game.buy_item("papan")
	var sambung: String = " ".join(main._intro_lines(Content.map_by_id("danau")))
	check(sambung.findn("belum lengkap") >= 0, "dialog Danau menyebut komponen belum lengkap")
	check(sambung.findn("Mikrokontroler") >= 0, "dialog Danau menyebut nama komponen yang kurang")
	Game.buy_item("mcu")
	Game.buy_item("daya")
	check(Game.all_components(), "empat komponen lengkap setelah dibeli di toko")
	check(Game.components_cost() == 120, "harga seluruh komponen sesuai Tabel 2.4/2.6 (120 uang)")
	var sudah: String = " ".join(main._intro_lines(Content.map_by_id("danau")))
	check(sudah.findn("sudah membawa keempat komponen") >= 0,
		"dialog Danau berubah setelah komponen lengkap")
	await open_via_object("danau-3")
	check(main.puzzle.visible, "perakitan terbuka setelah komponen lengkap")
	main.puzzle._on_close()
	await wait(0.2)

	# --- selesaikan seluruh tantangan tiap peta
	Game.components = {"sensor": true, "papan": true, "mcu": true, "daya": true}
	for raw in Content.MAPS:
		var mid: String = raw["id"]
		main._load_map(mid)
		await wait(0.3)
		main.dialog.visible = false
		var mm := Content.map_by_id(mid)
		for ci in range((mm["challenges"] as Array).size()):
			var ch: Dictionary = mm["challenges"][ci]
			await open_via_object(str(ch["id"]))
			await wait(0.15)
			if not main.puzzle.visible:
				check(false, "puzzle terbuka untuk %s" % ch["id"])
				continue
			if not main.puzzle._lesson_done and main.puzzle._c.has("lesson"):
				main.puzzle._on_lesson_answer(int(main.puzzle._c["lesson"]["answer"]), Button.new())
				await wait(0.1)
			_solve(main.puzzle._c)
			await wait(0.15)
			if main.puzzle._action_row.get_child_count() > 0:
				main.puzzle._action_row.get_child(0).pressed.emit()
			await wait(0.2)
		check(Game.done.has(str((mm["challenges"] as Array)[0]["id"])), "tantangan %s tercatat" % mid)

	# --- aturan badge: satu quest tidak memberi badge
	Game.reset()
	Game.complete_challenge("kota-1", "kota")
	check(Game.badges.is_empty(), "satu quest belum memberi badge")
	check(not Game.map_unlocked("hutan"), "hutan terkunci sebelum quest pengantar selesai")
	Game.complete_challenge("kota-2", "kota")
	check(Game.badges.is_empty(), "Kota Unggul tidak memberi badge (Map 1 hub)")
	check(Game.map_unlocked("hutan"), "hutan terbuka setelah seluruh quest Kota Unggul selesai")
	check(not Game.map_unlocked("pabrik"), "pabrik terkunci tanpa badge Map 2")

	var hutan_ch: Array = Content.map_by_id("hutan")["challenges"]
	for i in range(hutan_ch.size() - 1):
		Game.complete_challenge(str(hutan_ch[i]["id"]), "hutan")
	check(Game.badges.is_empty(), "badge hutan belum diberikan sebelum tantangan akhir")
	Game.complete_challenge(str(hutan_ch[hutan_ch.size() - 1]["id"]), "hutan")
	check(Game.badges.has("nature"), "badge Map 2 diberikan setelah seluruh quest selesai")
	check(Game.map_unlocked("pabrik"), "pabrik terbuka setelah badge Map 2")
	check(Game.badges.size() == 1, "hanya satu badge untuk satu map")

	# --- struktur instrumen post-test
	check(Game.posttest_items().size() == 20, "post-test berisi 20 soal")
	var per_ok := true
	var picked := Game.posttest_items()
	for mt in Content.MATERI:
		var n := 0
		for it in picked:
			if str(it["m"]) == mt:
				n += 1
		if n != 5:
			per_ok = false
	check(per_ok, "setiap materi diwakili 5 soal")
	var opts_ok := true
	for it in Game.posttest_items():
		if (it["o"] as Array).size() != 4:
			opts_ok = false
	check(opts_ok, "setiap soal punya 4 opsi jawaban")

	# --- hukuman gagal: progres dan badge reset, uang + pembelian tetap
	Game.reset()
	Game.badges = ["nature", "core"] as Array[String]
	Game.done["hutan-1"] = true
	Game.done["pabrik-1"] = true
	Game.coins = 42
	Game.items["lensa"] = 2
	Game.components["sensor"] = true
	Game.map_lives["hutan"] = 3
	Game.note_mistake("hutan", "hutan-2")
	check(Game.map_lives["hutan"] == 2, "salah pertama mengurangi satu nyawa")
	Game.note_mistake("hutan", "hutan-2")
	check(Game.map_lives["hutan"] == 2, "soal sama tidak menghukum dua kali")
	Game.note_mistake("hutan", "hutan-3")
	Game.note_mistake("hutan", "hutan-4")
	check(Game.done.is_empty(), "nyawa habis menghapus seluruh progres quest")
	check(Game.badges.is_empty(), "nyawa habis menghapus seluruh badge")
	check(Game.coins == 42, "nyawa habis tetap menyimpan uang")
	check(Game.item_count("lensa") == 2 and Game.has_component("sensor"), "nyawa habis tetap menyimpan item dan komponen")
	check(Game.current_map == "kota", "nyawa habis memulai ulang dari Kota Unggul")
	check(Game.lives_left("hutan") == Content.LIVES_PER_MAP, "nyawa pulih setelah reset progres")
	check(not Game.is_map_cleared("hutan"), "peta kembali terkunci setelah progres reset")

	# beri waktu handler game over selesai reload Kota Unggul
	await wait(2.6)
	main._start_play("kota")
	await wait(0.3)

	# --- jalur UI: salah mengurangi nyawa, game over reset progres global
	Game.reset()
	Game.coins = 77
	Game.items["lensa"] = 1
	Game.components["sensor"] = true
	Game.badges = ["nature"]
	Game.done["hutan-1"] = true
	Game.done["hutan-2"] = true
	Game.done["hutan-3"] = true
	Game.done["pabrik-1"] = true
	main._load_map("hutan")
	await wait(0.4)
	main.dialog.visible = false
	await open_via_object("hutan-b1")
	check(main.puzzle.visible and main.puzzle._c.has("bank_materi"), "quest bank terbuka dari terminal soal")
	var salah := (int(main.puzzle._c["answer"]) + 1) % 4
	main.puzzle._on_mcq(salah, Button.new())
	await wait(0.2)
	check(Game.lives_left("hutan") == 2, "jawaban salah di panel memotong satu nyawa")
	check(main.puzzle._feedback.text.contains("Nyawa wilayah 2/3"), "sisa nyawa tampil di umpan balik")
	Game.note_mistake("hutan", "hutan-b2")
	Game.note_mistake("hutan", "hutan-b3")
	await wait(2.6)
	check(Game.current_map == "kota" and main.current_map == "kota", "game over kembali ke Kota Unggul")
	check(Game.done.is_empty() and Game.badges.is_empty(), "game over reset progres dan badge seluruh wilayah")
	check(Game.coins == 77, "game over menyimpan uang pemain")
	check(Game.item_count("lensa") == 1 and Game.has_component("sensor"), "game over menyimpan pembelian")
	check(Game.lives_left("hutan") == Content.LIVES_PER_MAP, "game over mengisi ulang nyawa")
	check(main._world.npcs.size() == 4 and main._world.objects.size() == 2, "Kota Unggul tetap bisa dimainkan setelah reset")
	check(main.hud._lives.text.begins_with("Nyawa 3/3"), "nyawa tampil juga di Kota Unggul setelah reset")

	# --- soal bank diundi acak tiap sesi, bukan memakai seed tetap per peserta
	Game.reset()
	Game.player_code = "PESERTA-UJI"
	var undian: Dictionary = {}
	for i in range(6):
		Game.bank_picks.clear()
		undian[str(Game.bank_question("hutan-b1", "Basis Data").get("id", ""))] = true
	check(undian.size() >= 2, "soal bank diundi acak, tidak selalu soal yang sama")
	Game.bank_picks.clear()
	var lima: Dictionary = {}
	for i in range(5):
		lima[str(Game.bank_question("hutan-b%d" % (i + 1), "Basis Data").get("id", ""))] = true
	check(lima.size() == 5, "lima soal dalam satu wilayah tidak dobel")

	# --- puzzle diundi acak dari 10 soal per materi
	Game.puzzle_picks.clear()
	var p1 := str(Game.bank_puzzle("hutan-p1", "Basis Data").get("id", ""))
	var p2 := str(Game.bank_puzzle("hutan-p2", "Basis Data").get("id", ""))
	check(p1 != "" and p2 != "" and p1 != p2, "dua puzzle satu wilayah tidak dobel")
	var undian_p: Dictionary = {}
	for i in range(6):
		Game.puzzle_picks.clear()
		undian_p[str(Game.bank_puzzle("hutan-p1", "Basis Data").get("id", ""))] = true
	check(undian_p.size() >= 2, "puzzle diundi acak, tidak selalu puzzle yang sama")

	# --- panel mendukung puzzle isi rumpang (fill the blank)
	var pz_fill := {}
	for pz in Content.puzzles_of("Basis Data"):
		if str(pz.get("type", "")) == "fill":
			pz_fill = pz
			break
	Game.puzzle_picks["uji-fill"] = str(pz_fill.get("id", ""))
	main.puzzle.open({"id": "uji-fill", "type": "puzzle", "puzzle_bank": true, "bank_materi": "Basis Data"}, 0, 1)
	await wait(0.2)
	check(main.puzzle._fill_edit != null, "panel puzzle isi rumpang tampil")
	main.puzzle._fill_edit.text = str((pz_fill.get("accept", [""]) as Array)[0])
	main.puzzle._on_fill_check()
	await wait(0.2)
	check(main.puzzle._done, "jawaban benar menyelesaikan puzzle isi rumpang")
	main.puzzle.visible = false

	# --- tema panel mengikuti wilayah (bahan tiap peta berbeda)
	var tema_ok := true
	var tema_unik: Array = []
	for k in UiKit.THEMES.keys():
		var th: Dictionary = UiKit.THEMES[k]
		for field in ["frame", "paper", "ribbon"]:
			if not ResourceLoader.exists(str(th[field])):
				tema_ok = false
		if not tema_unik.has(str(th["paper"])):
			tema_unik.append(str(th["paper"]))
	check(tema_ok and tema_unik.size() == 6, "enam wilayah punya tekstur tema sendiri")
	UiKit.set_theme("pabrik")
	var paper_pabrik := str(UiKit.parchment_style().texture.resource_path)
	UiKit.set_theme("hutan")
	var paper_hutan := str(UiKit.parchment_style().texture.resource_path)
	UiKit.set_theme("")
	var paper_dasar := str(UiKit.parchment_style().texture.resource_path)
	check(paper_pabrik.find("card_pabrik") >= 0 and paper_hutan.find("card_hutan") >= 0
		and paper_dasar.find("card_kota") >= 0, "kertas panel berganti sesuai wilayah")

	# --- cerita tiap NPC tampil sebelum materi
	Game.reset()
	main._load_map("hutan")
	await wait(0.3)
	main._on_talk_npc("petani")
	await wait(0.2)
	var cerita: Array = main.dialog._lines
	check(cerita.size() > 0 and str(cerita[0]).findn("Sawahku") >= 0, "dialog NPC diawali cerita pribadinya")
	main.dialog.visible = false

	# --- quest puzzle bisa datang dari NPC, bukan hanya benda
	main._on_talk_npc("arsip")
	await wait(0.2)
	var guard_q := 0
	while main.dialog.visible and guard_q < 20:
		await press_e()
		await wait(0.1)
		guard_q += 1
	await wait(0.3)
	check(main.puzzle.visible and main.puzzle._c.has("puzzle_bank"), "NPC lain bisa memberi quest puzzle")
	var tipe_p := str(main.puzzle._c.get("type", ""))
	check(tipe_p == "order" or tipe_p == "fill", "puzzle berjenis urutan atau isi rumpang")

	# --- puzzle gagal: nyawa langsung habis, progres direset, uang tetap
	Game.coins = 45
	if tipe_p == "fill":
		main.puzzle._fill_edit.text = "jawaban-pasti-salah"
		main.puzzle._on_fill_check()
	else:
		var langkah: Array = (main.puzzle._c.get("items", []) as Array).duplicate()
		if langkah.size() >= 2:
			var tmp = langkah[0]
			langkah[0] = langkah[1]
			langkah[1] = tmp
		main.puzzle._order_answer = langkah
		main.puzzle._order_pool.clear()
		main.puzzle._on_order_check()
	await wait(0.5)
	check(Game.done.is_empty() and Game.badges.is_empty(), "puzzle gagal menghapus seluruh progres dan badge")
	check(Game.coins == 45, "puzzle gagal tetap menyimpan uang")
	check(Game.current_map == "kota", "puzzle gagal mengembalikan pemain ke Kota Unggul")
	check(not main.puzzle.visible, "panel quest tertutup setelah game over")
	check(not main.dialog.visible, "reset tidak memunculkan dialog quest otomatis")

	# --- koin hanya dibayar sekali, juga setelah reset (FR-012)
	Game.reset()
	Game.complete_challenge("hutan-1", "hutan")
	check(Game.coins == Content.COINS_PER_CHALLENGE, "tantangan pertama membayar koin")
	Game.map_lives["hutan"] = 1
	Game.note_mistake("hutan", "hutan-2")
	await wait(2.6)
	check(Game.done.is_empty(), "reset nyawa berjalan sebelum uji koin ulang")
	Game.complete_challenge("hutan-1", "hutan")
	check(Game.coins == Content.COINS_PER_CHALLENGE, "koin tidak dibayar dua kali setelah reset")
	# --- simpan/muat setelah reset tidak memulihkan progres lama
	Game.save_game()
	Game.load_game()
	check(Game.done.size() == 1 and Game.done.has("hutan-1"), "simpan/muat setelah reset tidak memulihkan progres lama")
	check(Game.badges.is_empty(), "simpan/muat setelah reset tidak memulihkan badge lama")
	check(Game.coins == Content.COINS_PER_CHALLENGE, "simpan/muat setelah reset mempertahankan uang")

	# --- penilaian post-test
	var all_correct: Array = []
	for it in Game.posttest_items():
		all_correct.append(int(it["a"]))
	var r100 := Game.grade_posttest(all_correct)
	check(int(r100["nilai"]) == 100 and bool(r100["tuntas"]), "20 benar = nilai 100 dan tuntas")
	var half: Array = []
	for i in range(Game.posttest_items().size()):
		half.append(int(Game.posttest_items()[i]["a"]) if i < 10 else (int(Game.posttest_items()[i]["a"]) + 1) % 4)
	var r50 := Game.grade_posttest(half)
	check(int(r50["nilai"]) == 50, "10 benar = nilai 50")
	check(not bool(r50["tuntas"]), "nilai 50 belum mencapai batas tuntas 70")

	# --- skor SUS
	var max_sus: Array = [5, 1, 5, 1, 5, 1, 5, 1, 5, 1]
	var min_sus: Array = [1, 5, 1, 5, 1, 5, 1, 5, 1, 5]
	check(is_equal_approx(Game.sus_score(max_sus), 100.0), "SUS jawaban paling positif = 100")
	check(is_equal_approx(Game.sus_score(min_sus), 0.0), "SUS jawaban paling negatif = 0")
	var mid_sus: Array = [4, 2, 4, 2, 4, 2, 4, 2, 4, 2]
	check(is_equal_approx(Game.sus_score(mid_sus), 75.0), "SUS 3/4 positif = 75")

	# --- asesmen tersimpan & CSV
	Game.player_code = "P01"
	Game.submit_posttest(all_correct)
	Game.submit_sus(max_sus)
	check(Game.assessment_complete(), "post-test dan SUS tercatat selesai")
	var recs := Game.read_records()
	check(recs.size() == 1, "satu baris data peserta tersimpan")
	if recs.size() == 1:
		var rec: Dictionary = recs[0]
		check(str(rec.get("kode", "")) == "P01", "kode peserta tersimpan")
		check(int(rec.get("post", 0)) == 100, "nilai post-test tersimpan")
		check(is_equal_approx(float(rec.get("sus", 0.0)), 100.0), "skor SUS tersimpan")
		check(rec.has("durasi_menit"), "durasi bermain tersimpan")
		check(int((rec.get("materi", {}) as Dictionary).get("Basis Data", -1)) == 5, "skor per materi tersimpan")
	var csv_path := "user://uji_rekap.csv"
	check(Game.export_csv(csv_path), "ekspor CSV berhasil")
	var f := FileAccess.open(csv_path, FileAccess.READ)
	if f:
		var head := f.get_line()
		f.close()
		check(head.begins_with("kode,tanggal,durasi_menit"), "header CSV sesuai")
	else:
		check(false, "berkas CSV dapat dibaca")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(csv_path))

	# --- panel asesmen (UI)
	main._open_asesmen()
	await wait(0.25)
	check(main.asesmen.visible, "panel asesmen terbuka")
	check(main.asesmen._stage == "done", "asesmen yang sudah selesai langsung menampilkan ringkasan")
	main.asesmen._close(true)
	await wait(0.2)
	check(not main.asesmen.visible, "panel asesmen tertutup")

	# --- boss & ending bercabang
	main._load_map("source")
	await wait(1.6)  # biarkan timer asesmen otomatis dari uji sebelumnya selesai
	main.asesmen.visible = false
	await open_via_object("source-1")
	check(main.puzzle.visible, "tantangan akhir The Source terbuka")
	check(int(main.puzzle._c.get("boss_hp", 0)) == 4, "boss The Source tampil dengan HP 4")
	main.puzzle._on_close()

	Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
	main._choose_ending("flow", [])
	check(Game.ending_choice == "flow", "keputusan ending tersimpan")
	check(main.ending_screen._title.text == "TERRA PULIH", "ending mengikuti keputusan pemain")
	main._show_title()
	await wait(0.2)

	# --- penyimpanan
	Game.save_game()
	var badges_before := Game.badges.size()
	var done_before := Game.done.size()
	Game.reset()
	Game.load_game()
	check(Game.badges.size() == badges_before, "simpan & muat mengembalikan badge")
	check(Game.done.size() == done_before, "simpan & muat mengembalikan progres tantangan")
	check(Game.assessment_complete(), "simpan & muat mengembalikan status asesmen")

	await _uji_tambahan()
	await _uji_jeda_jurnal()

	print("== Selesai ==")

## Uji tambahan: kasus batas yang mudah terlewat.
func _uji_tambahan() -> void:
	print("-- kasus batas --")
	# 1. peserta baru: kode peserta tidak boleh terbawa dari sesi sebelumnya
	Game.player_code = "P99"
	Game.reset()
	check(Game.player_code == "", "reset mengosongkan kode peserta (peserta baru)")
	check(Game.playtime_minutes() >= 0.0, "durasi bermain tidak negatif")

	# 2. satu tantangan tidak dihitung dua kali
	Game.reset()
	Game.complete_challenge("hutan-1", "hutan")
	Game.complete_challenge("hutan-1", "hutan")
	check(Game.done.size() == 1, "tantangan yang sama tidak tercatat dua kali")
	check(Game.coins == Game.COINS_PER_CHALLENGE, "uang tidak bertambah dua kali")

	# 3. batal di asesmen tidak menyimpan data
	var rec0 := Game.read_records().size()
	main._load_map("source")
	await wait(0.3)
	main._open_asesmen()
	await wait(0.2)
	check(main.asesmen._stage == "intro", "asesmen baru dimulai dari halaman kode peserta")
	main.asesmen._close(false)
	await wait(0.2)
	check(not Game.assessment_complete(), "batal mengisi asesmen tidak dianggap selesai")
	check(Game.read_records().size() == rec0, "batal mengisi asesmen tidak menambah data")

	# 4. post-test saja tetap tersimpan (SUS kosong), lalu diperbarui saat SUS dikirim
	Game.player_code = "P02"
	Game.submit_posttest(Game.answer_key())
	var recs := Game.read_records()
	var row := _cari(recs, "P02")
	check(not row.is_empty(), "jawaban post-test tersimpan walau SUS belum diisi")
	check(float(row.get("sus", 0.0)) < 0.0, "skor SUS ditandai kosong sebelum kuesioner diisi")
	var csv2 := "user://uji_dua.csv"
	check(Game.export_csv(csv2), "ekspor CSV dengan SUS kosong tetap berhasil")
	var f2 := FileAccess.open(csv2, FileAccess.READ)
	if f2:
		var baris := f2.get_as_text().split("\n")
		f2.close()
		var sus_kol := "?"
		for ln in baris:
			if ln.begins_with("P02,"):
				var kol := ln.split(",")
				sus_kol = str(kol[11]) if kol.size() > 11 else "?"
		check(sus_kol == "", "kolom SUS kosong di CSV, bukan angka palsu (didapat '%s')" % sus_kol)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(csv2))
	Game.submit_sus([3, 3, 3, 3, 3, 3, 3, 3, 3, 3])
	row = _cari(Game.read_records(), "P02")
	check(is_equal_approx(float(row.get("sus", -1.0)), 50.0), "SUS netral (3) = 50")
	check(Game.read_records().size() == rec0 + 1, "SUS memperbarui baris yang sama, tidak menambah baris")

	# 5. kode peserta berbeda menjadi baris berbeda
	Game.player_code = "P03"
	Game.submit_posttest(Game.answer_key())
	Game.submit_sus([5, 1, 5, 1, 5, 1, 5, 1, 5, 1])
	check(Game.read_records().size() == rec0 + 2, "peserta dengan kode berbeda mendapat baris baru")

	# 6. SUS tidak lengkap ditolak
	check(Game.submit_sus([5, 5, -1, 5, 5, 5, 5, 5, 5, 5]) < 0.0, "SUS dengan butir kosong ditolak")

	# 7. durasi bermain bertambah dan tidak melonjak setelah simpan/muat
	Game.reset()
	await wait(1.1)
	var d1 := Game.playtime_minutes()
	check(d1 > 0.0, "durasi bermain terhitung (%.3f menit)" % d1)
	Game.save_game()
	await wait(1.1)
	Game.load_game()
	var d2 := Game.playtime_minutes()
	check(d2 >= d1 and d2 < d1 + 5.0, "durasi tetap wajar setelah simpan/muat (%.3f -> %.3f)" % [d1, d2])

	# 8. seluruh map terbuka setelah badge lengkap
	Game.reset()
	for b in ["nature", "core", "cipher", "aqua"]:
		Game.badges.append(b)
	var semua := true
	for m in Content.MAPS:
		var mid := str(m["id"])
		if mid == "hutan":
			continue   # Map 2 menunggu quest pengantar Map 1 (tanpa badge)
		if not Game.map_unlocked(mid):
			semua = false
	check(semua, "map 3-6 terbuka setelah 4 badge dimiliki")
	check(not Game.map_unlocked("hutan"), "hutan tetap menunggu quest pengantar Map 1")
	Game.complete_challenge("kota-1", "kota")
	Game.complete_challenge("kota-2", "kota")
	check(Game.map_unlocked("hutan"), "hutan terbuka setelah quest pengantar selesai")
	check(Content.badge_total() == 4, "jumlah badge yang bisa diperoleh = 4")

	# 9. jawaban kosong (-1) dihitung salah, bukan error
	var kosong: Array = []
	for i in range(Game.posttest_items().size()):
		kosong.append(-1)
	var nol := Game.grade_posttest(kosong)
	check(int(nol["nilai"]) == 0 and int(nol["benar"]) == 0 and not bool(nol["tuntas"]),
		"jawaban kosong dinilai 0 dan tidak tuntas")

	# 9b. potret dialog mengambil SATU frame, bukan seluruh sprite sheet
	for m in Content.MAPS:
		var key := str(m.get("npc_sprite", ""))
		if key == "":
			continue
		main.dialog._set_portrait(key)
		var at := main.dialog._portrait.texture as AtlasTexture
		var tex: Texture2D = at.atlas
		var r := at.region.size
		check(r.x > 0.0 and r.y > 0.0 and r.x <= tex.get_width() and r.y <= tex.get_height(),
			"%s: potret %s memotong satu frame dari sheet" % [str(m["id"]), key])
		check(r.x < tex.get_width() or r.y < tex.get_height(),
			"%s: potret %s tidak menampilkan seluruh sheet" % [str(m["id"]), key])

	# 10. berkas rekap rusak tidak membuat game berhenti
	var cadangan := ""
	if FileAccess.file_exists(Game.record_path):
		cadangan = FileAccess.get_file_as_string(Game.record_path)
	var fbad := FileAccess.open(Game.record_path, FileAccess.WRITE)
	if fbad:
		fbad.store_string("{rusak")
		fbad.close()
	check(Game.read_records().size() == 0, "berkas rekap rusak dibaca sebagai daftar kosong")
	if cadangan != "":
		var fok := FileAccess.open(Game.record_path, FileAccess.WRITE)
		if fok:
			fok.store_string(cadangan)
			fok.close()
		check(Game.read_records().size() > 0, "rekap pulih setelah berkas diperbaiki")

	# 11. uang hanya dari Map 2-Map 5 dan cukup untuk seluruh komponen
	Game.reset()
	Game.complete_challenge("kota-1", "kota")
	Game.complete_challenge("kota-2", "kota")
	check(Game.coins == 0, "Map 1 (hub) tidak memberi uang")
	Game.complete_challenge("source-1", "source")
	check(Game.coins == 0, "Map 6 (post-test) tidak memberi uang")
	var keping := 0
	for m in Content.MAPS:
		var mid := str(m["id"])
		if not Game.COINS_MAPS.has(mid) or mid == "danau":
			continue
		keping += (m["challenges"] as Array).size() * Game.COINS_PER_CHALLENGE
	check(Game.components_cost() <= keping,
		"harga komponen (%d) tidak melebihi uang dari Map 2-4 (%d)" % [Game.components_cost(), keping])
	check(Game.missing_components().size() == Game.COMPONENT_TOTAL,
		"komponen dihitung dari daftar Tabel 2.4/2.6, bukan dari isi peta")

	# 12. pesan singkat tidak menembus layar lain
	Game.reset()
	main._start_play("hutan")
	await wait(0.4)
	main._toast_msg("Cari Papan Data — tanda ? di peta.", 5.0)
	await wait(0.2)
	check(main._toast.modulate.a > 0.5, "pesan singkat tampil saat bermain")
	main._open_maps()
	await wait(0.3)
	check(main._toast.modulate.a == 0.0 and str(main._toast.text) == "",
		"pesan singkat tidak menembus layar Peta Wilayah")
	main._hide_all()
	main._start_play("kota")
	await wait(0.3)

func _cari(recs: Array, kode: String) -> Dictionary:
	for r in recs:
		if str(r.get("kode", "")) == kode:
			return r
	return {}

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
		"fill":
			main.puzzle._fill_edit.text = str((ch.get("accept", [""]) as Array)[0])
			main.puzzle._on_fill_check()
		"puzzle":
			pass

## Layar jeda, jurnal misi, dan penanda tujuan.
func _uji_jeda_jurnal() -> void:
	print("-- layar jeda & jurnal misi --")
	Game.reset()
	main._on_new_game()
	await wait(0.4)
	main._load_map("hutan")
	await wait(0.4)

	# 1. setiap tantangan punya pemicu yang bisa ditunjuk jurnal
	check(str(Content.trigger_of("hutan", "hutan-1").get("label", "")) == "Papan Data",
		"jurnal: hutan-1 dipicu Papan Data")
	check(str(Content.trigger_of("hutan", "hutan-b1").get("label", "")) == "Terminal Soal",
		"jurnal: soal bank diarahkan ke Terminal Soal")
	check(str(Content.trigger_of("hutan", "hutan-p1").get("label", "")) == "Pompa Rusak",
		"jurnal: puzzle bank diarahkan ke Pompa Rusak")
	var yatim: Array[String] = []
	for m in Content.MAPS:
		var mid := str(m["id"])
		for ch in Content.map_by_id(mid).get("challenges", []):
			if Content.trigger_of(mid, str(ch.get("id", ""))).is_empty():
				yatim.append("%s/%s" % [mid, str(ch.get("id", ""))])
	check(yatim.is_empty(), "semua tantangan punya pemicu (tanpa pemicu: %s)" % str(yatim))

	# 2. layar jeda
	main._open_pause()
	await wait(0.15)
	check(main.pause_menu.visible, "Esc membuka layar jeda")
	check(get_tree().paused, "permainan berhenti saat layar jeda terbuka")
	var kontrol := ""
	for n in main.pause_menu.find_children("*", "Label", true, false):
		kontrol += (n as Label).text + " "
	check(kontrol.findn("panah") >= 0 and kontrol.findn("jurnal") >= 0,
		"layar jeda memuat daftar kontrol (panah dan J disebut)")
	check(not main.hud.visible, "HUD disembunyikan saat layar jeda dibuka")
	Game.set_bgm_db(-30.0)
	Game.save_settings()
	Game.bgm_db = 0.0
	Game.load_settings()
	check(is_equal_approx(Game.bgm_db, -30.0), "volume musik tersimpan di berkas setelan")
	Game.set_bgm_db(-13.0)
	Game.save_settings()
	main._close_pause()
	await wait(0.15)
	check(not main.pause_menu.visible and not get_tree().paused,
		"Lanjutkan menutup jeda dan melanjutkan permainan")
	check(main.hud.visible, "HUD muncul lagi setelah jeda ditutup")
	main.pause_menu.open_settings()
	check(not main.pause_menu._kontrol.visible,
		"daftar kontrol disembunyikan di layar pengaturan")
	main.pause_menu.visible = false

	# 2b. tombol "Suara" di HUD dihapus; bisu dilakukan lewat penggeser volume
	var tombol_suara := 0
	for n in main.hud.find_children("*", "Button", true, false):
		if str((n as Button).text).begins_with("Suara"):
			tombol_suara += 1
	check(tombol_suara == 0, "HUD tidak lagi memuat tombol Suara")
	Game.set_sfx_db(Game.SILENT_DB)
	check(Game.sfx_db <= Game.SILENT_DB + 1.0, "penggeser efek suara bisa mencapai senyap")
	Game.set_sfx_db(-7.0)

	# 3. jurnal misi
	main._open_journal(false)
	await wait(0.2)
	check(main.journal.visible, "tombol J membuka jurnal misi")
	check(main.journal._left.get_child_count() == Content.MAPS.size(),
		"jurnal memuat satu baris untuk setiap wilayah")
	var n_ch := (Content.map_by_id("hutan")["challenges"] as Array).size()
	check(main.journal._right.get_child_count() >= n_ch,
		"jurnal memuat seluruh tantangan wilayah terpilih")
	main.journal._on_close()
	await wait(0.1)
	check(not main.journal.visible and not get_tree().paused,
		"menutup jurnal melanjutkan permainan")

	# 4. penanda tujuan di peta
	check(main._world.mark_objective("obj:hutan-cari-1"), "penanda bisa dipasang pada benda misi")
	var tujuan: Dictionary = main._world.next_objective()
	check(str(tujuan.get("name", "")) == "Papan Data", "HUD menunjuk ke benda yang ditandai")
	main._world.clear_mark()
	check(main._world.marked == "", "penanda bisa dilepas kembali")

	# 5. ulangi wilayah: progres direset, uang & barang tetap
	Game.complete_challenge("hutan-1", "hutan")
	var uang := Game.coins
	Game.items["lensa"] = 2
	Game.restart_map("hutan")
	check(not Game.done.has("hutan-1"), "ulangi wilayah menghapus progres wilayah itu")
	check(Game.coins == uang and Game.item_count("lensa") == 2,
		"ulangi wilayah tidak menghapus uang/barang")
	check(Game.lives_left("hutan") == Content.LIVES_PER_MAP,
		"ulangi wilayah mengembalikan nyawa menjadi penuh")

	# 6. setelan di layar judul: berkas terpisah dari simpanan permainan
	Game.set_bgm_db(-22.0)
	Game.save_settings()
	check(FileAccess.file_exists(Game.settings_path), "setelan disimpan ke berkas sendiri")
	Game.set_bgm_db(0.0)
	Game.load_settings()
	check(is_equal_approx(Game.bgm_db, -22.0), "setelan terbaca lagi saat game dibuka")
	if FileAccess.file_exists(Game.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.save_settings()
	check(not Game.has_save(), "menyimpan setelan tidak membuat simpanan permainan")
	Game.set_bgm_db(-13.0)
	Game.save_settings()

	# 7. koleksi badge
	main._open_badges()
	await wait(0.2)
	check(main.badges_screen.visible, "angka badge di HUD membuka koleksi badge")
	check(main.badges_screen._grid.get_child_count() == 4, "koleksi badge memuat empat badge")
	main.badges_screen._on_close()
	await wait(0.1)
	check(not main.badges_screen.visible and not get_tree().paused,
		"menutup koleksi badge melanjutkan permainan")

	# 8. ringkasan Mode Riset (rata-rata, ketuntasan, SUS, durasi)
	var rr: Dictionary = main.research_screen.ringkas([
		{"post": 60, "tuntas": false, "sus": 70.0, "durasi_menit": 20.0,
			"materi": {"Basis Data": 2, "Sistem Operasi": 3, "Kriptografi": 3, "Internet of Things": 2}},
		{"post": 80, "tuntas": true, "sus": 90.0, "durasi_menit": 30.0,
			"materi": {"Basis Data": 4, "Sistem Operasi": 4, "Kriptografi": 3, "Internet of Things": 4}},
	])
	check(is_equal_approx(float(rr["post"]), 70.0), "ringkasan: rata-rata post-test 70")
	check(int(rr["tuntas"]) == 1 and int(rr["tuntas_pct"]) == 50,
		"ringkasan: ketuntasan 1 dari 2 (50%)")
	check(is_equal_approx(float(rr["sus"]), 80.0), "ringkasan: rata-rata SUS 80")
	check(is_equal_approx(float(rr["durasi"]), 25.0), "ringkasan: rata-rata durasi 25 menit")
	check(is_equal_approx(float((rr["materi"] as Dictionary)["Basis Data"]), 3.0),
		"ringkasan: rata-rata benar Basis Data 3 dari 5")
	# Peserta yang belum mengisi SUS tidak boleh dihitung sebagai 0.
	var rr2: Dictionary = main.research_screen.ringkas([
		{"post": 100, "tuntas": true, "sus": -1.0, "durasi_menit": 10.0, "materi": {}},
		{"post": 0, "tuntas": false, "sus": 90.0, "durasi_menit": 10.0, "materi": {}},
	])
	check(int(rr2["sus_n"]) == 1 and is_equal_approx(float(rr2["sus"]), 90.0),
		"ringkasan: SUS kosong tidak dihitung 0")
	var rr0: Dictionary = main.research_screen.ringkas([])
	check(int(rr0["n"]) == 0, "ringkasan: data kosong tidak membuat error")

	# 9. layar judul bersih; Mode Riset hanya lewat Ctrl+R
	var ada_riset := false
	for n in main.title_screen.find_children("*", "Button", true, false):
		if (n as Button).text.findn("Mode Riset") >= 0:
			ada_riset = true
	var ada_kunci := false
	for n in main.title_screen.find_children("*", "Label", true, false):
		var tx := (n as Label).text
		if tx.findn("WASD") >= 0 or tx.findn("Kelompok") >= 0 or tx.findn("prototipe") >= 0:
			ada_kunci = true
	check(not ada_riset, "judul: tombol Mode Riset tidak lagi tampil")
	check(not ada_kunci, "judul: baris kontrol, identitas kelompok, dan kata prototipe hilang")
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.ctrl_pressed = true
	ev.physical_keycode = KEY_R
	main._show_title()
	main._unhandled_input(ev)
	check(main.state == "research", "Ctrl+R dari judul membuka Mode Riset")
	main._on_research_back()
	check(main.state == "title", "kembali dari Mode Riset membuka judul lagi")
