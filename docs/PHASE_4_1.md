# Phase 4.1 — Unified targeting

- Click an enemy, NPC, resource or object to select it.
- A yellow ring identifies the selected entity; a small HUD label shows its name/type.
- Clicking empty ground clears selection and moves the player.
- Only one target may be selected; replacing scenes discards the old targeting controller.
- No combat, gathering or approach is triggered by selection.
- Player controller default speed is 480 world units/sec.

Test: `godot --headless --path . --script res://tests/targeting_smoke_test.gd`

Note: WorldEntity must have a nonzero collision_layer to receive Area2D input events.
