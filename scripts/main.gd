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
const SHOP_SCRIPT := preload("res://scripts/ui/shop_panel.gd")

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

var hud: Control
var dialog: Control
var puzzle: Control
var badge_popup: Control
var shop: Control
var title_screen: Control
var map_screen: Control
var research_screen: Control
var ending_screen: Control

var _pending_badge := ""
var _dialog_intent := ""   # "quest" | "info" | "gate" | "shop" | "object"
var _pending_object := ""

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

	map_screen.map_chosen.connect(_on_map_chosen)
	map_screen.back_pressed.connect(_on_map_back)

	research_screen.back_pressed.connect(_on_research_back)

	ending_screen.open_maps.connect(func(): _open_maps())
	ending_screen.open_research.connect(func(): _open_research())
	ending_screen.back_to_title.connect(_show_title)

	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 2
	add_child(_hud_layer)
	hud = HUD_SCRIPT.new()
	_hud_layer.add_child(hud)
	hud.open_map.connect(func(): _open_maps())
	hud.open_menu.connect(func(): _open_maps())

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
	puzzle.closed.connect(func(): pass)

	shop = SHOP_SCRIPT.new()
	_modal_layer.add_child(shop)

	badge_popup = BADGE_SCRIPT.new()
	_modal_layer.add_child(badge_popup)
	badge_popup.closed.connect(_on_badge_closed)

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
			Game.xp = 90
			_start_play("hutan")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m2 := Content.map_by_id("hutan")
			puzzle.open(m2["challenges"][1], 1, 3)
		"cipher":
			Game.xp = 260
			Game.badges = ["nature", "core"] as Array[String]
			_start_play("candi")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m3 := Content.map_by_id("candi")
			puzzle.open(m3["challenges"][1], 1, 3)
		"badge":
			Game.xp = 200
			_start_play("hutan")
			await get_tree().create_timer(0.3).timeout
			badge_popup.show_badge("nature", "Nature Data Crystal")
		"ending":
			Game.xp = 510
			Game.badges = ["nature", "core", "cipher", "aqua", "guardian"] as Array[String]
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
				_world.player._sprite.play("idle_down")
				_world.player.can_move = false
				_world.camera.position = Vector2(793, 240 - 80)
		"kanan":
			_start_play("kota")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			if _world and _world.player:
				_world.player.position = _world.tile_center(24, 10)
				_world.player._sprite.play("walk_right")
				_world.player._sprite.pause()
				_world.player._sprite.frame = 0
				_world.player.can_move = false
		"depan":
			_start_play("kota")
			await get_tree().create_timer(0.5).timeout
			dialog.visible = false
			if _world and _world.player:
				_world.player.position = _world.tile_center(24, 10)
				_world.player._sprite.play("idle_down")
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
			Game.xp = 150
			Game.badges = ["nature"] as Array[String]
			_start_play("pabrik")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var m4 := Content.map_by_id("pabrik")
			puzzle.open(m4["challenges"][1], 1, 3)
		"craft":
			Game.xp = 400
			Game.badges = ["nature", "core", "cipher"] as Array[String]
			Game.components = {"sensor": true, "mcu": true, "wifi": true}
			_start_play("danau")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var md := Content.map_by_id("danau")
			puzzle.open(md["challenges"][1], 1, 3)
		"boss":
			Game.xp = 500
			Game.badges = ["nature", "core", "cipher", "aqua"] as Array[String]
			_start_play("source")
			await get_tree().create_timer(0.4).timeout
			dialog.visible = false
			var ms := Content.map_by_id("source")
			puzzle.open(_with_boss(ms["challenges"][0], ms), 0, 3)
		"pilih":
			_show_ending_choice()
		"shop":
			Game.coins = 40
			_start_play("kota")
			await get_tree().create_timer(0.6).timeout
			shop.open()
		"rekam":
			await _demo_rekam()
		"tour":
			await _demo_tour()
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
		_:
			pass

# ------------------------------------------------------ demo rekaman (video)
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
	var guard := 0
	while _world.player.position.distance_to(target) > 30.0 and guard < 160:
		guard += 1
		var d: Vector2 = target - _world.player.position
		_release_move_keys()
		if abs(d.x) >= abs(d.y):
			Input.action_press("move_right" if d.x > 0.0 else "move_left")
		else:
			Input.action_press("move_down" if d.y > 0.0 else "move_up")
		await get_tree().physics_frame
	_release_move_keys()
	if pause:
		await get_tree().create_timer(0.25).timeout

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
	title_screen.visible = false
	map_screen.visible = false
	research_screen.visible = false
	ending_screen.visible = false
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
	if _world and is_instance_valid(_world):
		_world.queue_free()
	_world = WORLD_SCRIPT.new()
	_world_holder.add_child(_world)
	_world.build(id)
	_world.talk_to_npc.connect(_on_talk_npc)
	_world.inspect_object.connect(_on_inspect_object)
	_world.enter_portal.connect(_on_enter_portal)
	hud.set_map(Content.map_by_id(id))
	Game.set_prompt("")
	Game.save_game()

	await get_tree().process_frame
	var m := Content.map_by_id(id)
	if Game.is_map_cleared(id):
		_toast_msg("Wilayah selesai — cari gerbang bercahaya di tepi peta", 2.6)
	else:
		var target := _quest_npc_name(m)
		if target != "":
			_toast_msg("Temui %s — tanda ! di atas kepalanya" % target, 3.0)

