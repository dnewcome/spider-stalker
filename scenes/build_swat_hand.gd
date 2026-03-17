extends SceneTree
## Scene builder -- run: timeout 60 godot --headless --script scenes/build_swat_hand.gd

func _initialize() -> void:
	var root = Node2D.new()
	root.name = "SwatHand"
	root.set_script(load("res://scripts/swat_hand.gd"))

	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	root.add_child(shadow)

	var hand = AnimatedSprite2D.new()
	hand.name = "Hand"
	root.add_child(hand)

	var hit_zone = Area2D.new()
	hit_zone.name = "HitZone"
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 60.0
	col.shape = shape
	hit_zone.add_child(col)
	root.add_child(hit_zone)

	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/swat_hand.tscn")
	print("Saved: res://scenes/swat_hand.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
