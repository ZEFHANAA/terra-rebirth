extends Node
## Autoload "Game" — status permainan, penyimpanan, dan aturan progres.
##
## Aturan progres mengikuti Bab II 2.5 dan Tabel 2.5:
##   - menyelesaikan satu quest TIDAK memberi badge;
##   - badge diberikan setelah SELURUH quest pada satu map selesai;
##   - badge map sebelumnya adalah syarat masuk map berikutnya.
## Tidak ada level maupun XP: satu-satunya kunci akses adalah badge.

signal challenge_completed(challenge_id: String)
signal badge_earned(badge_id: String, badge_name: String)
signal map_completed(map_id: String)
signal prompt_changed(text: String)
signal coins_changed(coins: int)
signal items_changed()
signal components_changed()
signal progress_changed()
signal map_failed(map_id: String)
signal lives_changed(map_id: String, lives: int)

# ------------------------------------------------------------- audio
## Musik latar + efek suara (WAV hasil sintesis di assets/audio/).
var audio_on := true
var _bgm: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _bgm_id := ""

const AUDIO_DIR := "res://assets/audio/"

func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	for i in range(4):
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		_sfx_pool.append(pl)

func play_bgm(id: String) -> void:
	if _bgm == null or (not audio_on) or _bgm_id == id:
		return
	var path := AUDIO_DIR + id + ".wav"
	if not ResourceLoader.exists(path):
		return
	var st = load(path)
	if st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = st.data.size() / 2  # mono 16 bit -> jumlah frame
	_bgm.stream = st
	_bgm.volume_db = -13.0
	_bgm.play()
	_bgm_id = id

func sfx(id: String, vol: float = -7.0) -> void:
	if not audio_on or _sfx_pool.is_empty():
		return
	var path := AUDIO_DIR + id + ".wav"
	if not ResourceLoader.exists(path):
		return
	var pl := _sfx_pool[_sfx_next % _sfx_pool.size()]
	_sfx_next += 1
	pl.stream = load(path)
	pl.volume_db = vol
	pl.play()

func toggle_audio() -> bool:
	audio_on = not audio_on
	if not audio_on:
		if _bgm != null:
			_bgm.stop()
		for pl in _sfx_pool:
			pl.stop()
	else:
		_bgm_id = ""
		play_bgm("bgm_final" if current_map == "source" else "bgm_explore")
	return audio_on

## Path bisa dialihkan saat pengujian/demo supaya data peserta asli tidak tersentuh.
var save_path := "user://save_terra.json"
var record_path := "user://records_terra.json"

var badges: Array[String] = []
var done: Dictionary = {}          # challenge_id -> true
var map_lives: Dictionary = {}      # map_id -> nyawa tersisa, per wilayah
var outro_seen: Dictionary = {}     # map_id -> penutup cerita sudah ditampilkan
var current_map: String = "kota"
var player_code: String = ""       # kode peserta untuk mode pengujian
var prompt_text: String = ""
var coins: int = 0
## Tantangan yang koinnya sudah pernah dibayarkan. Tidak pernah direset, supaya
## mengulang wilayah setelah nyawa habis tidak menjadi tambang uang.
var earned: Dictionary = {}
var items: Dictionary = {}         # item_id -> jumlah yang dimiliki
var components: Dictionary = {}    # komponen perangkat yang sudah dibeli di toko
var ending_choice: String = ""     # "seal" atau "flow"

## Bank soal: hasil undian disimpan agar soal tidak berganti saat quest dibuka
## ulang, dan agar tim peneliti bisa tahu soal mana yang diterima peserta.
var bank_picks: Dictionary = {}    # challenge_id -> id soal bank
var puzzle_picks: Dictionary = {}  # challenge_id -> id puzzle bank
var post_picks: Array = []         # id soal post-test yang diundi untuk peserta
var penalized: Dictionary = {}     # challenge_id -> true (nyawa sudah dipotong)

## Status asesmen (post-test & SUS) pada sesi berjalan.
var post_answers: Array = []       # jawaban post-test, -1 bila kosong
var post_done: bool = false
var sus_answers: Array = []        # jawaban SUS 1-5, -1 bila kosong
var sus_done: bool = false
var session_start: int = 0         # unix time mulai bermain
var session_end: int = 0           # unix time selesai asesmen
var playtime_before: float = 0.0   # detik bermain pada sesi-sesi sebelumnya

