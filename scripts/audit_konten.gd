extends SceneTree
## Audit konten: memeriksa konsistensi data/content.gd terhadap aturan dokumen.
## Jalankan: godot --headless --script res://scripts/audit_konten.gd
##
## Yang diperiksa:
##   - struktur peta: id unik, badge, req_badge berurutan, tantangan akhir
##   - tiap map materi memuat 4-5 tantangan konsep + 1 tantangan akhir (total 25)
##   - post-test: 20 soal, 5 per materi, 4 opsi unik, kunci valid
##   - SUS: 10 butir dengan polaritas ganjil/genap
##   - sandi Caesar: ciphertext benar-benar menghasilkan jawaban
##   - semua tantangan punya kunci yang bisa dipakai mesin

var fails := 0
var checks := 0

func ok(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("  OK    ", label)
	else:
		fails += 1
		print("  GAGAL ", label)

func _initialize() -> void:
	print("=== AUDIT KONTEN ===")
	_struktur()
	_posttest()
	_sus()
	_sandi()
	_kunci()
	_peta()
	_rujukan()
	_toko()
	_aset()
	_tipe()
	print("\n=== %d cek, %d gagal ===" % [checks, fails])
	quit(1 if fails > 0 else 0)

func _struktur() -> void:
	print("\n-- struktur peta --")
	var ids: Array = []
	var prev_badge := ""
	for m in Content.MAPS:
		ids.append(str(m["id"]))
		var mid := str(m["id"])
		var chs: Array = m.get("challenges", [])
		ok(chs.size() > 0, "%s punya tantangan" % mid)
		var uniq := {}
		for c in chs:
			uniq[str(c["id"])] = true
		ok(uniq.size() == chs.size(), "%s: id tantangan unik (%d)" % [mid, chs.size()])
		var last: Dictionary = chs[chs.size() - 1]
		if mid != "kota":
			ok(bool(last.get("final", false)), "%s: tantangan terakhir ditandai final" % mid)
		# badge & syarat
		var badge := str(m.get("badge", ""))
		if mid == "kota" or mid == "source":
			ok(badge == "", "%s: tidak memberi badge (sesuai Tabel 2.5/2.6)" % mid)
		else:
			ok(badge != "", "%s: memberi badge" % mid)
		ok(str(m.get("req_badge", "")) == prev_badge,
			"%s: syarat badge = badge map sebelumnya (%s)" % [mid, prev_badge if prev_badge != "" else "tidak ada"])
		if badge != "":
			prev_badge = badge
		# NPC & objek
		ok((Content.npcs_of(m) as Array).size() > 0, "%s: punya NPC" % mid)
		if m.has("objects"):
			ok((m["objects"] as Array).size() > 0, "%s: objek pencarian terdaftar" % mid)
	ok(ids.size() == 6, "jumlah map = 6")
	ok(Content.total_challenges() == 25, "total tantangan = 25 (didapat %d)" % Content.total_challenges())
	# materi: satu map per materi, urutan tetap
	for mt in Content.MATERI:
		var found := 0
		for m in Content.MAPS:
			if str(m.get("material", "")) == mt:
				found += 1
		ok(found == 1, "materi '%s' muncul di tepat satu map" % mt)
	# kota 2 quest pengantar, map materi 5 tantangan
	ok((Content.map_by_id("kota")["challenges"] as Array).size() == 2, "Kota Unggul = 2 quest pengantar")
	for mid in ["hutan", "pabrik", "danau"]:
		ok((Content.map_by_id(mid)["challenges"] as Array).size() == 5, "%s = 5 tantangan" % mid)
	ok((Content.map_by_id("candi")["challenges"] as Array).size() == 4, "candi = 4 tantangan")

func _posttest() -> void:
	print("\n-- post-test --")
	ok(Content.TEST_ITEMS.size() == 20, "20 soal")
	var per := {}
	var soal := {}
	for it in Content.TEST_ITEMS:
		var mt := str(it["m"])
		per[mt] = int(per.get(mt, 0)) + 1
		ok(Content.MATERI.has(mt), "materi soal dikenal: %s" % mt)
		var opts: Array = it["o"]
		ok(opts.size() == 4, "4 opsi: %s" % str(it["q"]).substr(0, 40))
		var uniq := {}
		for o in opts:
			uniq[str(o)] = true
		ok(uniq.size() == opts.size(), "opsi tidak duplikat: %s" % str(it["q"]).substr(0, 32))
		ok(int(it["a"]) >= 0 and int(it["a"]) < opts.size(), "kunci dalam rentang: %s" % str(it["q"]).substr(0, 32))
		soal[str(it["q"])] = true
		ok(str(it["q"]).length() > 15, "soal tidak kosong: %s" % str(it["q"]).substr(0, 32))
	ok(soal.size() == 20, "tidak ada soal duplikat")
	for mt in Content.MATERI:
		ok(int(per.get(mt, 0)) == 5, "%s: 5 soal (didapat %d)" % [mt, int(per.get(mt, 0))])
	# sebaran kunci: jangan semua di satu opsi
	var dist := [0, 0, 0, 0]
	for it in Content.TEST_ITEMS:
		dist[int(it["a"])] += 1
	print("      sebaran kunci A/B/C/D: ", dist)
	ok(dist.min() >= 2, "kunci tersebar (tiap opsi minimal 2 kali)")

func _sus() -> void:
	print("\n-- SUS --")
	ok(Content.SUS_ITEMS.size() == 10, "10 butir")
	var neg := ["tidak", "rumit", "bingung", "sulit", "berbelit", "canggung",
		"membutuhkan bantuan", "perlu belajar", "banyak hal", "terlalu banyak"]
	for i in range(Content.SUS_ITEMS.size()):
		var t := str(Content.SUS_ITEMS[i]).to_lower()
		var is_neg := false
		for w in neg:
			if t.contains(w):
				is_neg = true
		var expect_neg := (i % 2 == 1)
		ok(is_neg == expect_neg, "butir %d polaritas %s: %s" % [i + 1,
			"negatif" if expect_neg else "positif", str(Content.SUS_ITEMS[i]).substr(0, 46)])

func _sandi() -> void:
	print("\n-- sandi Caesar --")
	for m in Content.MAPS:
		for c in m.get("challenges", []):
			if str(c.get("type", "")) != "cipher":
				continue
			var shift := int(c.get("answer_shift", 0))
			var teks := str(c.get("ciphertext", ""))
			var plain := _decode(teks, shift)
			print("      %s: '%s' geser %d -> '%s'" % [c["id"], teks, shift, plain])
			ok(plain.to_upper() == str(c.get("answer", "")).to_upper(),
				"%s: ciphertext menghasilkan jawaban '%s'" % [c["id"], str(c.get("answer", ""))])

## Peta: spawn & seluruh titik interaktif harus berada di lantai yang bisa dicapai.
func _peta() -> void:
	print("\n-- keterjangkauan peta --")
	var spawns: Dictionary = Content.SPAWNS
	for m in Content.MAPS:
		var mid := str(m["id"])
		var path := "res://assets/maps/%s.json" % mid
		if not FileAccess.file_exists(path):
			ok(false, "%s: berkas peta ada" % mid)
			continue
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var solid: Array = meta.get("solid", [])
		if solid.is_empty():
			ok(false, "%s: data solid terbaca" % mid)
			continue
		var rows := solid.size()
		var cols := (solid[0] as Array).size()
		var sp: Vector2 = spawns.get(mid, Vector2(20, 18))
		var start := Vector2i(int(sp.x), int(sp.y))
		var reach := _bfs(solid, start)
		ok(reach.size() > 50, "%s: spawn (%d,%d) di lantai, %d tile terjangkau" % [mid, start.x, start.y, reach.size()])
		var titik: Array = []
		var meta_npc: Dictionary = meta.get("npc", {})
		for n in Content.npcs_of(m):
			# Peta tanpa daftar NPC memakai koordinat NPC dari berkas peta.
			titik.append(["NPC " + str(n.get("name", "?")),
				int(n.get("x", meta_npc.get("x", 0))), int(n.get("y", meta_npc.get("y", 0)))])
		for o in m.get("objects", []):
			titik.append(["objek " + str(o.get("label", "?")), int(o.get("x", 0)), int(o.get("y", 0))])
		if meta.has("portal"):
			var p: Dictionary = meta["portal"]
			titik.append(["portal", int(p.get("x", 0)), int(p.get("y", 0))])
		for t in titik:
			var tx := int(t[1])
			var ty := int(t[2])
			var dalam := tx >= 0 and ty >= 0 and tx < cols and ty < rows
			ok(dalam, "%s: %s di dalam peta (%d,%d)" % [mid, str(t[0]), tx, ty])
			if dalam:
				ok(_dekat(reach, tx, ty), "%s: %s bisa dijangkau dari spawn" % [mid, str(t[0])])

func _bfs(solid: Array, start: Vector2i) -> Dictionary:
	var h := solid.size()
	var w := (solid[0] as Array).size()
	var seen := {}
	if start.x < 0 or start.y < 0 or start.x >= w or start.y >= h:
		return seen
	if int((solid[start.y] as Array)[start.x]) != 0:
		return seen
	seen[start] = true
	var q: Array = [start]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cur + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			if seen.has(n) or int((solid[n.y] as Array)[n.x]) != 0:
				continue
			seen[n] = true
			q.append(n)
	return seen

## Titik dianggap terjangkau bila tile-nya (atau tetangganya) bisa dicapai.
func _dekat(reach: Dictionary, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if reach.has(Vector2i(x + dx, y + dy)):
				return true
	return false

## Rujukan silang: id tantangan unik antar-map, objek menunjuk tantangan yang ada.
func _rujukan() -> void:
	print("\n-- rujukan silang --")
	var semua := {}
	var ganda := []
	for m in Content.MAPS:
		for c in m.get("challenges", []):
			var cid := str(c["id"])
			if semua.has(cid):
				ganda.append(cid)
			semua[cid] = true
	ok(ganda.is_empty(), "id tantangan unik antar-map%s" % ("" if ganda.is_empty() else " (ganda: %s)" % str(ganda)))
	for m in Content.MAPS:
		var mid := str(m["id"])
		var ada := {}
		for c in m.get("challenges", []):
			ada[str(c["id"])] = true
		for o in m.get("objects", []):
			if not o.has("challenge"):
				continue   # komponen yang dikumpulkan, bukan tantangan
			var ref := str(o.get("challenge", ""))
			ok(ada.has(ref), "%s: %s menunjuk tantangan %s" % [mid, str(o.get("id", "?")), ref])
		for n in Content.npcs_of(m):
			for ref in n.get("quest", []):
				ok(ada.has(str(ref)), "%s: quest NPC %s menunjuk %s" % [mid, str(n.get("id", "?")), str(ref)])
	# badge harus dikenali HUD (konstanta BADGE_ICON) dan ikonnya bisa dimuat
	var hud_script = load("res://scripts/ui/hud.gd")
	ok(hud_script != null, "skrip HUD bisa dimuat")
	var konst := {}
	if hud_script != null:
		konst = hud_script.get_script_constant_map()
	var ikon: Dictionary = konst.get("BADGE_ICON", {})
	for m in Content.MAPS:
		var b := str(m.get("badge", ""))
		if b != "":
			ok(ikon.has(b), "badge '%s' dikenali HUD" % b)
			ok(ResourceLoader.exists(str(ikon.get(b, ""))), "ikon badge '%s' bisa dimuat" % b)

## Toko & komponen perangkat: Tabel 2.4/2.6 dan aturan uang (Bab II 2.5).
func _toko() -> void:
	print("\n-- toko & komponen perangkat (Tabel 2.4/2.6) --")
	ok(Content.COMPONENT_IDS.size() == 4, "komponen perangkat berjumlah 4")
	ok(Content.COMPONENT_TOTAL == Content.COMPONENT_IDS.size(),
		"COMPONENT_TOTAL sesuai jumlah komponen (%d)" % Content.COMPONENT_IDS.size())
	for id in Content.COMPONENT_IDS:
		var it: Dictionary = Content.SHOP.get(str(id), {})
		ok(not it.is_empty(), "komponen '%s' dijual di toko" % str(id))
		ok(bool(it.get("component", false)), "komponen '%s' ditandai sebagai komponen" % str(id))
		ok(str(it.get("name", "")).length() > 3, "komponen '%s' punya nama" % str(id))
		ok(int(it.get("price", 0)) > 0, "komponen '%s' punya harga" % str(id))
	# Harga seluruh komponen tidak boleh melebihi uang dari Map 2-Map 4,
	# karena komponen harus dibeli sebelum puzzle Danau dikerjakan.
	var keping := 0
	for m in Content.MAPS:
		var mid := str(m["id"])
		if not Content.COINS_MAPS.has(mid) or mid == "danau":
			continue
		keping += (m["challenges"] as Array).size() * Content.COINS_PER_CHALLENGE
	var harga := 0
	for id in Content.COMPONENT_IDS:
		harga += int((Content.SHOP.get(str(id), {}) as Dictionary).get("price", 0))
	ok(harga <= keping, "harga komponen (%d) <= uang dari Map 2-4 (%d)" % [harga, keping])
	# Komponen tidak lagi ditemukan di peta (Bab III 3.6.4).
	ok(not Content.map_by_id("danau").has("objects"),
		"Danau tidak menyediakan komponen di peta — semuanya dibeli di Kota Unggul")
	for m in Content.MAPS:
		for o in m.get("objects", []):
			ok(not o.has("gives"), "%s: objek %s tidak memberi komponen" % [str(m["id"]), str(o.get("id", "?"))])
	# Nama komponen di slot perakitan harus sama dengan nama di toko.
	for m in Content.MAPS:
		for c in m.get("challenges", []):
			if str(c.get("type", "")) != "craft":
				continue
			var nama_toko := []
			for id in Content.COMPONENT_IDS:
				nama_toko.append(str((Content.SHOP[str(id)] as Dictionary)["name"]))
			for s in c.get("slots", []):
				ok(nama_toko.has(str(s)), "%s: slot '%s' ada di daftar komponen toko" % [c["id"], str(s)])

## Aset: setiap berkas yang dirujuk konten harus benar-benar ada.
func _aset() -> void:
	print("\n-- berkas aset --")
	ok(ResourceLoader.exists("res://assets/sprites/hero.png"), "sprite hero tersedia")
	## MC baru (aset kelompok): 10 frame idle + 10 frame run + potret.
	var mc_idle := 0
	var mc_run := 0
	for i in range(10):
		if ResourceLoader.exists("res://assets/sprites/mc/idle_%02d.png" % i):
			mc_idle += 1
		if ResourceLoader.exists("res://assets/sprites/mc/run_%02d.png" % i):
			mc_run += 1
	ok(mc_idle == 10, "aset MC idle lengkap (10 frame)")
	ok(mc_run == 10, "aset MC run lengkap (10 frame)")
	ok(ResourceLoader.exists("res://assets/sprites/mc/portrait.png"), "potret MC tersedia")
	for m in Content.MAPS:
		var mid := str(m["id"])
		ok(FileAccess.file_exists("res://assets/maps/%s.json" % mid), "%s: tilemap json ada" % mid)
		ok(ResourceLoader.exists("res://assets/maps/%s.png" % mid), "%s: gambar tilemap ada" % mid)
		ok(FileAccess.file_exists("res://assets/maps/%s.props.json" % mid), "%s: data properti tile ada" % mid)
		var badge := str(m.get("badge", ""))
		if badge != "":
			ok(ResourceLoader.exists("res://assets/ui/badge_%s.png" % badge),
				"%s: ikon badge '%s' ada" % [mid, badge])
		for n in m.get("npcs", []):
			var spr := str(n.get("sprite", ""))
			ok(spr != "" and ResourceLoader.exists("res://assets/sprites/npc_%s.png" % spr),
				"%s: sprite NPC %s ('%s') ada" % [mid, str(n.get("id", "?")), spr])
	ok(ResourceLoader.exists("res://assets/ui/badge_guardian.png"), "ikon badge guardian (Map 6) ada")

## Tipe tantangan: harus dikenal panel puzzle dan punya data yang cukup.
func _tipe() -> void:
	print("\n-- tipe tantangan --")
	var dikenal := ["mcq", "build", "order", "cipher", "craft"]
	for m in Content.MAPS:
		for c in m.get("challenges", []):
			var t := str(c.get("type", ""))
			var cid := str(c.get("id", "?"))
			ok(dikenal.has(t), "%s: tipe '%s' dikenal panel puzzle" % [cid, t])
			match t:
				"mcq":
					var o: Array = c.get("options", [])
					ok(o.size() >= 2, "%s: punya >= 2 opsi" % cid)
					var uniq := {}
					for x in o:
						uniq[str(x)] = true
					ok(uniq.size() == o.size(), "%s: opsi tidak ada yang kembar" % cid)
					var a := int(c.get("answer", -1))
					ok(a >= 0 and a < o.size(), "%s: indeks jawaban valid (%d)" % [cid, a])
				"build":
					var parts: Array = c.get("parts", [])
					ok(parts.size() > 0, "%s: punya bagian query" % cid)
					for p in parts:
						var po: Array = (p as Dictionary).get("options", [])
						ok(po.has(str((p as Dictionary).get("answer", ""))),
							"%s: jawaban bagian '%s' ada di opsinya" % [cid, str((p as Dictionary).get("pre", "?"))])
				"order":
					ok((c.get("items", []) as Array).size() >= 3, "%s: punya >= 3 langkah untuk diurutkan" % cid)
				"cipher":
					ok(str(c.get("ciphertext", "")) != "", "%s: punya ciphertext" % cid)
					ok(str(c.get("answer", "")) != "", "%s: punya jawaban" % cid)
				"craft":
					var slots: Array = c.get("slots", [])
					var pool: Array = c.get("pool", [])
					ok(slots.size() > 0, "%s: punya slot perakitan" % cid)
					for s in slots:
						ok(pool.has(str(s)), "%s: slot '%s' tersedia di pilihan" % [cid, str(s)])

func _decode(s: String, shift: int) -> String:
	var out := ""
	for i in range(s.length()):
		var ch := s[i]
		if ch >= "A" and ch <= "Z":
			var k := (ch.unicode_at(0) - 65 - shift + 26) % 26
			out += char(65 + k)
		elif ch >= "a" and ch <= "z":
			var k2 := (ch.unicode_at(0) - 97 - shift + 26) % 26
			out += char(97 + k2)
		else:
			out += ch
	return out

func _kunci() -> void:
	print("\n-- kelengkapan kunci tantangan --")
	for m in Content.MAPS:
		for c in m.get("challenges", []):
			var t := str(c.get("type", "mcq"))
			match t:
				"mcq":
					ok(c.has("answer") and c.has("options"), "%s: mcq punya options+answer" % c["id"])
				"build":
					ok(c.has("parts"), "%s: build punya parts" % c["id"])
				"order":
					ok(c.has("items"), "%s: order punya items" % c["id"])
				"cipher":
					ok(c.has("answer_shift"), "%s: cipher punya answer_shift" % c["id"])
				"craft":
					ok(c.has("slots"), "%s: craft punya slots" % c["id"])
			ok(str(c.get("explain", "")).length() > 10, "%s: ada pembahasan (feedback)" % c["id"])
