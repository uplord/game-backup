# Uplord — Phase 1.3 data architecture

This is **one Godot project**. Open `project.godot` at the repository root.

- `main/client/` — client entry scene (default Play scene)
- `main/server/` — headless server entry scene (no networking yet)
- `core/` — EventBus, ServiceRegistry, GameState, GameManager, PlayerState
- `addons/phantom_camera/` — preserved from the supplied backup; existing plugin is not removed
- `tests/` — Godot-only smoke tests
- `data/` — validated, versioned content definitions and read-only repository

Phase 1.3: see `docs/PHASE_1_3.md`. Run `godot --headless --path . --script res://tests/content_smoke_test.gd`.
- `docs/` — architecture and run commands

No Python files or code-copying scripts. No duplicate nested Godot projects.

## Run on macOS
From this folder, with `godot` configured on your PATH:

- Client: `godot --path .`
- Headless server: `godot --headless --path . res://main/server/server_main.tscn --quit-after 2`
- Smoke test: `godot --headless --path . --script res://tests/core_smoke_test.gd`

If Terminal says `command not found`, replace `godot` with `/Applications/Godot.app/Contents/MacOS/Godot` (adjust for your installation).

The game is a **bootstrap scaffold**, not the older playable game. This upload contains no original player or map scenes. Phantom Camera is preserved but not yet connected to a player. The current startup scene still uses a placeholder Camera2D.

Godot is not installed in the environment where this ZIP was built, so run the smoke test and scenes locally to verify.

## Phase 1.4: developer tools
See `docs/PHASE_1_4.md` for the logger, F3 overlay, startup diagnostics and test commands.
