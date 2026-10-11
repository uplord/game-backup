# Phase 3.1 — Map architecture

Run **res://world/scenes/starter_town.tscn**, **forest.tscn**, or **mine.tscn** with F6.

Each map inherits `world/scenes/base_map.tscn`, with reusable Background, Ground,
Decorations, Collision, Spawns, Entities, Actors and Foreground containers.

Select the root map node in the Godot Inspector to set:
- `map_id`: stable content/CMS identifier.
- `map_size`: world dimensions; drives camera framing and movement bounds.
- `player_visual_scale`: **1.0 normal, 0.65 smaller, 1.3 larger**.
  This scales only the character art, preserving walking speed and physics collision.
- `player_spawn`: initial player foot position in map-local coordinates.
- `ground_color`: temporary preview background.

The map uses the existing Phase 2.3 Camera2D framing. Phantom Camera integration
is still outstanding; this phase does not claim to replace it. The camera fits
map height to the usable viewport, so increasing `map_size.y` ALSO makes the
entire world, including the player, appear smaller. The independent visual scale
is available when you want to shrink the character without changing map size.

No transitions, collision polygons, entity spawning or multiplayer instances yet;
those are Phase 3.2–3.5 tasks. Place art in the existing map layers.

Test: `godot --headless --path . --script res://tests/map_architecture_smoke_test.gd`
