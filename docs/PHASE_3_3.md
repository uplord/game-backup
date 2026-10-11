# Phase 3.3 — World entities

Reusable `world/components/world_entity.tscn` with `world_entity.gd` supports four placement types: enemy, npc, resource, object. Set `entity_type`, `definition_id`, and a unique `placement_id` in each map scene. The visual marker is a placeholder, not a gameplay sprite.

Map scenes retain the `Entities` node inherited from `base_map.tscn`. Sample placements: village guide and notice board in starter town plaza, training dummy in forest entrance, copper rock in mine entrance. Their definitions are stored in `data/local/content.json`.

`UplordMapBase.list_world_entities()` lists placements and `validate_world_entities(repository)` checks duplicate/missing placement IDs and unknown content references. This phase only lays out and validates entities. Interaction range, targeting, NPC dialogue, combat, resource depletion, respawning and server authority belong to later phases. Clicking a placeholder emits `interaction_requested`, but nothing consumes it yet.

Test: `godot --headless --path . --script res://tests/world_entities_smoke_test.gd`
