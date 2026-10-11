# Phase 4.2 — Interaction slots

Each entity provides up to five slots on either side. Slot positions are based on the entity ground origin, with horizontal separation of 420 world units and vertical spacing of 55. The interaction radius defaults to 480. Slots are reserved on selection and released on deselection, manual movement, or scene unload. If the preferred side is full, the opposite side is tried. If all slots are full, no approach starts. Map boundaries are respected. Multiplayer will require server-authoritative reservations and disconnect cleanup. This local implementation is not network-safe.

Test: `godot --headless --path . --script res://tests/interaction_slots_smoke_test.gd`
