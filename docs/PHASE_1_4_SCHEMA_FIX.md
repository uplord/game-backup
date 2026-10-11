# Phase 1.4 schema version fix

Godot `JSON.parse_string()` converts JSON numbers to floating-point Variants, so the JSON literal `1` can arrive as `1.0`. The validator previously required `TYPE_INT`, incorrectly rejecting valid local content. It now accepts numeric 1 in either integer or float representation, while rejecting strings and unsupported versions. The original content JSON is unchanged.

The startup diagnostics also frees its temporary content repository after inspection.

Run:

```sh
godot --headless --path . --script res://tests/content_smoke_test.gd
godot --headless --path . res://main/server/server_main.tscn --quit-after 2
```
