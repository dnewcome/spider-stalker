extends Node2D
## res://scripts/swat_hand.gd
## Controls the swat hand animation: telegraph shadow -> slam -> squish check.
## The hand.png is ~630x380px: left 315px = raised pose, right 315px = slammed pose.

signal squished

@export var telegraph_duration: float = 1.5

# Child node refs
@onready var shadow: Sprite2D = $Shadow
@onready var hand_anim: AnimatedSprite2D = $Hand
@onready var hit_zone: Area2D = $HitZone

var _active: bool = false
var _phase: String = "idle"   # idle / telegraph / slam / done
var _timer: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _slam_pos: Vector2 = Vector2.ZERO

# Reference to spider (set by game_manager)
var _spider: Node2D = null

func _ready() -> void:
	visible = false
	_active = false

	# Build the hand sprite frames from hand.png (1264x848 => two 632x848 halves)
	var hand_tex: Texture2D = load("res://assets/img/hand.png")
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("raised")
	frames.set_animation_loop("raised", false)
	frames.set_animation_speed("raised", 1.0)
	var raised_atlas = AtlasTexture.new()
	raised_atlas.atlas = hand_tex
	raised_atlas.region = Rect2(0, 0, 632, 848)
	frames.add_frame("raised", raised_atlas)

	frames.add_animation("slammed")
	frames.set_animation_loop("slammed", false)
	frames.set_animation_speed("slammed", 1.0)
	var slam_atlas = AtlasTexture.new()
	slam_atlas.atlas = hand_tex
	slam_atlas.region = Rect2(632, 0, 632, 848)
	frames.add_frame("slammed", slam_atlas)

	hand_anim.sprite_frames = frames
	# Scale: 632x848 -> display at ~180x240px
	hand_anim.scale = Vector2(0.28, 0.28)

	# Shadow: yellow-green glow circle drawn procedurally
	# We'll use a ColorRect with circular modulation — actually draw via code
	# Shadow is a simple Sprite2D — use a colored circle texture drawn at runtime
	# Use _draw() on a Node2D child, or just set shadow modulate + scale in trigger_swat
	if shadow:
		shadow.visible = false

func _process(delta: float) -> void:
	if not _active:
		return

	_timer += delta

	match _phase:
		"telegraph":
			# Shadow pulses, hand hovers above target (offscreen-ish above)
			var progress: float = clamp(_timer / telegraph_duration, 0.0, 1.0)
			# Pulse shadow alpha
			if shadow:
				var pulse: float = 0.5 + 0.5 * sin(_timer * 8.0)
				shadow.modulate = Color(1.0, 1.0, 0.0, 0.7 + pulse * 0.3)

			# Animate hand descending slowly from above
			if hand_anim:
				var start_y: float = _target_pos.y - 250.0
				var end_y: float = _target_pos.y - 80.0
				hand_anim.position.y = lerp(start_y, end_y, progress)

			# After telegraph, slam!
			if _timer >= telegraph_duration:
				_do_slam()

		"slam":
			# Hold slam pose briefly, check hit, then disappear
			if _timer >= 0.3:
				_finish_swat()

func trigger_swat(pos: Vector2) -> void:
	_target_pos = pos
	_slam_pos = pos
	_phase = "telegraph"
	_timer = 0.0
	_active = true
	visible = true
	position = Vector2.ZERO  # Root stays at origin; children positioned

	# Position shadow at target
	if shadow:
		shadow.position = _target_pos
		shadow.visible = true
		# Draw a circle: use a generated image as texture
		var img = Image.create(240, 240, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		# Draw filled circle
		var center = Vector2(120, 120)
		for y in range(240):
			for x in range(240):
				var d: float = Vector2(x, y).distance_to(center)
				if d < 115.0:
					var alpha: float = clamp(1.0 - d / 115.0, 0.0, 1.0) * 0.6
					img.set_pixel(x, y, Color(1.0, 0.9, 0.0, alpha))
		var img_tex = ImageTexture.create_from_image(img)
		shadow.texture = img_tex
		shadow.modulate = Color(1.0, 1.0, 0.0, 0.8)

	# Position hand above target
	if hand_anim:
		hand_anim.position = Vector2(_target_pos.x, _target_pos.y - 250.0)
		hand_anim.play("raised")
		hand_anim.visible = true

	# Reset hit zone
	if hit_zone:
		hit_zone.position = _target_pos

func _do_slam() -> void:
	_phase = "slam"
	_timer = 0.0

	# Move hand to slam position
	if hand_anim:
		hand_anim.position = _target_pos
		hand_anim.play("slammed")

	# Screen shake feel: hide shadow, show impact
	if shadow:
		shadow.modulate = Color(1.0, 0.3, 0.0, 1.0)

	# Check if spider is in the hit zone
	_check_squish()

func _check_squish() -> void:
	if _spider == null:
		return
	var dist: float = _spider.global_position.distance_to(_target_pos)
	if dist < 110.0:
		squished.emit()

func _finish_swat() -> void:
	_phase = "idle"
	_active = false
	visible = false
	if shadow:
		shadow.visible = false
	if hand_anim:
		hand_anim.visible = false

func set_spider(spider: Node2D) -> void:
	_spider = spider

func is_active() -> bool:
	return _active
