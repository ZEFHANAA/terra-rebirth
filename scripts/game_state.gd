extends Node
## Autoload "Game" — status permainan, penyimpanan, dan aturan progres.

signal xp_changed(xp: int, level: int)
signal challenge_completed(challenge_id: String)
signal badge_earned(badge_id: String, badge_name: String)
signal map_completed(map_id: String)
signal prompt_changed(text: String)
signal coins_changed(coins: int)
signal items_changed()
signal components_changed()

const SAVE_PATH := "user://save_terra.json"
const RECORD_PATH := "user://records_terra.json"

var xp: int = 0
var badges: Array[String] = []
var done: Dictionary = {}          # challenge_id -> true
var current_map: String = "kota"
var player_code: String = ""       # kode peserta untuk mode riset
var prompt_text: String = ""
var coins: int = 0
var items: Dictionary = {}         # item_id -> jumlah yang dimiliki
var components: Dictionary = {}    # komponen Danau yang sudah ditemukan
var ending_choice: String = ""     # "seal" atau "flow"

const COINS_PER_CHALLENGE := 10
## Barang yang dijual pedagang di Kota Unggul.
const SHOP := {
	"lensa": {
		"name": "Lensa Analisis",
		"price": 20,
		"desc": "Sekali pakai. Membuka petunjuk pada tantangan yang sedang dibuka.",
	},
}

func reset() -> void:
	xp = 0
	badges.clear()
	done.clear()
	current_map = "kota"
	coins = 0
	items.clear()
	components.clear()
	ending_choice = ""
	items_changed.emit()
	components_changed.emit()
	xp_changed.emit(xp, level())

func set_prompt(text: String) -> void:
	if text != prompt_text:
		prompt_text = text
		prompt_changed.emit(text)

func level() -> int:
	return Content.level_for_xp(xp)

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
	return Content.map_by_id(map_id).get("challenges", []).size()

func is_map_cleared(map_id: String) -> bool:
	return map_done(map_id) >= map_total(map_id) and map_total(map_id) > 0

func has_badge(badge_id: String) -> bool:
	return badge_id == "" or badges.has(badge_id)

## Syarat buka peta: level minimum DAN badge peta sebelumnya.
func map_unlocked(map_id: String) -> bool:
	var m := Content.map_by_id(map_id)
	if m.is_empty():
		return false
	if level() < int(m["req_level"]):
		return false
	var req: String = m["req_badge"]
	if req != "" and not badges.has(req):
		return false
	return true

func unlock_hint(map_id: String) -> String:
	var m := Content.map_by_id(map_id)
	var parts: Array[String] = []
	if level() < int(m["req_level"]):
		parts.append("Lv %d" % int(m["req_level"]))
	var req: String = m["req_badge"]
	if req != "" and not badges.has(req):
		var prev := ""
		for pm in Content.MAPS:
			if pm.get("badge", "") == req:
				prev = str(pm.get("badge_name", req))
		parts.append("badge %s" % (prev if prev != "" else req))
	if parts.is_empty():
		return ""
	return "Butuh " + " + ".join(parts)

## Menyelesaikan satu tantangan. Mengembalikan true bila baru diselesaikan.
func complete_challenge(challenge_id: String, map_id: String) -> bool:
	if done.has(challenge_id):
		return false
	done[challenge_id] = true
	var before := level()
	xp += Content.XP_PER_CHALLENGE
	coins += COINS_PER_CHALLENGE
	coins_changed.emit(coins)
	challenge_completed.emit(challenge_id)
	xp_changed.emit(xp, level())
	if level() > before:
		pass
	# badge hanya diberikan setelah SELURUH tantangan peta selesai
	if is_map_cleared(map_id):
		var m := Content.map_by_id(map_id)
		var b: String = m.get("badge", "")
		if b != "" and not badges.has(b):
			badges.append(b)
			badge_earned.emit(b, m.get("badge_name", ""))
		map_completed.emit(map_id)
	save_game()
	return true

func next_map_id(map_id: String) -> String:
	for i in range(Content.MAPS.size()):
		if Content.MAPS[i]["id"] == map_id:
			if i + 1 < Content.MAPS.size():
				return Content.MAPS[i + 1]["id"]
			return ""
	return ""

# ------------------------------------------------------------------ simpan
func save_game() -> void:
	var data := {
		"xp": xp, "badges": badges, "done": done, "current_map": current_map,
		"player_code": player_code, "coins": coins, "items": items,
		"components": components, "ending_choice": ending_choice
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var raw := f.get_as_text()
	f.close()
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	xp = int(data.get("xp", 0))
	badges.clear()
	for b in data.get("badges", []):
		badges.append(str(b))
	done = data.get("done", {})
	current_map = str(data.get("current_map", "kota"))
	player_code = str(data.get("player_code", ""))
	coins = int(data.get("coins", 0))
	items = data.get("items", {})
	components = data.get("components", {})
	ending_choice = str(data.get("ending_choice", ""))
	components_changed.emit()
	coins_changed.emit(coins)
	items_changed.emit()
	xp_changed.emit(xp, level())
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# ------------------------------------------------------------------ rekaman riset
func save_record(rec: Dictionary) -> void:
	var arr: Array = []
	if FileAccess.file_exists(RECORD_PATH):
		var f := FileAccess.open(RECORD_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_ARRAY:
				arr = parsed
	arr.append(rec)
	var out := FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(arr, "\t"))
		out.close()

func upsert_record(kode: String, rec: Dictionary) -> void:
	var arr: Array = []
	if FileAccess.file_exists(RECORD_PATH):
		var f := FileAccess.open(RECORD_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_ARRAY:
				arr = parsed
	var replaced := false
	for i in range(arr.size()):
		if str(arr[i].get("kode", "")) == kode:
			arr[i] = rec
			replaced = true
	if not replaced:
		arr.append(rec)
	var out := FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(arr, "\t"))
		out.close()

func read_records() -> Array:
	if not FileAccess.file_exists(RECORD_PATH):
		return []
	var f := FileAccess.open(RECORD_PATH, FileAccess.READ)
	if not f:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_ARRAY else []

func export_csv(path: String) -> bool:
	if not FileAccess.file_exists(RECORD_PATH):
		return false
	var f := FileAccess.open(RECORD_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		return false
	var lines := PackedStringArray()
	lines.append("kode,waktu,pre,post,ngain,sus")
	for r in parsed:
		lines.append("%s,%s,%d,%d,%.2f,%.1f" % [
			str(r.get("kode", "")), str(r.get("waktu", "")),
			int(r.get("pre", 0)), int(r.get("post", 0)),
			float(r.get("ngain", 0.0)), float(r.get("sus", 0.0))
		])
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out:
		out.store_string("\n".join(lines))
		out.close()
	return true

# ------------------------------------------------------------------ toko
func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func can_afford(item_id: String) -> bool:
	var it: Dictionary = SHOP.get(item_id, {})
	return not it.is_empty() and coins >= int(it["price"])

## Membeli satu barang. Mengembalikan true bila berhasil.
func buy_item(item_id: String) -> bool:
	if not can_afford(item_id):
		return false
	coins -= int(SHOP[item_id]["price"])
	items[item_id] = item_count(item_id) + 1
	coins_changed.emit(coins)
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

# ------------------------------------------------------------------ komponen Danau
func has_component(id: String) -> bool:
	return bool(components.get(id, false))

func collect_component(id: String) -> void:
	components[id] = true
	components_changed.emit()
	save_game()

func component_count() -> int:
	return components.size()

func all_components() -> bool:
	return component_count() >= 3

func set_ending_choice(id: String) -> void:
	ending_choice = id
	save_game()
