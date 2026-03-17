extends CharacterBody2D
## res://scripts/spider_controller.gd

signal died
signal moved(speed: float)

@export var move_speed: float = 120.0

# Isometric movement: W=up-left, S=down-right, A=down-left, D=up-right
# In 2D isometric: up-left = (-1, -0.5) normalized, etc.
const ISO_DIRS = {
	"up_left":   Vector2(-1.0, -0.5),   # W
	"down_right": Vector2(1.0,  0.5),   # S
	"down_left":  Vector2(-1.0,  0.5),  # A
	"up_right":   Vector2(1.0, -0.5),   # D
}

# Bed bounds (viewport 1280x720)
const BED_MIN = Vector2(200.0, 280.0)
const BED_MAX = Vector2(680.0, 520.0)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _alive: bool = true
var _game_over: bool = false

func _ready() -> void:
	if anim:
		anim.play("walk")

func _physics_process(delta: float) -> void:
	if _game_over or not _alive:
		velocity = Vector2.ZERO
		return

	# Build isometric movement direction
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir += ISO_DIRS["up_left"]
	if Input.is_action_pressed("move_down"):
		dir += ISO_DIRS["down_right"]
	if Input.is_action_pressed("move_left"):
		dir += ISO_DIRS["down_left"]
	if Input.is_action_pressed("move_right"):
		dir += ISO_DIRS["up_right"]

	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity = dir * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Clamp to bed bounds
	position.x = clamp(position.x, BED_MIN.x, BED_MAX.x)
	position.y = clamp(position.y, BED_MIN.y, BED_MAX.y)

	# Emit current speed (0 when still, move_speed when moving)
	var current_speed: float = velocity.length()
	moved.emit(current_speed)

func die() -> void:
	_alive = false
	if anim:
		anim.modulate = Color(1.0, 0.2, 0.2, 0.7)
	died.emit()

func set_game_over(v: bool) -> void:
	_game_over = v

func reset_to_start() -> void:
	_alive = true
	_game_over = false
	position = Vector2(460.0, 420.0)
	velocity = Vector2.ZERO
	if anim:
		anim.modulate = Color.WHITE
		anim.play("walk")