const COINS_PER_CHALLENGE := Content.COINS_PER_CHALLENGE
## Uang hanya diberikan untuk puzzle di Map 2 sampai Map 5 (Bab II 2.5).
const COINS_MAPS := Content.COINS_MAPS

## Empat komponen perangkat yang wajib dibeli di toko (Tabel 2.4/2.6).
const COMPONENT_IDS := Content.COMPONENT_IDS
const COMPONENT_TOTAL := Content.COMPONENT_TOTAL

## Barang yang dijual pedagang di Kota Unggul (Tabel 2.6: "membeli item").
## "component": true menandai komponen perangkat IoT — membelinya langsung
## mencatat komponen sebagai dimiliki (bukan barang sekali pakai).
const SHOP := Content.SHOP

func reset() -> void:
	badges.clear()
	done.clear()
	map_lives.clear()
	outro_seen.clear()
	bank_picks.clear()
	puzzle_picks.clear()
	post_picks.clear()
	penalized.clear()
	current_map = "kota"
	coins = 0
	earned.clear()            # peserta baru: riwayat pembayaran koin ikut direset
	items.clear()
	components.clear()
	ending_choice = ""
	player_code = ""          # peserta baru: kode harus diisi ulang di asesmen
	playtime_before = 0.0
	post_answers = []
	post_done = false
	sus_answers = []
	sus_done = false
	session_start = int(Time.get_unix_time_from_system())
	session_end = 0
	items_changed.emit()
	components_changed.emit()
	coins_changed.emit(coins)
	progress_changed.emit()

func set_prompt(text: String) -> void:
	if text != prompt_text:
		prompt_text = text
		prompt_changed.emit(text)

func total_done() -> int:
	return done.size()

func map_done(map_id: String) -> int:
	var m := Content.map_by_id(map_id)
	var n := 0
	for c in m.get("challenges", []):
		if done.has(c["id"]):
			n += 1
	return n

func map_total(map_id: String) -> int:
	return (Content.map_by_id(map_id).get("challenges", []) as Array).size()

func is_map_cleared(map_id: String) -> bool:
	return map_total(map_id) > 0 and map_done(map_id) >= map_total(map_id)

# ------------------------------------------------------- nyawa & bank soal
## Nyawa tersisa pada satu wilayah.
func lives_left(map_id: String) -> int:
	return int(map_lives.get(map_id, Content.LIVES_PER_MAP))

## Mencatat satu jawaban salah. Satu quest hanya memotong satu nyawa, supaya
## satu teka-teki sulit tidak langsung menghabiskan seluruh wilayah.
## Mengembalikan sisa nyawa setelah pencatatan.
func note_mistake(map_id: String, challenge_id: String) -> int:
	if challenge_id == "" or penalized.has(challenge_id):
		return lives_left(map_id)
	penalized[challenge_id] = true
	var left := lives_left(map_id) - 1
	map_lives[map_id] = left
	lives_changed.emit(map_id, left)
	if left <= 0:
		_fail_map(map_id)
	else:
		save_game()
	return left

## Nyawa habis: SELURUH progres dan badge dihapus. Uang, item, dan komponen yang
## sudah dibeli tetap tersimpan supaya pembelian pemain tidak hangus. Kode peserta
## juga dipertahankan karena itu identitas, bukan progres permainan.
func _fail_map(map_id: String) -> void:
	badges.clear()
	done.clear()
	outro_seen.clear()
	bank_picks.clear()
	puzzle_picks.clear()
	penalized.clear()
	post_picks.clear()
	map_lives.clear()
	post_answers = []
	post_done = false
	sus_answers = []
	sus_done = false
	ending_choice = ""
	current_map = "kota"
	save_game()
	progress_changed.emit()
	lives_changed.emit(map_id, 0)
	map_failed.emit(map_id)

## Soal bank untuk satu tantangan. Undian disimpan, jadi soal tidak berganti
## saat panel dibuka ulang, tetapi tetap berbeda antar peserta.
func bank_question(challenge_id: String, materi: String) -> Dictionary:
	var bank := Content.bank_of(materi)
	if bank.is_empty():
		return {}
	var picked := str(bank_picks.get(challenge_id, ""))
	if picked != "":
		for it in bank:
			if str(it.get("id", "")) == picked:
				return it
	var idx := _roll_index(challenge_id, materi, bank.size())
	var item: Dictionary = bank[idx]
	bank_picks[challenge_id] = str(item.get("id", ""))
	save_game()
	return item

