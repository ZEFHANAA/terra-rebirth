extends CharacterBody2D
## Karakter pemain memakai spritesheet transparan 3x4 dari player_hero_v2_spritesheet.png.
## Baris: bawah, kiri, kanan, atas. Kolom: tiga frame gerak.

const SPEED := 190.0
const MC_SHEET := "res://assets/sprites/player_hero_v2_spritesheet.png"
const MC_SCALE := 3.0
const MC_FRAME_SIZE := Vector2(32, 32)

var can_move := true
var facing := "down"

var _sprite: AnimatedSprite2D

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, 16)
	shape.shape = rect
	shape.position = Vector2(0, 10)
	add_child(shape)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.animation = "idle_down"
	_sprite.scale = Vector2(MC_SCALE, MC_SCALE)
	# Pusatkan frame sehingga kaki berada dekat y = 8.
	_sprite.position = Vector2(0, 8.0 - MC_FRAME_SIZE.y * MC_SCALE * 0.5)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	z_index = 0

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var tex: Texture2D = load(MC_SHEET)
	var atlas_frames: Array[AtlasTexture] = []
	for row in range(4):
		for col in range(3):
			var frame := AtlasTexture.new()
			frame.atlas = tex
			frame.region = Rect2(col * MC_FRAME_SIZE.x, row * MC_FRAME_SIZE.y, MC_FRAME_SIZE.x, MC_FRAME_SIZE.y)
			atlas_frames.append(frame)
	var directions := {"down": 0, "left": 1, "right": 2, "up": 3}
	for arah in directions:
		var row: int = directions[arah]
		var idle_name := "idle_%s" % arah
		sf.add_animation(idle_name)
		sf.set_animation_speed(idle_name, 3.0)
		sf.set_animation_loop(idle_name, true)
		sf.add_frame(idle_name, atlas_frames[row * 3 + 1])

		var walk_name := "walk_%s" % arah
		sf.add_animation(walk_name)
		sf.set_animation_speed(walk_name, 7.0)
		sf.set_animation_loop(walk_name, true)
		for col in range(3):
			sf.add_frame(walk_name, atlas_frames[row * 3 + col])
	return sf

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_sprite.play("idle_%s" % facing)
		return

	var v := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		v.x -= 1
	if Input.is_action_pressed("move_right"):
		v.x += 1
	if Input.is_action_pressed("move_up"):
		v.y -= 1
	if Input.is_action_pressed("move_down"):
		v.y += 1

	if v.length() > 0:
		v = v.normalized()
		if abs(v.x) > abs(v.y):
			facing = "right" if v.x > 0 else "left"
		else:
			facing = "down" if v.y > 0 else "up"
		_sprite.play("walk_%s" % facing)
	else:
		_sprite.play("idle_%s" % facing)

	velocity = v * SPEED
	move_and_slide()
