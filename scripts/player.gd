extends CharacterBody2D
## Karakter pemain (MC) memakai aset Idle & Run dari kelompok:
## assets/sprites/mc/idle_00..09.png dan run_00..09.png (kanvas 512x512, kaki di dasar).
## Sprite menghadap samping, jadi arah atas/bawah tetap memakai hadap terakhir (flip_h).

const SPEED := 190.0
const MC_DIR := "res://assets/sprites/mc/"
const IDLE_COUNT := 10
const RUN_COUNT := 10
## 512 px kanvas -> tinggi karakter tampil ~131 px (dulu 144 px), jadi 0.27.
const MC_SCALE := 0.27
const MC_HALF := 256.0

var can_move := true
var facing := "down"

var _sprite: AnimatedSprite2D
var _hadap := 1.0  ## 1 = menghadap kanan, -1 = kiri

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, 16)
	shape.shape = rect
	shape.position = Vector2(0, 10)
	add_child(shape)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.animation = "idle"
	_sprite.scale = Vector2(MC_SCALE, MC_SCALE)
	# Kaki (dasar kanvas) ditempel di y = 8, sama seperti sprite lama.
	_sprite.position = Vector2(0, 8.0 - MC_HALF * MC_SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	z_index = 0

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	sf.add_animation("idle")
	sf.set_animation_speed("idle", 6.0)
	sf.set_animation_loop("idle", true)
	for i in range(IDLE_COUNT):
		sf.add_frame("idle", load("%sidle_%02d.png" % [MC_DIR, i]))

	sf.add_animation("run")
	sf.set_animation_speed("run", 14.0)
	sf.set_animation_loop("run", true)
	for i in range(RUN_COUNT):
		sf.add_frame("run", load("%srun_%02d.png" % [MC_DIR, i]))
	return sf

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_sprite.play("idle")
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
		if absf(v.x) > 0.01:
			_hadap = signf(v.x)
		_sprite.play("run")
	else:
		_sprite.play("idle")

	_sprite.flip_h = _hadap < 0.0
	velocity = v * SPEED
	move_and_slide()
