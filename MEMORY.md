# Memory — Spider Stalker

## Task 3: Presentation Video

### SceneTree Script Gotchas
- `_process(delta: float)` in a `SceneTree` script must return `bool`, not `void` — `false` = continue, `true` = stop. Using `-> void` causes a parse error.
- `_initialize()` does NOT support `await` directly. Use `_process` with an `INIT` phase and check `_frame >= 2` to wait for `_ready()` calls to complete on all child nodes.
- `set()` works to override exported vars on a script (e.g., `_main.set("swat_interval_normal_min", 999.0)`) — useful for suppressing auto-swat during scripted sequences.

### Video Capture
- GPU display `:0` works for `--write-movie` (NVIDIA RTX 4070 SUPER). Use `DISPLAY=:0 godot --rendering-driver vulkan`.
- 950 frames at 30fps = ~31.7s. Recording runs faster than real-time (~2x on this GPU).
- Output: AVI (MJPEG) ~86MB → MP4 (H.264 CRF 28) ~599KB. Very efficient for Telegram delivery.
- `--quit-after N` is the frame count. Script can also call `quit(0)` explicitly.

### Spider Control in Presentation
- Set `_spider.velocity` then `_spider.position += _spider.velocity * delta` directly — bypasses physics but gives clean scripted motion.
- Call `_disturbance_meter._on_spider_moved(speed)` each frame to drive meter fill.
- Level clear: call `_main.call("_on_goal_reached", _spider)` — triggers score increment + overlay.

## Task 2: Core Gameplay

### Script Architecture
- `game_manager.gd` extends `Node2D` (not Node) — must match the scene root type (Main is Node2D)
- `disturbance_meter.gd` extends `Node`, finds HUD nodes via `get_parent().get_node_or_null("HUDRoot/...")` — parent is HUD CanvasLayer
- `swat_hand.gd` builds its own `SpriteFrames` at `_ready()` — do NOT set frames in scene builder (AtlasTexture regions must match actual file size)
- `spider_controller.gd` uses `MOTION_MODE_FLOATING` for top-down movement

### Asset Corrections
- `hand.png` actual size: **1264×848px** (not 630×380 as in ASSETS.md). Left half = raised pose `Rect2(0,0,632,848)`, right half = slammed `Rect2(632,0,632,848)`. Scale to 0.28 for good display size.
- `spider.png` confirmed 992×992, 248×248 per frame, scale 120/248 ≈ 0.484

### Isometric Movement
- W=up-left `Vector2(-1, -0.5)`, S=down-right `Vector2(1, 0.5)`, A=down-left `Vector2(-1, 0.5)`, D=up-right `Vector2(1, -0.5)` — standard 2D isometric
- Bed bounds: `BED_MIN=Vector2(200, 280)`, `BED_MAX=Vector2(680, 520)` — clamp `position` after `move_and_slide()`

### Scene Layout — Corrected
- BedArea at `(500, 380)` in world space
- GoalZone at `(0, -80)` relative to BedArea = world `(500, 300)` — WITHIN bed bounds so spider can reach it
- Original GoalZone at `(0, -220)` = world `(500, 160)` was ABOVE bed min y=280 — unreachable, fixed to `(0, -80)`
- FaceZone at `(0, -130)` = world `(500, 250)` — slightly above bed top, still functionally OK for sensitive zone detection
- HandsZone at `(0, -50)` = world `(500, 330)` — on bed

### Disturbance Meter Tuning
- `fill_rate_base = 0.07` per second (at max speed) — reasonable pacing
- `drain_rate = 0.06` per second when still
- `fill_rate_sensitive_mult = 3.0` in sensitive zones
- At 120px/s for ~10s, meter fills to ~0.7 — gives ~14s of full-speed movement before game over

### Swat Hand
- Shadow: 240×240 procedural circle image created in `trigger_swat()` each time — avoids texture-in-scene-builder issues
- Hand positioned above target (`y - 250`) during telegraph, slams to target position
- Squish detection: distance < 110px from spider to target position
- Auto-hides 0.3s after slam

### GoalZone Connection Pattern
- In `game_manager._ready()`: set `collision_mask = 1` on Area2D zones (spider is layer 1), then `.connect("body_entered", ...)` — zones start with mask=0 in scene, manager enables them at runtime

### Overlay System
- Game over / level clear: created at runtime in `_create_overlay()` as CanvasLayer layer=20
- Uses `Label` + `ColorRect` background, `Control.PRESET_CENTER` anchoring with manual offsets

### Verified Working (from test run)
- Spider moves with WASD, constrained to bed bounds ✓
- Disturbance meter fills while moving, drains when still ✓
- GoalZone triggers "Level Clear! +N" correctly ✓
- Swat shadow glow (yellow) appears on bed ✓
- Hand slams down and squish detection works ✓
- SQUISHED game over screen shows score + restart prompt ✓
- Score increments with level clears ✓

## Task 1: Visual Scene

### Asset Details

- `bedroom_bg.png` is 2752×1536, RGB (no alpha). Scale to fill 1280×720 with `Vector2(1280.0/2752.0, 720.0/1536.0)` — slight non-uniform scale (~0.37% difference) is invisible in practice.
- `bed_raw3.png` is 1200×896, RGB with solid magenta background — NOT usable as a sprite without masking. The bedroom_bg already includes the bed visually; just use bg as full backdrop.
- `spider.png` is 992×992 RGBA, 4×4 grid = 248×248px per frame. AtlasTexture with region `Rect2(col*248, row*248, 248, 248)` works correctly. Scale 120/248 ≈ 0.484 gives good visibility (~120px on screen).
- Spider frame 0 (top-left) is slightly washed — all 16 frames used at 8fps looks fine in practice.

### Build-time vs Runtime

- `AnimatedSprite2D.playing = true` CANNOT be set in a scene builder (headless) — causes "Invalid assignment" error. Must call `anim.play("walk")` in `_ready()` of the runtime script.
- `SpriteFrames.remove_animation("default")` before adding custom animations — avoids orphaned "default" animation.

### GPU Capture

- Display `:0` has NVIDIA RTX 4070 SUPER with Vulkan — use `DISPLAY=:0 godot --rendering-driver vulkan` for GPU rendering.
- Headless `--write-movie` crashes with signal 11 (null texture in dummy renderer) — always need a display for screenshots.
- `xvfb-run` is NOT installed on this system — must use existing display `:0`.

### Scene Layout (viewport 1280×720)

- Bed region (from bedroom_bg) roughly: x=350-670, y=280-500 in viewport space
- Spider initial position: `Vector2(460, 420)` — on bed surface, center-ish
- BedArea node at: `Vector2(500, 380)`

### HUD

- CanvasLayer with `layer=10` keeps HUD above gameplay
- `PRESET_TOP_RIGHT` + `offset_left=-120, offset_top=10, offset_right=-10` works for top-right score label
- PanelContainer + VBoxContainer at position (10,10) for left HUD panel
