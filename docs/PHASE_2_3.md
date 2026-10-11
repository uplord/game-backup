# Phase 2.3 — Map camera and responsive framing

Open `res://characters/player/movement_preview.tscn` and press F6.

- Camera follows player on X only, never on Y.
- Zoom is derived from the entire vertical map height.
- Camera clamps horizontally at the world edges; player keeps moving towards edges.
- Landscape viewport is limited to 16:9 and black side bars fill the rest.
- Portrait reserves a bottom black HUD region outside the playable map area.
- Mouse clicks use the existing player controller world-coordinate movement.
- Existing Phantom Camera addon is preserved. This phase uses a native Camera2D driver to avoid dependency on plugin editor registration; Phantom Camera-specific effects remain for a later integration.

Resize the game window and verify map height stays fully visible and the player does not jump. On phones, safe-area insets still need device testing and a later UI-specific pass.
