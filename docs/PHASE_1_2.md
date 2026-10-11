# Phase 1.2 — Core architecture

## Responsibilities
- **GameManager**: process mode and lifecycle. Never calculates damage or XP.
- **GameState**: runtime state and notifications. Not authoritative persistence.
- **PlayerState**: serialisable player snapshot with explicit fields.
- **EventBus**: signals only, no side effects.
- **ServiceRegistry**: lookup of scene-owned nodes; prevents duplicate registrations and stale references.

## Runtime flow
Client or server entry scene calls `GameManager.initialize(mode)`.
Gameplay services will be added to the scene tree and registered by ID.
Systems request actions; authoritative validation is planned for the server.
UI listens to EventBus and never mutates combat or inventory directly.

## Cleanup performed
- Kept the root Godot project and preserved the existing Phantom Camera addon.
- Removed redundant nested client/server Godot project files and unused shared sync scaffold.
- Removed generated `.godot`, `.git`, `.DS_Store`, `.import` and macOS metadata from deliverable.
- No Python scripts or dependencies.

## Limits
No Firebase, UDP server, real movement, map loader, or CMS integration implemented yet.
No runtime Godot execution was possible in this build environment.
