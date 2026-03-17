extends SceneTree
## Scene builder -- run: timeout 60 godot --headless --script scenes/build_spider.gd
## Produces: res://scenes/spider.tscn

func _initialize() -> void:
	print("Building: spider.tscn")

	var root = CharacterBody2D.new()
	root.name = "Spider"
	root.collision_layer = 1
	root.collision_mask = 0
	root.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	root.set_script(load("res://scripts/spider_controller.gd"))

	# AnimatedSprite2D with walk/idle animation from 4x4 spritesheet
	var anim = AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"

	# Build SpriteFrames from spider.png (992x992 total, 4x4 grid = 248x248 per frame)
	var frames = SpriteFrames.new()
	var spider_tex: Texture2D = load("res://assets/img/spider.png")

	# Remove default "default" animation
	frames.remove_animation("default")

	# Create "walk" animation using all 16 frames (248x248 each)
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 8.0)

	for row in range(4):
		for col in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = spider_tex
			atlas.region = Rect2(col * 248, row * 248, 248, 248)
			frames.add_frame("walk", atlas)

	anim.sprite_frames = frames
	anim.animation = &"walk"
	# Note: anim.playing must be set at runtime (in _ready()), not at build-time
	# Spider frame is 248x248 — scale down to ~120px tall for good visibility
	var spider_display_size: float = 120.0
	anim.scale = Vector2(spider_display_size / 248.0, spider_display_size / 248.0)
	root.add_child(anim)

	# Collision shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	col.shape = shape
	root.add_child(col)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/spider.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/spider.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
