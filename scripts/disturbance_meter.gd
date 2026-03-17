extends Node
## res://scripts/disturbance_meter.gd
## Manages disturbance meter logic and HUD display.
## Attached to DisturbanceMeter node under HUD CanvasLayer.

signal meter_full
signal meter_high(threshold: float)

@export var drain_rate: float = 0.06         # per second when still
@export var fill_rate_base: float = 0.07     # per second per unit speed fraction (slower fill = more playable)
@export var fill_rate_sensitive_mult: float = 3.0

var meter: float = 0.0   # 0.0–1.0
var in_sensitive_zone: bool = false
var _current_speed: float = 0.0
var _was_high: bool = false
var _was_full: bool = false
var _enabled: bool = true

# HUD refs (set by game_manager after ready)
var _bar: ProgressBar = null
var _label: Label = null
var _shake_time: float = 0.0

func _ready() -> void:
	# Find HUD nodes — DisturbanceMeter is child of HUD CanvasLayer
	# HUD/HUDRoot/MeterPanel/MeterVBox/MeterBar etc.
	var hud_root = get_parent().get_node_or_null("HUDRoot")
	if hud_root:
		var panel = hud_root.get_node_or_null("MeterPanel")
		if panel:
			var vbox = panel.get_node_or_null("MeterVBox")
			if vbox:
				_bar = vbox.get_node_or_null("MeterBar")
				_label = vbox.get_node_or_null("ZZZLabel")

func _process(delta: float) -> void:
	if not _enabled:
		return

	# Fill or drain based on speed
	var speed_frac: float = clamp(_current_speed / 120.0, 0.0, 1.0)

	if speed_frac > 0.01:
		var rate = fill_rate_base
		if in_sensitive_zone:
			rate *= fill_rate_sensitive_mult
		meter += rate * speed_frac * delta
	else:
		meter -= drain_rate * delta

	meter = clamp(meter, 0.0, 1.0)

	# Signals
	if meter >= 1.0 and not _was_full:
		_was_full = true
		meter_full.emit()
	elif meter < 1.0:
		_was_full = false

	if meter >= 0.8 and not _was_high:
		_was_high = true
		meter_high.emit(0.8)
	elif meter < 0.8:
		_was_high = false

	# Update HUD
	_update_hud(delta)

func _update_hud(delta: float) -> void:
	if _bar:
		_bar.value = meter * 100.0
		# Color lerp: green -> yellow -> red
		var r: float = clamp(meter * 2.0, 0.0, 1.0)
		var g: float = clamp(2.0 - meter * 2.0, 0.0, 1.0)
		_bar.modulate = Color(r, g, 0.2, 1.0)

	if _label:
		if meter >= 0.8:
			_label.text = "ZZZ!!!"
			# Shake label
			_shake_time += delta * 20.0
			_label.position.x = sin(_shake_time) * 3.0
		else:
			_label.text = "ZZZ Disturbance"
			_label.position.x = 0.0

func _on_spider_moved(speed: float) -> void:
	_current_speed = speed

func set_sensitive(v: bool) -> void:
	in_sensitive_zone = v

func reset() -> void:
	meter = 0.0
	_current_speed = 0.0
	in_sensitive_zone = false
	_was_high = false
	_was_full = false
	if _bar:
		_bar.value = 0.0
	if _label:
		_label.text = "ZZZ Disturbance"
		_label.position.x = 0.0

func set_enabled(v: bool) -> void:
	_enabled = v

func get_meter() -> float:
	return meter
