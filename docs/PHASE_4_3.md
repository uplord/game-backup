# Phase 4.3 — Contextual Interact Button

The existing per-map targeting controller now owns a screen-space contextual action button.

- Select an NPC, enemy, resource, or object: button appears disabled while approaching.
- Reach your reserved left/right interaction slot: button enables with Talk, Engage, Gather, or Inspect.
- Press button: `interaction_activated(entity, action)` is emitted. This phase deliberately does not perform combat, gathering, dialogue or inspection gameplay.
- Deselect, move manually or leave the scene: button disables/hides and reservations are released.
- The existing 5-per-side slots, 210-unit distance, 240-unit radius and 480 movement speed are preserved.

Test: `godot --headless --path . --script res://tests/interaction_button_smoke_test.gd`
Preview: `res://world/world_preview.tscn`
