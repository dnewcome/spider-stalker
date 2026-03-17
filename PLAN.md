# Game Plan: Spider Stalker

## Game Description

The player controls a spider walking across sleeping humans in their bedroom at night. The view is isometric pseudo-3D (like classic Diablo/Baldur's Gate — 2D sprites rendered to look 3D from an isometric angle).

Core gameplay:
- The spider navigates across the body/bed of a sleeping person, moving from one end to the other as the goal
- Movement creates a "disturbance meter" that fills based on speed and where you step (sensitive spots like face and hands cause more disturbance)
- Periodically the human's sleep cycle triggers a swat — a hand slams down near the spider. The spider must dodge or it is squished (game over)
- Swats are telegraphed: the hand rises and a shadow appears on the bed, giving the player a moment to evade
- If the disturbance meter fills too high the human wakes and swats more aggressively, or fully wakes for instant game over
- Reach the far edge of the bed to advance to the next sleeping human; score increases per human crossed

Visual style:
- Dark bedroom at night, moonlight through curtains
- Isometric pseudo-3D: bed, pillow, blanket, and sleeping human are isometric sprites with depth/shading
- Spider is a detailed isometric sprite with animated legs (scuttle movement)
- Swat hand is a large fleshy hand sprite slamming down with impact dust effect
- Disturbance meter shown as an agitated ZZZ indicator that grows more frantic as it fills

## 1. Visual Scene — Bedroom & Spider
- **Depends on:** (none)
- **Status:** done
- **Targets:** scenes/main.tscn, scenes/build_main.gd, scripts/game_manager.gd, project.godot
- **Goal:** Establish the full isometric visual scene: bedroom background, bed with sleeping human, and the playable spider — all correctly sized, positioned, and layered for isometric depth. No gameplay yet.
- **Requirements:**
  - Bedroom background fills the viewport — dark room, moonlit window, furniture
  - Bed is centered in the isometric view, large enough to walk across (~60% of screen width)
  - Sleeping human visible as a lumpy shape under blanket on the bed
  - Spider sprite sits on the bed, ~48px tall, with 8-frame scuttle walk animation cycling at idle
  - Isometric y-sorting active so the spider renders in front of bed edge, behind headboard
  - Score label top-right; disturbance meter bar top-left with ZZZ label — placeholder values, no logic yet
- **Assets:**
  - `bedroom_bg` background (`assets/img/bedroom_bg.png`) — fullscreen 1920×1080, already includes bed and sleeping person; use as full backdrop. Bed region is roughly center-left third of image.
  - `bed` sprite (`assets/img/bed_raw3.png`) — ~480×360px isometric bed with sleeping human; use with ColorRect or place on top of background at matching position. Note: transparent version `bed.png` has slight alpha fringe.
  - `spider` spritesheet (`assets/img/spider.png`) — 4×4 grid, 248×248px per frame, hframes=4 vframes=4, transparent bg. All 16 frames usable as walk/idle animation.
- **Verify:** Screenshot shows the dark isometric bedroom with bed center-screen, sleeping human visible under blanket, spider sitting on the bed with legs visibly animated, HUD elements present in corners.

## 2. Core Gameplay — Movement, Disturbance & Swat
- **Depends on:** 1
- **Status:** done
- **Targets:** scripts/spider_controller.gd, scripts/game_manager.gd, scripts/swat_hand.gd, scripts/disturbance_meter.gd, scenes/main.tscn
- **Goal:** All gameplay systems: spider movement, disturbance meter filling, swat telegraphing and dodge, level progression, and game over/win conditions.
- **Requirements:**
  - WASD/arrow keys move the spider in isometric directions across the bed; movement speed is capped (~120 px/s)
  - Disturbance meter fills while moving (faster = more), drains slowly when still; sensitive zones (face, hands area near pillow/sides) fill it 3× faster
  - Meter displayed as a progress bar with ZZZ icons that multiply and shake as meter fills (calm at 0%, frantic at 80%+)
  - Every 4–8 seconds a swat triggers: shadow circle appears on the bed at a random position near the spider; 1.5s later the hand sprite slams down — spider inside the shadow at impact = game over squish
  - If disturbance meter ≥ 80%: swats trigger every 2–3s instead; at 100%: instant game over ("human woke up!")
  - Reaching the far (top) edge of the bed clears the level: brief "Level Clear!" flash, score +1, new human/bed resets
  - Game over shows score and restart prompt
- **Assets:**
  - `hand` sprite (`assets/img/hand.png`) — left half=raised pose, right half=slammed pose, ~300×220px each; crop at 50% width for two animation frames. Use for swat animation. Impact dust can be drawn procedurally with particles.
- **Verify:** Spider moves across bed with WASD. Disturbance meter visibly rises when moving fast, slows when still. Shadow circle appears and hand slams down after delay — standing in shadow causes game over. Reaching far edge increments score. Meter at 100% triggers immediate wake game over.

## 3. Presentation Video
- **Depends on:** 2
- **Status:** done
- **Targets:** test/presentation.gd, screenshots/presentation/gameplay.mp4
- **Goal:** Create a ~30-second cinematic video showcasing the completed game.
- **Requirements:**
  - Write test/presentation.gd — a SceneTree script (extends SceneTree)
  - Showcase representative gameplay via simulated input or scripted animations
  - ~900 frames at 30 FPS (30 seconds)
  - Use Video Capture from godot-capture (AVI via --write-movie, convert to MP4 with ffmpeg)
  - Output: screenshots/presentation/gameplay.mp4
  - **2D games:** camera pans and smooth scrolling, zoom transitions between overview and close-up, trigger representative gameplay sequences, tight viewport framing
- **Verify:** A smooth MP4 video showing polished gameplay with no visual glitches.