## Mengundi soal yang belum dipakai pada wilayah yang sama. Undian memakai
## RNG acak (bukan seed tetap) supaya soal benar-benar berbeda tiap sesi.
func _roll_index(challenge_id: String, materi: String, n: int) -> int:
	var bank := Content.bank_of(materi)
	var prefix := challenge_id.split("-")[0]
	var used: Array = []
	for cid in bank_picks.keys():
		if str(cid).begins_with(prefix + "-"):
			used.append(str(bank_picks[cid]))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var start := rng.randi_range(0, n - 1)
	for step in range(n):
		var i := (start + step) % n
		if not used.has(str(bank[i].get("id", ""))):
			return i
	return start

## Puzzle acak untuk satu tantangan puzzle. Undian disimpan, jadi puzzle tidak
## berganti saat panel dibuka ulang, tetapi berbeda tiap sesi.
func bank_puzzle(challenge_id: String, materi: String) -> Dictionary:
	var bank := Content.puzzles_of(materi)
	if bank.is_empty():
		return {}
	var picked := str(puzzle_picks.get(challenge_id, ""))
	if picked != "":
		for it in bank:
			if str(it.get("id", "")) == picked:
				return it
	var idx := _roll_puzzle_index(bank, challenge_id)
	var item: Dictionary = bank[idx]
	puzzle_picks[challenge_id] = str(item.get("id", ""))
	save_game()
	return item

func _roll_puzzle_index(bank: Array, challenge_id: String) -> int:
	var prefix := challenge_id.split("-")[0]
	var used: Array = []
	for cid in puzzle_picks.keys():
		if str(cid).begins_with(prefix + "-"):
			used.append(str(puzzle_picks[cid]))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var start := rng.randi_range(0, bank.size() - 1)
	for step in range(bank.size()):
		var i := (start + step) % bank.size()
		if not used.has(str(bank[i].get("id", ""))):
			return i
	return start

## Puzzle gagal tidak memotong satu nyawa, tetapi langsung menghabiskan nyawa
## wilayah itu sehingga seluruh progres direset.
func fail_puzzle(map_id: String) -> void:
	_fail_map(map_id)

## Dua puluh soal post-test (5 per materi) yang diundi untuk peserta ini.
func posttest_items() -> Array:
	if post_picks.is_empty():
		post_picks = Content.posttest_ids(player_code)
		save_game()
	return Content.items_by_ids(post_picks)

func has_badge(badge_id: String) -> bool:
	return badge_id == "" or badges.has(badge_id)

## Syarat buka map: badge map sebelumnya, atau (khusus Map 2) quest pengantar
## di Kota Unggul sudah diselesaikan. Tidak ada syarat level.
func map_unlocked(map_id: String) -> bool:
	var m := Content.map_by_id(map_id)
	if m.is_empty():
		return false
	var req_badge := str(m.get("req_badge", ""))
	if req_badge != "" and not badges.has(req_badge):
		return false
	var req_clear := str(m.get("req_clear", ""))
	if req_clear != "" and not is_map_cleared(req_clear):
		return false
	return true

func unlock_hint(map_id: String) -> String:
	var m := Content.map_by_id(map_id)
	var parts: Array[String] = []
	var req_badge := str(m.get("req_badge", ""))
	if req_badge != "" and not badges.has(req_badge):
		parts.append("badge %s" % Content.badge_name_of(req_badge))
	var req_clear := str(m.get("req_clear", ""))
	if req_clear != "" and not is_map_cleared(req_clear):
		var pm := Content.map_by_id(req_clear)
		parts.append("seluruh quest %s" % str(pm.get("name", req_clear)))
	if parts.is_empty():
		return ""
	return "Butuh " + " + ".join(parts)

