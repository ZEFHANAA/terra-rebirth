extends SceneTree
## Menulis daftar titik penting tiap peta (NPC, objek, portal) ke /tmp/points.json
## supaya penata properti tidak menaruh aset besar di atasnya.
## Jalankan: godot --headless --path . --script res://tools/dump_points.gd

func _init() -> void:
	var out := {}
	for m in Content.MAPS:
		var mid := str(m["id"])
		var pts: Array = []
		for n in Content.npcs_of(m):
			pts.append({"kind": "npc", "x": int(n.get("x", -1)), "y": int(n.get("y", -1))})
		for o in m.get("objects", []):
			pts.append({"kind": "obj", "x": int(o.get("x", -1)), "y": int(o.get("y", -1))})
		if m.has("portal"):
			var p = m["portal"]
			if typeof(p) == TYPE_DICTIONARY:
				pts.append({"kind": "portal", "x": int(p.get("x", -1)), "y": int(p.get("y", -1))})
		out[mid] = pts
	var f := FileAccess.open("/tmp/points.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("tulis /tmp/points.json")
	quit()
