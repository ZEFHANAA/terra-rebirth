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

func run() -> void:
	print("== Mulai uji ==")
	check(Game.record_path != "user://records_terra.json" and Game.save_path != "user://save_terra.json",
		"uji memakai berkas terpisah (data peserta asli aman)")
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

	# --- pedagang: komponen perangkat dibeli di Kota Unggul (Tabel 2.4/2.6)
	main.puzzle._on_close()
	await wait(0.2)
	Game.coins = 100
	Game.coins_changed.emit(Game.coins)
	check(not Game.can_afford("lensa"), "item bantu ditahan selama uang belum cukup untuk komponen")
	check(Game.can_afford("sensor"), "komponen tetap bisa dibeli walau uang terbatas")
	main._on_talk_npc("pedagang")
	await wait(0.25)
	for i in range(6):
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
	check(main._world.objects.size() == 5, "Hutan punya 5 objek pencarian (5 quest)")
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

	# --- komponen Map 5 dibeli di toko, bukan ditemukan di peta (Bab III 3.6.4)
	main._load_map("danau")
	await wait(0.3)
	check((Content.map_by_id("danau").get("objects", []) as Array).is_empty(),
		"Danau tidak lagi menyediakan komponen di peta")
	Game.done["danau-1"] = true
	Game.done["danau-2"] = true
	main._open_next_challenge()
	await wait(0.3)
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
	main._open_next_challenge()
	await wait(0.3)
	check(main.puzzle.visible, "perakitan terbuka setelah komponen lengkap")
	main.puzzle._on_close()
	await wait(0.2)

	# --- selesaikan seluruh tantangan tiap peta
	Game.components = {"sensor": true, "papan": true, "mcu": true, "daya": true}
	for m in Content.MAPS:
		var mid: String = m["id"]
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
			if main.puzzle._action_row.get_child_count() > 0:
				main.puzzle._action_row.get_child(0).pressed.emit()
			await wait(0.2)
		check(Game.done.has(str((m["challenges"] as Array)[0]["id"])), "tantangan %s tercatat" % mid)

	# --- aturan badge: satu quest tidak memberi badge
	Game.reset()
	Game.complete_challenge("kota-1", "kota")
	check(Game.badges.is_empty(), "satu quest belum memberi badge")
	check(not Game.map_unlocked("hutan"), "hutan terkunci sebelum quest pengantar selesai")
	Game.complete_challenge("kota-2", "kota")
	check(Game.badges.is_empty(), "Kota Unggul tidak memberi badge (Map 1 hub)")
	check(Game.map_unlocked("hutan"), "hutan terbuka setelah seluruh quest Kota Unggul selesai")
	check(not Game.map_unlocked("pabrik"), "pabrik terkunci tanpa badge Map 2")

	Game.complete_challenge("hutan-1", "hutan")
	Game.complete_challenge("hutan-2", "hutan")
	Game.complete_challenge("hutan-3", "hutan")
	Game.complete_challenge("hutan-4", "hutan")
	check(Game.badges.is_empty(), "badge hutan belum diberikan sebelum tantangan akhir")
	Game.complete_challenge("hutan-5", "hutan")
	check(Game.badges.has("nature"), "badge Map 2 diberikan setelah seluruh quest selesai")
	check(Game.map_unlocked("pabrik"), "pabrik terbuka setelah badge Map 2")
	check(Game.badges.size() == 1, "hanya satu badge untuk satu map")

	# --- struktur instrumen post-test
	check(Content.TEST_ITEMS.size() == 20, "post-test berisi 20 soal")
	var per_ok := true
	for mt in Content.MATERI:
		if Content.test_count_for(mt) != 5:
			per_ok = false
	check(per_ok, "setiap materi diwakili 5 soal")
	var opts_ok := true
	for it in Content.TEST_ITEMS:
		if (it["o"] as Array).size() != 4:
			opts_ok = false
	check(opts_ok, "setiap soal punya 4 opsi jawaban")

	# --- penilaian post-test
	var all_correct: Array = []
	for it in Content.TEST_ITEMS:
		all_correct.append(int(it["a"]))
	var r100 := Game.grade_posttest(all_correct)
	check(int(r100["nilai"]) == 100 and bool(r100["tuntas"]), "20 benar = nilai 100 dan tuntas")
	var half: Array = []
	for i in range(Content.TEST_ITEMS.size()):
		half.append(int(Content.TEST_ITEMS[i]["a"]) if i < 10 else (int(Content.TEST_ITEMS[i]["a"]) + 1) % 4)
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
	main._open_next_challenge()
	await wait(0.3)
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
	Game.submit_posttest(Content.answer_key())
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
	Game.submit_posttest(Content.answer_key())
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
	for i in range(Content.TEST_ITEMS.size()):
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
