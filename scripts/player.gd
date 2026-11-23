extends CharacterBody2D
## Karakter pemain (MC) memakai aset chibi 4 arah dari pratinjau yang diolah:
## assets/sprites/mc2/idle_<arah>.png dan walk_<arah>_00..11.png.
## Kanvas seragam 96x160, kaki di dasar; keempat arah digambar terpisah.

const SPEED := 190.0
const MC_DIR := "res://assets/sprites/mc2/"
const MC_DIRS := ["down", "up", "left", "right"]
const WALK_FRAMES := 12
const MC_SCALE := 0.84
## Tinggi kanvas (160) dipakai untuk menempelkan kaki sprite di y = 8.
const MC_HALF_H := 160.0

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
	# Kaki (dasar kanvas) ditempel di y = 8, sama seperti sprite lama.
	_sprite.position = Vector2(0, 8.0 - MC_HALF_H * MC_SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	z_index = 0

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for arah in MC_DIRS:
		var idle_name := "idle_%s" % arah
		sf.add_animation(idle_name)
		sf.set_animation_speed(idle_name, 3.0)
		sf.set_animation_loop(idle_name, true)
		sf.add_frame(idle_name, load("%sidle_%s.png" % [MC_DIR, arah]))

		var walk_name := "walk_%s" % arah
		sf.add_animation(walk_name)
		sf.set_animation_speed(walk_name, 12.0)
		sf.set_animation_loop(walk_name, true)
		for i in range(WALK_FRAMES):
			sf.add_frame(walk_name, load("%swalk_%s_%02d.png" % [MC_DIR, arah, i]))
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