## Menyelesaikan satu tantangan. Mengembalikan true bila baru diselesaikan.
func complete_challenge(challenge_id: String, map_id: String) -> bool:
	if done.has(challenge_id):
		return false
	done[challenge_id] = true
	# Uang hanya dari puzzle Map 2-Map 5, dan hanya sekali untuk setiap puzzle —
	# termasuk setelah progres direset, karena `earned` tidak ikut dihapus.
	if COINS_MAPS.has(map_id) and not earned.has(challenge_id):
		earned[challenge_id] = true
		coins += COINS_PER_CHALLENGE
		coins_changed.emit(coins)
		sfx("sfx_coin")
	challenge_completed.emit(challenge_id)
	progress_changed.emit()
	# Badge HANYA setelah seluruh tantangan pada map selesai.
	if is_map_cleared(map_id):
		var m := Content.map_by_id(map_id)
		var b := str(m.get("badge", ""))
		if b != "" and not badges.has(b):
			badges.append(b)
			sfx("sfx_badge")
			badge_earned.emit(b, str(m.get("badge_name", "")))
		map_completed.emit(map_id)
	save_game()
	return true

func next_map_id(map_id: String) -> String:
	var i := Content.map_index(map_id)
	if i >= 0 and i + 1 < Content.MAPS.size():
		return str(Content.MAPS[i + 1]["id"])
	return ""

# ------------------------------------------------------- asesmen (post-test)
## Menilai post-test. Mengembalikan {nilai, benar, total, per_materi, tuntas}.
func grade_posttest(answers: Array) -> Dictionary:
	var benar := 0
	var per := {}
	for mt in Content.MATERI:
		per[mt] = {"benar": 0, "total": 0}
	var items := posttest_items()
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var mt := str(item["m"])
		per[mt]["total"] = int(per[mt]["total"]) + 1
		var a := int(answers[i]) if i < answers.size() else -1
		if a == int(item["a"]):
			benar += 1
			per[mt]["benar"] = int(per[mt]["benar"]) + 1
	var total := items.size()
	var nilai := int(round(float(benar) / float(total) * 100.0)) if total > 0 else 0
	return {
		"nilai": nilai,
		"benar": benar,
		"total": total,
		"per_materi": per,
		"tuntas": nilai >= Content.PASSING_SCORE,
	}

func submit_posttest(answers: Array) -> Dictionary:
	post_answers = answers.duplicate()
	post_done = true
	var res := grade_posttest(post_answers)
	save_game()
	# Simpan lebih awal supaya jawaban post-test tidak hilang bila responden
	# berhenti sebelum mengisi SUS; baris yang sama diperbarui saat SUS dikirim.
	save_assessment_record(-1.0)
	return res

## Kunci jawaban untuk 20 soal yang benar-benar diterima peserta ini.
func answer_key() -> Array:
	var out: Array = []
	for it in posttest_items():
		out.append(int(it["a"]))
	return out

func posttest_result() -> Dictionary:
	if not post_done:
		return {}
	return grade_posttest(post_answers)

## Skor SUS 0-100 dari 10 jawaban skala 1-5 (Bab III 3.11).
static func sus_score(values: Array) -> float:
	var total := 0.0
	for i in range(values.size()):
		var val := int(values[i])
		if val < 1:
			return -1.0
		if i % 2 == 0:
			total += float(val - 1)
		else:
			total += float(5 - val)
	return total * 2.5

## Skor SUS dari jawaban yang tersimpan (0 bila belum diisi).
func sus_value() -> float:
	if sus_answers.is_empty():
		return 0.0
	var s := sus_score(sus_answers)
	return maxf(0.0, s)

func submit_sus(values: Array) -> float:
	var score := sus_score(values)
	if score < 0.0:
		return -1.0   # masih ada butir yang belum dinilai
	sus_answers = values.duplicate()
	sus_done = true
	session_end = int(Time.get_unix_time_from_system())
	save_game()
	save_assessment_record(score)
	return score

func assessment_complete() -> bool:
	return post_done and sus_done

## Durasi bermain dalam menit, dihitung dari mulai permainan sampai SUS selesai.
func playtime_minutes() -> float:
	if session_start <= 0 and playtime_before <= 0.0:
		return 0.0
	var end := session_end
	if end <= 0:
		end = int(Time.get_unix_time_from_system())
	var span := 0.0
	if session_start > 0:
		span = float(maxi(0, end - session_start))
	return (playtime_before + span) / 60.0

