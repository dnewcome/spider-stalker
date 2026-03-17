extends Node2D
## res://scripts/game_manager.gd
## Attached to Main (Node2D root). Orchestrates all gameplay.

signal game_over
signal level_cleared
signal swat_triggered(pos: Vector2)

@export var swat_interval_normal_min: float = 4.0
@export var swat_interval_normal_max: float = 8.0
@export var swat_interval_agitated_min: float = 2.0
@export var swat_interval_agitated_max: float = 3.0

var score: int = 0
var _is_alive: bool = false
var _game_started: bool = false
var _swat_timer: float = 0.0
var _next_swat_time: float = 6.0
var _meter_high: bool = false
var _game_over_shown: bool = false
var _level_clear_timer: float = 0.0
var _level_clear_showing: bool = false

# Node refs (resolved in _ready)
var _spider: Node2D = null
var _swat_hand: Node2D = null
var _disturbance_meter: Node = null
var _score_label: Label = null
var _overlay: CanvasLayer = null
var _overlay_label: Label = null
var _face_zone: Area2D = null
var _hands_zone: Area2D = null
var _goal_zone: Area2D = null

func _ready() -> void:
	# Resolve child nodes
	_spider = get_node_or_null("Spider")
	_swat_hand = get_node_or_null("SwatHand")

	var hud = get_node_or_null("HUD")
	if hud:
		_disturbance_meter = hud.get_node_or_null("DisturbanceMeter")
		var hud_root = hud.get_node_or_null("HUDRoot")
		if hud_root:
			_score_label = hud_root.get_node_or_null("ScoreLabel")

	var bed_area = get_node_or_null("BedArea")
	if bed_area:
		_face_zone = bed_area.get_node_or_null("FaceZone")
		_hands_zone = bed_area.get_node_or_null("HandsZone")
		_goal_zone = bed_area.get_node_or_null("GoalZone")

	# Set up collision masks for spider detection on zones
	if _face_zone:
		_face_zone.collision_mask = 1   # detect spider (layer 1)
		_face_zone.monitoring = true
		_face_zone.body_entered.connect(_on_sensitive_entered)
		_face_zone.body_exited.connect(_on_sensitive_exited)

	if _hands_zone:
		_hands_zone.collision_mask = 1
		_hands_zone.monitoring = true
		_hands_zone.body_entered.connect(_on_sensitive_entered)
		_hands_zone.body_exited.connect(_on_sensitive_exited)

	if _goal_zone:
		_goal_zone.collision_mask = 1
		_goal_zone.monitoring = true
		_goal_zone.body_entered.connect(_on_goal_reached)

	# Connect spider signals
	if _spider and _spider.has_signal("moved"):
		_spider.moved.connect(_on_spider_moved)
	if _spider and _spider.has_signal("died"):
		_spider.died.connect(_on_spider_died)

	# Connect disturbance meter signals
	if _disturbance_meter:
		_disturbance_meter.meter_full.connect(_on_meter_full)
		_disturbance_meter.meter_high.connect(_on_meter_high)

	# Connect swat hand squished signal
	if _swat_hand and _swat_hand.has_signal("squished"):
		_swat_hand.squished.connect(_on_squished)
		# Give swat_hand reference to spider
		if _swat_hand.has_method("set_spider") and _spider:
			_swat_hand.set_spider(_spider)

	# Create overlay CanvasLayer for game over / level clear messages
	_create_overlay()

	# Start game
	_start_game()

func _create_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "Overlay"
	_overlay.layer = 20
	add_child(_overlay)

	_overlay_label = Label.new()
	_overlay_label.name = "OverlayLabel"
	_overlay_label.text = ""
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	_overlay_label.offset_left = -320.0
	_overlay_label.offset_right = 320.0
	_overlay_label.offset_top = -100.0
	_overlay_label.offset_bottom = 100.0
	_overlay_label.add_theme_font_size_override("font_size", 48)
	_overlay_label.visible = false
	_overlay.add_child(_overlay_label)

	# Game over panel background
	var go_bg = ColorRect.new()
	go_bg.name = "OverlayBG"
	go_bg.color = Color(0.0, 0.0, 0.0, 0.6)
	go_bg.set_anchors_preset(Control.PRESET_CENTER)
	go_bg.offset_left = -340.0
	go_bg.offset_right = 340.0
	go_bg.offset_top = -120.0
	go_bg.offset_bottom = 120.0
	go_bg.visible = false
	_overlay.add_child(go_bg)

	# Move bg behind label
	_overlay.move_child(go_bg, 0)

