# Phase 3.4 — Map instances

`UplordMapInstanceManager` is a **server-side population model**; it does not yet create networking sessions, synchronise players, or persist occupancy. A single instance belongs to an **area**, and its players can occupy different **scenes** of that area. Moving between scenes within an area preserves the instance ID. Crossing into a different area joins an instance of that area. Empty instances are retired; IDs increase monotonically until reset.

Use `join_area(player_id, area_id, scene_id, preferred_instance_id)` to assign a player and `leave_area(player_id)` when they disconnect. Read `get_location(player_id)` for the resulting area, instance and scene IDs. The optional preferred ID is used if it exists and has space; otherwise a non-full instance is chosen or created. Each area can override `default_capacity` via `area_capacities`. Capacity is the number of **players per area instance**, not per scene.

For a quick headless check from the project directory:

```bash
godot --headless --path . --script res://tests/map_instances_smoke_test.gd
```

**Next:** Phase 3.5 will connect the persistent world runner, server authority and scene transitions to this bookkeeping. Until then, the local world preview is unchanged.
