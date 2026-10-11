# Phase 2.2 — Player movement

Run `res://characters/player/movement_preview.tscn` (F6) to test.

- Left click: move toward clicked world position.
- Hold left mouse: update destination continuously (optional `hold_to_move`).
- Touch and drag: move target updates for mobile.
- WASD / arrow keys: manual movement overrides click destination.
- Character faces left/right according to horizontal movement.
- `move_speed` is world units per second and is independent of sprite scale.
- Bounds default to 1920×1080 for this sandbox; set them per map later.
- Collision uses a foot-level circular shape; walls/obstacles are map work in Phase 3.
- Camera in this preview is static; Phantom Camera integration is Phase 2.3.

Test: `godot --headless --path . --script res://tests/player_movement_smoke_test.gd`

`.gitignore` now ignores `addons/` as requested. This affects untracked addon files only: if already tracked, run `git rm -r --cached addons` to stop tracking them (files remain on disk). Because Phantom Camera lives in `addons/`, a fresh clone must restore it separately.
