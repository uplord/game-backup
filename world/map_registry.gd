extends RefCounted
class_name UplordMapRegistry
## One area contains multiple scenes. Stable IDs are independent of file paths.
const AREAS := {
	"starter_town": {
		"plaza": "res://world/areas/starter_town/scenes/plaza.tscn",
		"east_gate": "res://world/areas/starter_town/scenes/east_gate.tscn",
	},
	"forest": {
		"entrance": "res://world/areas/forest/scenes/entrance.tscn",
		"clearing": "res://world/areas/forest/scenes/clearing.tscn",
	},
	"mine": {
		"entrance": "res://world/areas/mine/scenes/entrance.tscn",
	},
}
const DEFAULT_SCENES := {"starter_town":"plaza", "forest":"entrance", "mine":"entrance"}
static func has_scene(area_id: String, scene_id: String) -> bool:
	return AREAS.has(area_id) and AREAS[area_id].has(scene_id)
static func get_scene_path(area_id: String, scene_id: String = "") -> String:
	var resolved := scene_id if not scene_id.is_empty() else str(DEFAULT_SCENES.get(area_id, ""))
	return str(AREAS[area_id].get(resolved, "")) if AREAS.has(area_id) else ""
static func load_scene(area_id: String, scene_id: String = "") -> PackedScene:
	var path := get_scene_path(area_id, scene_id)
	if path.is_empty():
		push_error("Unknown area/scene: %s/%s" % [area_id, scene_id])
		return null
	return load(path) as PackedScene
# Backwards-compatible single-argument lookup for older callers.
static func load_map(map_id: String) -> PackedScene:
	return load_scene(map_id)
