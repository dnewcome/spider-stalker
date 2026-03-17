# Assets

**Art direction:** Dark isometric bedroom at night — hand-painted pixel art with ink outlines, deep blue-grey shadows, warm moonlight from curtained window casting silver on the bed. Chunky Diablo-style isometric 2D sprites with strong depth shading. Rich atmospheric darkness contrasting with the glowing swat-warning circle on the bed.

## Backgrounds

| Name | Description | Size | Image |
|------|-------------|------|-------|
| bedroom_bg | Dark isometric bedroom at night, moonlit window, sleeping person visible in bed, full room view | 1920×1080, fullscreen | assets/img/bedroom_bg.png |

## Sprites

| Name | Description | Size | Image |
|------|-------------|------|-------|
| bed | Isometric bed with sleeping human under dark green blanket, transparent bg (alpha matting — use raw if bg is problem) | ~480×360px | assets/img/bed.png (raw: assets/img/bed_raw3.png) |
| spider | Tarantula spider spritesheet, 4×4 grid (16 frames), transparent bg, ~248×248px per frame | 248×248px per frame, hframes=4 vframes=4 | assets/img/spider.png |
| hand | Swat hand — two poses side by side: left=raised/hovering, right=flat/slammed. Transparent bg. Split at midpoint for two frames | ~300×220px each pose | assets/img/hand.png |

## Notes

- `bedroom_bg.png` already includes the bed and sleeping person — use as the full backdrop. The bed region for gameplay is roughly the center-left third of the image.
- `bed.png` background removal was imperfect (semi-transparent magenta fringe). Use `bed_raw3.png` with a ColorRect mask or just use bedroom_bg as backdrop and define bed bounds in code.
- `spider.png`: top-left frame (frame 0) is slightly washed — use frames 1–15 or just accept it as idle.
- `hand.png`: left half = raised pose, right half = slammed pose — crop at 50% width for two separate frames.
