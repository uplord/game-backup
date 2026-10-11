# Phase 4.4 — Targeting integration

- One selected entity per map, with reserved interaction slot.
- Selection switches release the prior reservation.
- Ground click and keyboard movement cancel targeting.
- Interact is enabled only when the player reaches the reserved slot.
- Scene transition explicitly clears targeting before removing the old map.
- Target controller teardown releases reservations.
- State enum: IDLE, APPROACHING, READY, INTERACTING.
- Interaction signals remain placeholders for future gameplay handlers.

Run `godot --headless --path . --script res://tests/targeting_integration_smoke_test.gd`.
