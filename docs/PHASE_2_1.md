# Phase 2.1 — Player character (visual foundation)

## Added
- `characters/player/player_character.tscn`: modular three-quarter front character, each body part is its own Polygon2D node.
- `characters/player/player_character.gd`: palette customization, facing left/right, named body-part and equipment-socket accessors.
- `characters/player/player_preview.tscn`: independent visual preview scene. Open and run this scene in Godot; A/Left and D/Right flip the character.
- `tests/player_visual_smoke_test.gd`: headless smoke test for required parts, sockets and facing.

## Deliberate scope limits
The polygons are **temporary, simple placeholders**, not your final Adobe Animate artwork. The player has no movement controller, combat or multiplayer state yet. Equipment sockets are anchor markers; actual gear loading/layering arrives in a later phase. The Phantom Camera addon and Phase 1 client/server startup remain untouched. Replace placeholder polygons with imported art while keeping part names and socket names stable.

## Test
`godot --headless --path . --script res://tests/player_visual_smoke_test.gd`

## Preview
Open `res://characters/player/player_preview.tscn` and press F6 to run the current scene. Left/Right or A/D flips the preview.
