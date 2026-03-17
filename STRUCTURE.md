# Spider Stalker

## Dimension: 2D (Isometric pseudo-3D)

## Input Actions

| Action | Keys |
|--------|------|
| move_up | W, Up |
| move_down | S, Down |
| move_left | A, Left |
| move_right | D, Right |
| restart | R |

## Scenes

### Main
- **File:** res://scenes/main.tscn
- **Root type:** Node2D
- **Children:** Background, BedScene, Spider, SwatHand, CanvasLayer/HUD

### BedScene (inline in main)
- Sprite2D (bedroom background image)
- Node2D "BedArea" — contains bed sprite + sensitive zones as Area2D shapes
- Sprite2D "BedSprite" — isometric bed with sleeping human
- Area2D "FaceZone" — high-disturbance zone near pillow
- Area2D "HandsZone" — high-disturbance zone at bed sides
- Area2D "GoalZone" — far edge trigger for level clear

### Spider
- **File:** res://scenes/spider.tscn
- **Root type:** CharacterBody2D
- **Children:** AnimatedSprite2D, CollisionShape2D

### SwatHand
- **File:** res://scenes/swat_hand.tscn
- **Root type:** Node2D
- **Children:** Sprite2D "Shadow", AnimatedSprite2D "Hand", Area2D "HitZone"

## Scripts

### GameManager
- **File:** res://scripts/game_manager.gd
- **Extends:** Node
- **Attaches to:** Main
- **Signals emitted:** game_over, level_cleared
- **Signals received:** Spider.died, GoalZone.body_entered -> _on_goal_reached, SwatHand.squished -> _on_squished

### SpiderController
- **File:** res://scripts/spider_controller.gd
- **Extends:** CharacterBody2D
- **Attaches to:** Spider
- **Signals emitted:** died, moved(speed)
- **Signals received:** (none)

### DisturbanceMeter
- **File:** res://scripts/disturbance_meter.gd
- **Extends:** CanvasLayer
- **Attaches to:** HUD/DisturbanceMeter node
- **Signals emitted:** meter_full, meter_high(threshold_reached)
- **Signals received:** SpiderController.moved(speed) -> _on_spider_moved

### SwatHand
- **File:** res://scripts/swat_hand.gd
- **Extends:** Node2D
- **Attaches to:** SwatHand
- **Signals emitted:** squished
- **Signals received:** GameManager.swat_triggered(pos) -> trigger_swat

## Signal Map

- Spider:SpiderController.moved -> DisturbanceMeter._on_spider_moved
- Spider:SpiderController.died -> GameManager._on_spider_died
- Main:GoalZone.body_entered -> GameManager._on_goal_reached
- SwatHand:SwatHand.squished -> GameManager._on_squished
- GameManager.swat_triggered -> SwatHand.trigger_swat
- DisturbanceMeter.meter_full -> GameManager._on_meter_full
- DisturbanceMeter.meter_high -> GameManager._on_meter_high

## Asset Hints

- Bedroom background: isometric night bedroom, moonlit window, furniture, 1920×1080 fullscreen
- Bed sprite: isometric bed with pillow, blanket lump (sleeping human), ~600×400px single sprite
- Spider sprite sheet: 4×4 grid, 4 walk directions × 4 frames, ~96×96px per frame
- Swat hand sprite: large fleshy hand/fist from above, raised + slammed poses, ~200×300px
- Impact dust puff sprite: 4-frame circular burst, ~64×64px per frame