# ------------------------------------------------------------------ simpan
func save_game() -> void:
	# Durasi sesi berjalan dipindahkan ke akumulasi agar "Lanjutkan" tidak
	# menghitung jeda antar sesi sebagai waktu bermain.
	if session_end <= 0 and session_start > 0:
		playtime_before += float(maxi(0, int(Time.get_unix_time_from_system()) - session_start))
		session_start = int(Time.get_unix_time_from_system())
	var data := {
		"badges": badges, "done": done, "current_map": current_map,
		"player_code": player_code, "coins": coins, "items": items,
		"map_lives": map_lives, "outro_seen": outro_seen, "bank_picks": bank_picks,
		"puzzle_picks": puzzle_picks,
		"post_picks": post_picks, "penalized": penalized,
		"components": components, "ending_choice": ending_choice, "earned": earned,
		"post_answers": post_answers, "post_done": post_done,
		"sus_answers": sus_answers, "sus_done": sus_done,
		"session_start": session_start, "session_end": session_end,
		"playtime_before": playtime_before,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(save_path, FileAccess.READ)
	if not f:
		return false
	var raw := f.get_as_text()
	f.close()
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	badges.clear()
	for b in data.get("badges", []):
		badges.append(str(b))
	done = data.get("done", {})
	map_lives = data.get("map_lives", {})
	outro_seen = data.get("outro_seen", {})
	bank_picks = data.get("bank_picks", {})
	puzzle_picks = data.get("puzzle_picks", {})
	post_picks = data.get("post_picks", [])
	penalized = data.get("penalized", {})
	current_map = str(data.get("current_map", "kota"))
	player_code = str(data.get("player_code", ""))
	coins = int(data.get("coins", 0))
	## Save lama belum punya "earned": anggap tantangan yang sudah selesai sudah
	## dibayar, supaya pemain lama tidak bisa memanen koin dua kali.
	earned = data.get("earned", done.duplicate())
	items = data.get("items", {})
	components = data.get("components", {})
	ending_choice = str(data.get("ending_choice", ""))
	post_answers = data.get("post_answers", [])
	post_done = bool(data.get("post_done", false))
	sus_answers = data.get("sus_answers", [])
	sus_done = bool(data.get("sus_done", false))
	session_start = int(data.get("session_start", 0))
	session_end = int(data.get("session_end", 0))
	playtime_before = float(data.get("playtime_before", 0.0))
	components_changed.emit()
	coins_changed.emit(coins)
	items_changed.emit()
	progress_changed.emit()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

# ------------------------------------------------------------ rekaman riset
func _read_records() -> Array:
	if not FileAccess.file_exists(record_path):
		return []
	var f := FileAccess.open(record_path, FileAccess.READ)
	if not f:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_ARRAY else []

func _write_records(arr: Array) -> void:
	var out := FileAccess.open(record_path, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(arr, "\t"))
		out.close()

func read_records() -> Array:
	return _read_records()

## Menyimpan satu baris data peserta. Satu kode peserta hanya punya satu baris;
## data terbaru menimpa data lama.
func upsert_record(kode: String, rec: Dictionary) -> void:
	var arr := _read_records()
	var replaced := false
	for i in range(arr.size()):
		if str(arr[i].get("kode", "")) == kode:
			arr[i] = rec
			replaced = true
	if not replaced:
		arr.append(rec)
	_write_records(arr)

func save_assessment_record(sus: float) -> void:
	var res := posttest_result()
	var per := res.get("per_materi", {}) as Dictionary
	var rec := {
		"kode": player_code if player_code != "" else "TANPA-KODE",
		"tanggal": Time.get_datetime_string_from_system(),
		"durasi_menit": snappedf(playtime_minutes(), 0.1),
		"benar": int(res.get("benar", 0)),
		"total": int(res.get("total", 0)),
		"post": int(res.get("nilai", 0)),
		"tuntas": bool(res.get("tuntas", false)),
		"materi": {},
		"sus": sus,
		"post_jawaban": post_answers,
		"sus_jawaban": sus_answers,
		"tantangan": total_done(),
		"badge": badges.size(),
	}
	for mt in Content.MATERI:
		rec["materi"][mt] = int((per.get(mt, {}) as Dictionary).get("benar", 0))
	upsert_record(str(rec["kode"]), rec)

func export_csv(path: String) -> bool:
	var arr := _read_records()
	if arr.is_empty():
		return false
	var head := ["kode", "tanggal", "durasi_menit", "benar", "total", "post",
		"basis_data", "sistem_operasi", "kriptografi", "iot", "tuntas", "sus"]
	for i in range(post_picks.size() if not post_picks.is_empty() else 20):
		head.append("q%d" % (i + 1))
	for i in range(Content.SUS_ITEMS.size()):
		head.append("s%d" % (i + 1))
	var lines := PackedStringArray()
	lines.append(",".join(head))
	for r in arr:
		var per := r.get("materi", {}) as Dictionary
		var row := [
			str(r.get("kode", "")), str(r.get("tanggal", "")),
			"%.1f" % float(r.get("durasi_menit", 0.0)),
			str(int(r.get("benar", 0))), str(int(r.get("total", 0))),
			str(int(r.get("post", 0))),
			str(int(per.get("Basis Data", 0))),
			str(int(per.get("Sistem Operasi", 0))),
			str(int(per.get("Kriptografi", 0))),
			str(int(per.get("Internet of Things", 0))),
			"1" if bool(r.get("tuntas", false)) else "0",
			("" if float(r.get("sus", -1.0)) < 0.0 else "%.1f" % float(r.get("sus", 0.0))),
		]
		var pj: Array = r.get("post_jawaban", [])
		for i in range(post_picks.size() if not post_picks.is_empty() else 20):
			row.append(str(int(pj[i]) + 1) if i < pj.size() and int(pj[i]) >= 0 else "")
		var sj: Array = r.get("sus_jawaban", [])
		for i in range(Content.SUS_ITEMS.size()):
			row.append(str(int(sj[i])) if i < sj.size() and int(sj[i]) > 0 else "")
		lines.append(",".join(row))
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out:
		out.store_string("\n".join(lines))
		out.close()
	return true

# ------------------------------------------------------------------ toko
func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func is_component_item(item_id: String) -> bool:
	return bool((SHOP.get(item_id, {}) as Dictionary).get("component", false))

## Komponen perangkat yang belum dibeli, sesuai urutan Tabel 2.4/2.6.
func missing_components() -> Array:
	var out: Array = []
	for id in COMPONENT_IDS:
		if not has_component(str(id)):
			out.append(str(id))
	return out

## Harga seluruh komponen yang belum dibeli. Dipakai agar uang milik pemain
## tidak habis untuk barang lain sebelum komponen Map 5 lengkap.
func missing_components_cost() -> int:
	var total := 0
	for id in missing_components():
		total += int((SHOP.get(id, {}) as Dictionary).get("price", 0))
	return total

## Harga seluruh komponen perangkat (Tabel 2.4/2.6).
func components_cost() -> int:
	var total := 0
	for id in COMPONENT_IDS:
		total += int((SHOP.get(str(id), {}) as Dictionary).get("price", 0))
	return total

func component_name(id: String) -> String:
	return str((SHOP.get(id, {}) as Dictionary).get("name", id))

## Cek kemampuan membeli. Untuk barang non-komponen, uang yang tersisa setelah
## pembelian harus tetap cukup untuk komponen yang belum dibeli (Bab II 2.5).
func can_afford(item_id: String) -> bool:
	var it: Dictionary = SHOP.get(item_id, {})
	if it.is_empty():
		return false
	var price := int(it["price"])
	if coins < price:
		return false
	if is_component_item(item_id):
		return true
	return coins - price >= missing_components_cost()

## Membeli satu barang. Mengembalikan true bila berhasil.
func buy_item(item_id: String) -> bool:
	if not can_afford(item_id):
		return false
	coins -= int(SHOP[item_id]["price"])
	coins_changed.emit(coins)
	if is_component_item(item_id):
		components[item_id] = true
		components_changed.emit()
	else:
		items[item_id] = item_count(item_id) + 1
		items_changed.emit()
	save_game()
	return true

## Memakai satu barang. Mengembalikan true bila berhasil.
func use_item(item_id: String) -> bool:
	if item_count(item_id) <= 0:
		return false
	items[item_id] = item_count(item_id) - 1
	items_changed.emit()
	save_game()
	return true

# ------------------------------------------------------------ komponen Danau
## Komponen hanya diperoleh dengan MEMBELI di toko Kota Unggul (Bab III 3.6.4),
## tidak lagi ditemukan di peta Danau.
func has_component(id: String) -> bool:
	return bool(components.get(id, false))

func component_count() -> int:
	return COMPONENT_TOTAL - missing_components().size()

func all_components() -> bool:
	return missing_components().is_empty()

func set_ending_choice(id: String) -> void:
	ending_choice = id
	save_game()
