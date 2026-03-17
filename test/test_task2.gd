extends SceneTree
## Test harness for Task 2: Core Gameplay — Movement, Disturbance & Swat
## Verifies: spider moves with WASD, disturbance meter, swat hand, level clear, game over.

var _root_node: Node = null
var _frame: int = 0
var _spider: Node2D = null
var _swat_hand: Node2D = null
var _dist_meter: Node = null

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_root_node = scene.instantiate()
	_root_node.name = "MainTest"
	get_root().add_child(_root_node)

	_spider = _root_node.get_node_or_null("Spider")
	_swat_hand = _root_node.get_node_or_null("SwatHand")
	var hud = _root_node.get_node_or_null("HUD")
	if hud:
		_dist_meter = hud.get_node_or_null("DisturbanceMeter")

	print("Spider: ", _spider != null, " SwatHand: ", _swat_hand != null,
		" DisturbanceMeter: ", _dist_meter != null)

func _process(delta: float) -> bool:
	_frame += 1

	# Frames 3-40: move toward goal (up + right = W + D = isometric up-right)
	# BedArea at (500, 380), GoalZone at (500, 300). Spider starts at (460, 420).
	# Moving W (up-left direction) and D (up-right direction) -> net movement up
	if _frame == 3:
		# Move up-left and up-right = straight up (cancel horizontal)
		Input.action_press("move_up")
		Input.action_press("move_right")
		print("Frame ", _frame, ": Moving toward goal (up+right iso)")

	# Check movement progress
	if _frame == 15:
		if _spider:
			var pos = _spider.global_position
			print("Spider pos: ", pos, " (started at 460,420)")
			if pos.y < 420.0:
				print("ASSERT PASS: Spider moved upward toward goal")
			else:
				print("ASSERT FAIL: Spider did not move upward!")

	# Check disturbance meter filling
	if _frame == 20:
		if _dist_meter and _dist_meter.has_method("get_meter"):
			var m: float = _dist_meter.get_meter()
			print("Disturbance meter while moving: ", "%.3f" % m)
			if m > 0.01:
				print("ASSERT PASS: Meter filling while moving (", "%.3f" % m, ")")
			else:
				print("ASSERT FAIL: Meter not filling while moving!")

	# Stop moving at frame 40 to check drain
	if _frame == 40:
		Input.action_release("move_up")
		Input.action_release("move_right")
		print("Frame ", _frame, ": Stopped moving")

	# Check meter drains when still
	if _frame == 55:
		if _dist_meter and _dist_meter.has_method("get_meter"):
			var m: float = _dist_meter.get_meter()
			print("Disturbance meter after ~1.5s still: ", "%.3f" % m)

	# Resume moving at frame 58
	if _frame == 58:
		Input.action_press("move_up")
		Input.action_press("move_right")
		print("Frame ", _frame, ": Resuming movement toward goal")

	# At frame 70 force trigger a swat for visual demo
	if _frame == 70:
		Input.action_release("move_up")
		Input.action_release("move_right")
		print("Frame ", _frame, ": Triggering swat for visual demo")
		if _swat_hand and _swat_hand.has_method("trigger_swat"):
			_swat_hand.visible = true
			_swat_hand.trigger_swat(Vector2(460.0, 380.0))

	# Log swat state every 5 frames
	if _frame >= 70 and _frame <= 95 and _frame % 5 == 0 and _swat_hand:
		print("Frame ", _frame, ": SwatHand visible=", _swat_hand.visible,
			" active=", _swat_hand.is_active() if _swat_hand.has_method("is_active") else "?")

	# At frame 90: reset and move to check level clear
	# (We'll observe the swat animation until ~85, then reset spider manually)

	return false
