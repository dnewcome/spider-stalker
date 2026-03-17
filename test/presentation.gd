extends SceneTree
## Presentation script for Spider Stalker
## ~900 frames at 30fps = ~30 seconds

const MAIN_SCENE = "res://scenes/main.tscn"

var _frame: int = 0
var _main: Node2D = null
var _spider: CharacterBody2D = null
var _swat_hand: Node2D = null
var _disturbance_meter: Node = null

# Script phases
enum Phase {
	INIT,
	IDLE,
	MOVE_RIGHT,
	DODGE_UP,
	APPROACH_GOAL,
	LEVEL_CLEAR_WAIT,
	SECOND_RUN,
	DONE
}

var _phase: Phase = Phase.INIT
var _phase_timer: float = 0.0
var _swat_triggered: bool = false
var _goal_triggered: bool = false

func _initialize() -> void:
	# Load main scene
	var packed = load(MAIN_SCENE)
	if packed == null:
		push_error("Could not load main scene")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)
	print("Presentation: scene added, waiting for ready")


func _process(delta: float) -> bool:
	_frame += 1
	_phase_timer += delta

	# INIT phase: wait one frame for _ready() calls to complete
	if _phase == Phase.INIT:
		if _frame >= 2:
			_setup_refs()
			_phase = Phase.IDLE
			_phase_timer = 0.0
		return false

	match _phase:
		Phase.IDLE:
			# 5 seconds: spider idle on bed, show bedroom
			if _spider:
				# Keep spider still at start position
				_spider.velocity = Vector2.ZERO
				_notify_meter(0.0)

			if _phase_timer >= 5.0:
				_transition(Phase.MOVE_RIGHT)

		Phase.MOVE_RIGHT:
			# 10 seconds: spider moves right across bed, meter fills
			if _spider:
				var target = Vector2(640.0, 420.0)
				var dir = (target - _spider.position)
				if dir.length() > 5.0:
					_spider.velocity = dir.normalized() * 120.0
				else:
					_spider.velocity = Vector2.ZERO

				_spider.position += _spider.velocity * delta
				_clamp_spider()
				_notify_meter(_spider.velocity.length())

			# At 7s trigger swat telegraph
			if _phase_timer >= 7.0 and not _swat_triggered:
				_swat_triggered = true
				if _swat_hand and not _swat_hand.is_active():
					# Trigger at spider position so shadow is visible
					var sp = _spider.position if _spider else Vector2(600.0, 420.0)
					_swat_hand.trigger_swat(sp + Vector2(50.0, 10.0))
				print("Presentation: swat triggered")

			if _phase_timer >= 10.0:
				_transition(Phase.DODGE_UP)

		Phase.DODGE_UP:
			# 3 seconds: spider dodges left away from swat
			if _spider:
				var target = Vector2(340.0, 400.0)
				var dir = (target - _spider.position)
				if dir.length() > 5.0:
					_spider.velocity = dir.normalized() * 140.0
				else:
					_spider.velocity = Vector2.ZERO

				_spider.position += _spider.velocity * delta
				_clamp_spider()
				_notify_meter(_spider.velocity.length())

			if _phase_timer >= 3.0:
				_transition(Phase.APPROACH_GOAL)

		Phase.APPROACH_GOAL:
			# 5 seconds: spider moves toward goal zone (500, 300)
			if _spider:
				var goal_world = Vector2(500.0, 300.0)
				var dir = (goal_world - _spider.position)
				if dir.length() > 10.0:
					_spider.velocity = dir.normalized() * 100.0
				else:
					_spider.velocity = Vector2.ZERO
					if not _goal_triggered and _phase_timer >= 1.0:
						_goal_triggered = true
						_trigger_level_clear()

				_spider.position += _spider.velocity * delta
				_clamp_spider()
				_notify_meter(_spider.velocity.length())

			# Safety: after 4s force level clear
			if _phase_timer >= 4.0 and not _goal_triggered:
				_goal_triggered = true
				_trigger_level_clear()

			if _phase_timer >= 5.0:
				_transition(Phase.LEVEL_CLEAR_WAIT)

		Phase.LEVEL_CLEAR_WAIT:
			# 3 seconds: show level clear overlay
			if _spider:
				_spider.velocity = Vector2.ZERO
				_notify_meter(0.0)

			if _phase_timer >= 3.0:
				_transition(Phase.SECOND_RUN)

		Phase.SECOND_RUN:
			# 7 seconds: spider moves frantically, meter fills to danger
			if _spider:
				var t = _phase_timer
				# Oscillate across bed
				var target_x: float = 440.0 + sin(t * 1.8) * 160.0
				var target_y: float = 390.0 + cos(t * 1.2) * 80.0
				target_x = clamp(target_x, 240.0, 640.0)
				target_y = clamp(target_y, 300.0, 490.0)
				var target = Vector2(target_x, target_y)
				var dir = (target - _spider.position).normalized()
				_spider.velocity = dir * 120.0
				_spider.position += _spider.velocity * delta
				_clamp_spider()

				# Boost meter fill for dramatic effect
				if _disturbance_meter:
					_disturbance_meter.set("fill_rate_base", 0.25)
					_disturbance_meter._on_spider_moved(120.0)

			if _phase_timer >= 7.0:
				_transition(Phase.DONE)

		Phase.DONE:
			if _phase_timer >= 1.0:
				print("Presentation: complete at frame ", _frame)
				quit(0)

	return false


func _setup_refs() -> void:
	_spider = _main.get_node_or_null("Spider") as CharacterBody2D
	_swat_hand = _main.get_node_or_null("SwatHand")
	var hud = _main.get_node_or_null("HUD")
	if hud:
		_disturbance_meter = hud.get_node_or_null("DisturbanceMeter")

	# Override swat intervals so auto-swat doesn't fire during scripted sequence
	_main.set("swat_interval_normal_min", 999.0)
	_main.set("swat_interval_normal_max", 999.0)
	_main.set("swat_interval_agitated_min", 999.0)
	_main.set("swat_interval_agitated_max", 999.0)
	_main.set("_swat_timer", 0.0)
	_main.set("_next_swat_time", 999.0)

	print("Presentation: refs setup. spider=", _spider != null,
		" swat=", _swat_hand != null, " meter=", _disturbance_meter != null)


func _notify_meter(speed: float) -> void:
	if _disturbance_meter:
		_disturbance_meter._on_spider_moved(speed)


func _clamp_spider() -> void:
	if _spider:
		_spider.position.x = clamp(_spider.position.x, 200.0, 680.0)
		_spider.position.y = clamp(_spider.position.y, 280.0, 520.0)


func _trigger_level_clear() -> void:
	print("Presentation: triggering level clear")
	if _main and _main.has_method("_on_goal_reached"):
		_main.call("_on_goal_reached", _spider)


func _transition(new_phase: Phase) -> void:
	print("Presentation: -> ", Phase.keys()[new_phase], " at frame ", _frame)
	_phase = new_phase
	_phase_timer = 0.0
