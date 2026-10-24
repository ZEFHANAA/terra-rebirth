extends SceneTree
## Render SATU peta utuh (seluruh tile, tanpa kamera/HUD) ke berkas PNG.
## Pakai:
##   DISPLAY=:99 TERRA_MAP=kota TERRA_SHOT=/tmp/kota_full.png \
##     godot --path . --script res://tools/fullmap.gd
##
## Ukuran gambar = jumlah tile x ukuran tile (mis. 40x22 tile x 48 px = 1920x1056),
## jadi seluruh peta terlihat tanpa perlu digeser.

func _initialize() -> void:
	_render.call_deferred()

func _render() -> void:
	var mid := OS.get_environment("TERRA_MAP")
	if mid == "":
		mid = "kota"
	var out := OS.get_environment("TERRA_SHOT")
	if out == "":
		out = "/tmp/fullmap_%s.png" % mid

	var path := "res://assets/maps/%s.json" % mid
	if not FileAccess.file_exists(path):
		print("peta tidak ditemukan: ", path)
		quit(1)
		return
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var solid: Array = meta.get("solid", [])
	var t := int(meta.get("tile", 48))
	var cols := (solid[0] as Array).size()
	var rows := solid.size()

	# SubViewport seukuran peta: tanpa kamera, gambar digambar dari (0,0).
	var vp := SubViewport.new()
	vp.size = Vector2i(cols * t, rows * t)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	root.add_child(vp)

	var world: Node2D = load("res://scripts/world.gd").new()
	vp.add_child(world)
	world.build(mid)
	# Kamera dimatikan supaya seluruh peta tampak sekaligus.
	if world.camera != null:
		world.camera.enabled = false

	# Beri waktu tekstur & font siap sebelum ditangkap.
	for i in range(8):
		await process_frame

	var img := vp.get_texture().get_image()
	var err := img.save_png(out)
	if err != OK:
		print("gagal menyimpan: ", err)
		quit(1)
		return
	print("peta %s -> %s (%dx%d)" % [mid, out, img.get_width(), img.get_height()])
	quit()