func _start_game() -> void:
	_is_alive = true
	_game_started = true
	_game_over_shown = false
	_swat_timer = 0.0
	_next_swat_time = randf_range(swat_interval_normal_min, swat_interval_normal_max)
	_meter_high = false
	_level_clear_showing = false
	score = 0
	_update_score_label()
	_hide_overlay()
	if _disturbance_meter:
		_disturbance_meter.reset()
		_disturbance_meter.set_enabled(true)
	if _spider:
		_spider.reset_to_start()
	if _swat_hand:
		_swat_hand.visible = false

func _process(delta: float) -> void:
	if not _game_started or not _is_alive:
		# Listen for restart
		if _game_over_shown and Input.is_action_just_pressed("restart"):
			_start_game()
		return

	# Level clear flash countdown
	if _level_clear_showing:
		_level_clear_timer -= delta
		if _level_clear_timer <= 0.0:
			_level_clear_showing = false
			_hide_overlay()

	# Swat timer
	_swat_timer += delta
	if _swat_timer >= _next_swat_time:
		_swat_timer = 0.0
		_trigger_swat()
		# Schedule next swat
		if _meter_high:
			_next_swat_time = randf_range(swat_interval_agitated_min, swat_interval_agitated_max)
		else:
			_next_swat_time = randf_range(swat_interval_normal_min, swat_interval_normal_max)

func _trigger_swat() -> void:
	if _swat_hand == null or not _is_alive:
		return
	if _swat_hand.is_active():
		return  # already in progress

	# Pick random position near spider on bed
	var spider_pos = Vector2(460.0, 420.0)
	if _spider:
		spider_pos = _spider.global_position

	# Random position: mix of near-spider and random bed position
	var rand_offset = Vector2(
		randf_range(-120.0, 120.0),
		randf_range(-80.0, 80.0)
	)
	var target = spider_pos + rand_offset
	# Clamp to bed region
	target.x = clamp(target.x, 220.0, 660.0)
	target.y = clamp(target.y, 290.0, 510.0)

	swat_triggered.emit(target)
	_swat_hand.trigger_swat(target)

func _on_spider_moved(speed: float) -> void:
	if _disturbance_meter and _disturbance_meter.has_method("_on_spider_moved"):
		_disturbance_meter._on_spider_moved(speed)

func _on_spider_died() -> void:
	_show_game_over("SQUISHED!\nScore: " + str(score) + "\n\nPress R to restart")

func _on_goal_reached(_body) -> void:
	if not _is_alive or _game_over_shown:
		return
	score += 1
	_update_score_label()
	_show_level_clear()
	# Reset spider and meter
	if _spider:
		_spider.reset_to_start()
	if _disturbance_meter:
		_disturbance_meter.reset()
	_meter_high = false
	_next_swat_time = randf_range(swat_interval_normal_min, swat_interval_normal_max)
	_swat_timer = 0.0
	level_cleared.emit()

func _on_squished() -> void:
	if not _is_alive or _game_over_shown:
		return
	_is_alive = false
	if _spider:
		_spider.die()
	_show_game_over("SQUISHED!\nScore: " + str(score) + "\n\nPress R to restart")
	game_over.emit()

func _on_meter_full() -> void:
	if not _is_alive or _game_over_shown:
		return
	_is_alive = false
	if _spider:
		_spider.set_game_over(true)
	_show_game_over("HUMAN WOKE UP!\nScore: " + str(score) + "\n\nPress R to restart")
	game_over.emit()

func _on_meter_high(_threshold: float) -> void:
	_meter_high = true
	# Swat interval will update on next swat trigger

func _on_sensitive_entered(body: Node) -> void:
	if body == _spider and _disturbance_meter:
		_disturbance_meter.set_sensitive(true)

func _on_sensitive_exited(body: Node) -> void:
	if body == _spider and _disturbance_meter:
		# Only clear if not in any sensitive zone
		# Simple: clear when exiting (if both zones, this may flicker, acceptable)
		_disturbance_meter.set_sensitive(false)

func _show_game_over(msg: String) -> void:
	_game_over_shown = true
	_is_alive = false
	if _disturbance_meter:
		_disturbance_meter.set_enabled(false)
	_show_overlay(msg)

func _show_level_clear() -> void:
	_level_clear_showing = true
	_level_clear_timer = 2.0
	_show_overlay("Level Clear! +" + str(score))

func _show_overlay(msg: String) -> void:
	if _overlay_label:
		_overlay_label.text = msg
		_overlay_label.visible = true
	var bg = _overlay.get_node_or_null("OverlayBG")
	if bg:
		bg.visible = true

func _hide_overlay() -> void:
	if _overlay_label:
		_overlay_label.visible = false
	var bg = _overlay.get_node_or_null("OverlayBG") if _overlay else null
	if bg:
		bg.visible = false

func _update_score_label() -> void:
	if _score_label:
		_score_label.text = "Score: " + str(score)

func restart() -> void:
	_start_game()
