# Phase 6.1 — local combat prototype

This adds `world/components/combat_controller.gd`, instantiated by `UplordMapBase` after targeting. Select a published enemy, approach it, and engage. Press **1** or **Attack (1)** to deal preview damage. Enemy attacks periodically; it disappears on defeat and respawns after its configured delay.

## Enemy CMS fields

- `max_hp` (default 100)
- `level` (default 1)
- `damage` (default 5)
- `attack_interval` (default 2 seconds)
- `respawn_seconds` (default 15 seconds)
- `preview_player_damage` (default 10)
- `player_attack_interval` (default 1 second)

This is deliberately a **local gameplay prototype**, not authoritative multiplayer combat. Enemy state is local to the loaded scene, and player death resets preview HP. Skills, MP, XP, drops, persistent health, and server-side combat are not yet implemented. Existing CMS definitions can supply these optional fields; publishing changes requires a new release and reloading the game.
