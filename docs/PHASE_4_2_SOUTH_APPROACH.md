# Phase 4.2 adjustment: Southern-only approach

- Default interaction radius increased from 90 to 160 world units; override per entity in the Inspector.
- Valid interaction range requires player feet to be on or below the entity origin (positive Y).
- Approach samples only the bottom 180 degrees, and continues to its chosen standing position rather than stopping on the first radius crossing.
- If the player is already within range on the bottom half, they remain in place.
- No obstacle avoidance or multiplayer standing-slot reservations yet.
