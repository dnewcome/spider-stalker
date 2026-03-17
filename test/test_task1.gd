extends SceneTree
## Test harness: Task 1 — Visual Scene (Bedroom & Spider)
## Verifies: bedroom bg, bed, sleeping human, animated spider, HUD elements
## Run: godot --write-movie screenshots/task1/frame.png --fixed-fps 10 --quit-after 30 --script test/test_task1.gd

var _scene: Node = null
var _frame: int = 0

func _initialize() -> void:
	var scene_path = "res://scenes/main.tscn"
	var packed: PackedScene = load(scene_path)
	if packed == null:
		print("ASSERT FAIL: Could not load main.tscn")
		quit(1)
		return
	_scene = packed.instantiate()
	get_root().add_child(_scene)

	# Verify key nodes exist
	var bg = _scene.get_node_or_null("Background")
	print("ASSERT ", "PASS" if bg != null else "FAIL", ": Background node exists")

	var bed_area = _scene.get_node_or_null("BedArea")
	print("ASSERT ", "PASS" if bed_area != null else "FAIL", ": BedArea node exists")

	var spider = _scene.get_node_or_null("Spider")
	print("ASSERT ", "PASS" if spider != null else "FAIL", ": Spider node exists")

	if spider != null:
		var anim = spider.get_node_or_null("AnimatedSprite2D")
		print("ASSERT ", "PASS" if anim != null else "FAIL", ": Spider AnimatedSprite2D exists")

	var hud = _scene.get_node_or_null("HUD")
	print("ASSERT ", "PASS" if hud != null else "FAIL", ": HUD CanvasLayer exists")

	var score = _scene.get_node_or_null("HUD/HUDRoot/ScoreLabel")
	print("ASSERT ", "PASS" if score != null else "FAIL", ": ScoreLabel exists")

func _process(delta: float) -> bool:
	_frame += 1
	return false
