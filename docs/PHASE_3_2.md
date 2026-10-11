# Phase 3.2 — area scenes and transitions

## Design
- **Area** is a named region (starter_town, forest, mine).
- **Scene** is a traversable screen inside that area (plaza, east_gate, etc.).
- Each scene is a separate Godot PackedScene under `world/areas/<area>/scenes/`.
- `UplordMapRegistry` resolves `(area_id, scene_id)` to the corresponding PackedScene.
- Every scene has independent `map_size`, `player_visual_scale` and artwork layers.
- Exit Area2Ds identify destination area, scene and named spawn. Spawn markers sit under `Spawns`.
- `world/world_preview.tscn` owns the active map and swaps scenes without requiring a full project scene reload.
- Example route: Starter Town plaza ↔ east gate ↔ Forest entrance ↔ clearing ↔ Mine entrance.
- Player appearance and position are reinitialised per scene for now. Persistent state and multiplayer instances come in later phases.

## Try it
Run `res://world/world_preview.tscn` (F6), walk to the far right to cross the first exit. Walk left to return. Exits are wide vertical strips near map edges. They are invisible in gameplay.

## Smoke test
`godot --headless --path . --script res://tests/map_transition_smoke_test.gd`

## Notes
Old `world/scenes/starter_town.tscn`, `forest.tscn` and `mine.tscn` remain as legacy Phase 3.1 standalone previews. New development should use the area/scene paths and world runner. Current camera is the Phase 2.3 native Camera2D; Phantom Camera integration is still outstanding.
