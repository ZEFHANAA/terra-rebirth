extends CharacterBody2D
## Karakter pemain: gerak 4 arah + animasi jalan dari spritesheet 24x32.

const SPEED := 190.0
const DIRS := ["down", "up", "left", "right"]

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
	_sprite.sprite_frames = _build_frames("res://assets/sprites/hero.png")
	_sprite.animation = "idle_down"
	_sprite.position = Vector2(0, -56)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	z_index = 0

func _build_frames(path: String) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var tex: Texture2D = load(path)
	var fw := 96
	var fh := 144
	for row in range(DIRS.size()):
		var dir: String = DIRS[row]
		sf.add_animation("idle_" + dir)
		sf.set_animation_speed("idle_" + dir, 1.0)
		sf.set_animation_loop("idle_" + dir, true)
		var at0 := AtlasTexture.new()
		at0.atlas = tex
		at0.region = Rect2(0, row * fh, fw, fh)
		sf.add_frame("idle_" + dir, at0)

		sf.add_animation("walk_" + dir)
		sf.set_animation_speed("walk_" + dir, 9.0)
		sf.set_animation_loop("walk_" + dir, true)
		for col in [0, 1, 2, 3]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, row * fh, fw, fh)
			sf.add_frame("walk_" + dir, at)
	return sf

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
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
		_sprite.play("walk_" + facing)
	else:
		_sprite.play("idle_" + facing)

	velocity = v * SPEED
	move_and_slide()
