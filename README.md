# Spider Stalker

A stealth survival game where you play as a spider navigating across sleeping humans in a dark bedroom. Move carefully — wake them up and you're done.

![Spider Stalker](reference.png)

## Gameplay

You control a spider crossing a sleeping person's bed. Reach the far edge to advance to the next human and increase your score.

**The challenge:**
- Moving fills a **disturbance meter** — faster movement fills it faster
- Sensitive spots (face, hands near the pillow) fill it 3× faster
- Stay still to let the meter drain
- Periodically, the human's hand **swats** down near you — a shadow telegraphs where it will land. Get out of the shadow or get squished
- At **80%+ disturbance**, swats become much more frequent
- At **100%**, the human wakes up — instant game over

## Controls

| Action | Keys |
|--------|------|
| Move | WASD / Arrow Keys |
| Restart | R |

## Visual Style

Dark isometric pseudo-3D bedroom at night. Moonlight through curtains, a bed with a sleeping figure under the blanket, and a detailed spider with animated scuttling legs. The disturbance meter displays as a ZZZ indicator that grows more frantic as it fills.

## Built With

- [Godot 4](https://godotengine.org/)
- Procedural particle effects for swat impact dust
- Isometric y-sorting for depth layering
