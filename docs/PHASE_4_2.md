# Phase 4.2 — Approach and interaction range

Selecting an entity starts movement toward a nearby point on its lower semicircle. The point is selected from samples within the player movement bounds. The player stops when within the entity's exported `interaction_radius` (default 90 world units). Selecting another entity changes the destination. Clicking ground clears the target and uses normal click-to-move. Keyboard movement cancels the automatic approach. The controller emits `target_range_changed` for Phase 4.3's Interact button. Selection does not trigger combat, dialogue, or gathering.

No navigation mesh or obstacle avoidance is implemented yet; approach points are selected using map bounds only. The movement speed remains 480.

Run `godot --headless --path . --script res://tests/approach_smoke_test.gd`.