func _quest_npc_name(m: Dictionary) -> String:
	for n in Content.npcs_of(m):
		if str(n.get("action", "quest")) == "quest":
			return str(n.get("name", ""))
	return ""

func _open_dialog(n: Dictionary, lines: Array, intent: String) -> void:
	_dialog_intent = intent
	dialog.open(str(n.get("name", "NPC")), str(n.get("role", "")), lines, str(n.get("sprite", "")))

func _on_talk_npc(npc_id: String) -> void:
	var m := Content.map_by_id(current_map)
	var n := Content.npc_by_id(m, npc_id)
	if n.is_empty():
		return
	var action := str(n.get("action", "quest"))
	if action == "shop":
		_open_dialog(n, n.get("dialog", []), "shop")
		return
	if action == "gate":
		_open_dialog(n, _gate_lines(), "gate")
		return
	if action == "info":
		_open_dialog(n, n.get("dialog", []), "info")
		return
	# pemberi tugas
	if Game.is_map_cleared(current_map):
		_open_dialog(n, [
			"Kau sudah menyelesaikan semua tantangan di wilayah ini.",
			"Gerbang menuju wilayah berikutnya sudah terbuka. Cari gerbang bercahaya di tepi peta."
		], "info")
	elif Game.map_done(current_map) > 0:
		_open_dialog(n, ["Kita lanjutkan. Tantangan berikutnya menunggumu."], "quest")
	else:
		_open_dialog(n, m["intro"], "quest")

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

## Setelah dialog objek: ambil komponen atau buka tantangan terkait.
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
	if o.has("gives"):
		Game.collect_component(str(o["gives"]))
		var left := 3 - Game.component_count()
		if left > 0:
			_toast_msg("Komponen didapat — %d lagi" % left, 2.2)
		else:
			_toast_msg("Semua komponen lengkap — kembali ke Inventor", 2.8)
		return
	if o.has("challenge"):
		_open_challenge(str(o["challenge"]))

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
			"Kau memenuhi syarat. Gerbang menuju %s sudah terbuka." % str(nm.get("name", "")),
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
	if intent == "quest" and not Game.is_map_cleared(current_map):
		_open_next_challenge()

func _open_next_challenge() -> void:
	var m := Content.map_by_id(current_map)
	var chs: Array = m["challenges"]
	var idx := -1
	for i in range(chs.size()):
		if not Game.done.has(chs[i]["id"]):
			idx = i
			break
	if idx < 0:
		return
	var ch: Dictionary = chs[idx]
	if str(ch.get("type", "")) == "craft" and not Game.all_components():
		_toast_msg("Cari dulu 3 komponen di sekitar danau", 2.6)
		return
	puzzle.open(_with_boss(ch, m), idx, chs.size())

func _on_puzzle_solved(challenge_id: String) -> void:
	var was_cleared := Game.is_map_cleared(current_map)
	Game.complete_challenge(challenge_id, current_map)
	_toast.text = "+%d XP" % Content.XP_PER_CHALLENGE
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 0.0, 1.2).set_delay(0.5)

	if Game.is_map_cleared(current_map) and not was_cleared:
		return  # badge popup akan muncul lewat signal
	await get_tree().create_timer(0.35).timeout
	if state == "playing" and not Game.is_map_cleared(current_map):
		var mm := Content.map_by_id(current_map)
		if mm.has("objects"):
			_toast_msg("Cari objek bertanda ? di sekitar peta", 2.4)
		else:
			_open_next_challenge()

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
	if Game.badges.size() >= 5:
		_show_ending_choice()

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
		_toast.text = "Gerbang terkunci — selesaikan semua tantangan wilayah ini"
		_toast.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_property(_toast, "modulate:a", 0.0, 1.8).set_delay(1.0)
		return
	var nxt := Game.next_map_id(current_map)
	if nxt == "":
		_show_ending()
		return
	if not Game.map_unlocked(nxt):
		_toast.text = "Butuh level dan badge sebelumnya untuk wilayah berikutnya"
		_toast.modulate.a = 1.0
		var tw2 := create_tween()
		tw2.tween_property(_toast, "modulate:a", 0.0, 1.8).set_delay(1.0)
		return
	_fade_in_then(func(): _load_map(nxt))

func _toast_msg(text: String, dur: float) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 0.0, dur).set_delay(0.6)

func _fade_in_then(cb: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.18)
	tw.tween_callback(cb)
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)

func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)

# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
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

	if event.is_action_pressed("ui_cancel"):
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
			_open_maps()


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
