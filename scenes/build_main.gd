extends SceneTree
## Scene builder -- run: timeout 60 godot --headless --script scenes/build_main.gd
## Produces: res://scenes/main.tscn
## NOTE: bedroom_bg.png already includes bed and sleeping person.
## Use it as full backdrop. Bed zones are defined in code over the bed region.

func _initialize() -> void:
	print("Building: main.tscn")

	# Root node
	var root = Node2D.new()
	root.name = "Main"
	root.set_script(load("res://scripts/game_manager.gd"))

	# --- BACKGROUND ---
	# bedroom_bg.png is 2752x1536; viewport is 1280x720
	var bg = Sprite2D.new()
	bg.name = "Background"
	var bg_tex: Texture2D = load("res://assets/img/bedroom_bg.png")
	bg.texture = bg_tex
	# Center of viewport
	bg.position = Vector2(640, 360)
	# Scale non-uniformly to fill exactly 1280x720 (slight vertical stretch, minimal)
	# 1280/2752 = 0.4651 horizontal, 720/1536 = 0.4688 vertical — very close, no visible distortion
	bg.scale = Vector2(1280.0 / 2752.0, 720.0 / 1536.0)
	bg.z_index = -10
	root.add_child(bg)

	# --- BED AREA ---
	# bedroom_bg already has the bed in center-left area.
	# Bed region in source image: roughly x=600-1600, y=400-1100 (in 2752x1536 image)
	# In viewport space (scale=0.4651): x=279-744, y=186-512
	# Center of bed region in viewport: x~511, y~349
	# For gameplay we position zones over the bed
	var bed_area = Node2D.new()
	bed_area.name = "BedArea"
	bed_area.y_sort_enabled = true
	# Position at approximate bed center in 1280x720 viewport
	bed_area.position = Vector2(500, 380)
	root.add_child(bed_area)

	# Invisible BedSprite node (no texture — bg has the visual)
	# Still needed for STRUCTURE.md compliance
	var bed_sprite = Node2D.new()
	bed_sprite.name = "BedSprite"
	bed_area.add_child(bed_sprite)

	# Face zone (sensitive) — pillow area top of bed
	var face_zone = Area2D.new()
	face_zone.name = "FaceZone"
	face_zone.collision_layer = 2
	face_zone.collision_mask = 0
	var face_col = CollisionShape2D.new()
	var face_shape = RectangleShape2D.new()
	face_shape.size = Vector2(150, 80)
	face_col.shape = face_shape
	face_zone.add_child(face_col)
	face_zone.position = Vector2(0, -130)
	bed_area.add_child(face_zone)

	# Hands zone (sensitive) — sides of bed
	var hands_zone = Area2D.new()
	hands_zone.name = "HandsZone"
	hands_zone.collision_layer = 2
	hands_zone.collision_mask = 0
	var hands_col = CollisionShape2D.new()
	var hands_shape = RectangleShape2D.new()
	hands_shape.size = Vector2(300, 60)
	hands_col.shape = hands_shape
	hands_zone.add_child(hands_col)
	hands_zone.position = Vector2(0, -50)
	bed_area.add_child(hands_zone)

	# Goal zone — far edge of bed (top of isometric bed, reachable from start)
	# BedArea is at y=380; goal zone at y=-80 = world y=300, within bed bounds (y=280-520)
	var goal_zone = Area2D.new()
	goal_zone.name = "GoalZone"
	goal_zone.collision_layer = 2
	goal_zone.collision_mask = 0
	var goal_col = CollisionShape2D.new()
	var goal_shape = RectangleShape2D.new()
	goal_shape.size = Vector2(400, 40)
	goal_col.shape = goal_shape
	goal_zone.add_child(goal_col)
	goal_zone.position = Vector2(0, -80)
	bed_area.add_child(goal_zone)

	# --- SPIDER (instanced) ---
	var spider_scene: PackedScene = load("res://scenes/spider.tscn")
	var spider = spider_scene.instantiate()
	spider.name = "Spider"
	# On the bed — center of bed in viewport (bed is roughly x=350-670, y=280-500)
	spider.position = Vector2(460, 420)
	root.add_child(spider)

	# --- SWAT HAND (instanced, hidden initially) ---
	var swat_scene: PackedScene = load("res://scenes/swat_hand.tscn")
	var swat = swat_scene.instantiate()
	swat.name = "SwatHand"
	swat.position = Vector2(490, 300)
	swat.visible = false
	root.add_child(swat)

	# --- HUD via CanvasLayer ---
	var canvas = CanvasLayer.new()
	canvas.name = "HUD"
	canvas.layer = 10
	root.add_child(canvas)

	var hud_root = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud_root)

	# Disturbance meter container (top-left)
	var meter_panel = PanelContainer.new()
	meter_panel.name = "MeterPanel"
	meter_panel.position = Vector2(10, 10)
	meter_panel.custom_minimum_size = Vector2(220, 55)
	hud_root.add_child(meter_panel)

	var meter_vbox = VBoxContainer.new()
	meter_vbox.name = "MeterVBox"
	meter_panel.add_child(meter_vbox)

	var zzz_label = Label.new()
	zzz_label.name = "ZZZLabel"
	zzz_label.text = "ZZZ Disturbance"
	meter_vbox.add_child(zzz_label)

	var meter_bar = ProgressBar.new()
	meter_bar.name = "MeterBar"
	meter_bar.max_value = 100
	meter_bar.value = 15
	meter_bar.custom_minimum_size = Vector2(200, 20)
	meter_vbox.add_child(meter_bar)

	# Disturbance meter script node (logic)
	var meter_node = Node.new()
	meter_node.name = "DisturbanceMeter"
	meter_node.set_script(load("res://scripts/disturbance_meter.gd"))
	canvas.add_child(meter_node)

	# Score label (top-right)
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_label.offset_left = -120
	score_label.offset_top = 10
	score_label.offset_right = -10
	score_label.offset_bottom = 40
	hud_root.add_child(score_label)

	# --- OWNERSHIP ---
	_set_owners(root, root)

	# --- SAVE ---
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/main.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
