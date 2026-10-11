# Phase 1.4 — Development Tools

## Changes
- `DevLogger` autoload provides bounded structured logs, levels, categories and defensive snapshots.
- `UplordStartupDiagnostics.inspect()` checks required startup files, configured autoloads and validates the local content bundle.
- Client-only F3 debug overlay shows FPS, mode, current area and log entry count in debug builds. It is not attached to the server.
- Added `tests/startup_smoke_test.gd` and `tests/dev_tools_smoke_test.gd`.
- Preserved the original project and Phantom Camera addon. No gameplay or camera tuning changed.

## Commands (from the folder containing project.godot)

```sh
godot --headless --path . --script res://tests/core_smoke_test.gd
godot --headless --path . --script res://tests/content_smoke_test.gd
godot --headless --path . --script res://tests/startup_smoke_test.gd
godot --headless --path . --script res://tests/dev_tools_smoke_test.gd
godot --headless --path . res://main/server/server_main.tscn --quit-after 2
```

For the client, press F3 while running the debug build to show/hide the overlay.

## Limits
No live networking, CI pipeline or deployed build has been added. This environment does not have a Godot executable; run the tests on your Mac before proceeding.
