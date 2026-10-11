# Phase 3.5 — World Loading and Integration

- `world/world_runner.gd` owns a local `UplordMapInstanceManager` and the active scene.
- Each area can contain multiple scenes, identified by `(area_id, scene_id)`.
- Within an area, scene travel retains instance membership. Across areas, the manager chooses a destination instance and releases the previous membership.
- The map's `player_visual_scale` and `map_size` continue to control player artwork scale and camera framing independently.
- `get_world_location()` returns the current area, scene, instance, spawn and player position. `restore_world_location()` restores area/scene/spawn and an optional in-bounds Vector2 position.
- The instance manager is local preview bookkeeping, **not authoritative server multiplayer**. The future networking phase will move instance assignment and persistence to the server.

## Preview
Open `res://world/world_preview.tscn` and press F6. Move through scene exits.

## Test
`godot --headless --path . --script res://tests/world_integration_smoke_test.gd`

## Known limitation
World travel recreates the local player node. Combat state and long-lived player state need a dedicated persistence integration in later phases. The preview still uses the existing Camera2D implementation rather than Phantom Camera.
