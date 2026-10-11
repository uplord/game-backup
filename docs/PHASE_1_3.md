# Phase 1.3 — Data architecture

- `data/local/content.json` is a development-only content bundle (`schema_version: 1`).
- `data/content_validator.gd` checks bundle structure, IDs, duplicates and basic cross-references.
- `data/content_repository.gd` validates before replacing its in-memory snapshot; reads return defensive copies.
- CMS publishing will eventually produce the same versioned bundle format; no Firebase or network integration is included yet.
- Content definitions are **not** player saves or mutable runtime entity state.

## Run

`godot --headless --path . --script res://tests/content_smoke_test.gd`

The repository is deliberately not registered globally yet: Phase 1.4/bootstrapping can decide which local or remote content source is appropriate without introducing autoload ordering issues.

## Limitations

Validation is intentionally a foundation, not a full schema: later phases must add per-type required fields, numeric ranges, skill/area/quest links, migrations, and published-release signatures. No game logic is changed.
