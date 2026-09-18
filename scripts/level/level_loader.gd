class_name LevelLoader
extends RefCounted
## Loads level JSON + material resources and spawns BurnableObject instances.

const MATERIAL_PATHS := {
	"paper": "res://resources/materials/paper.tres",
	"wood": "res://resources/materials/wood.tres",
}

const BURNABLE_SCENE := preload("res://scenes/burnable_object.tscn")


static func load_level_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open level: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Level JSON invalid: %s" % path)
		return {}
	return parsed


static func get_material(material_id: String) -> MaterialDefinition:
	if not MATERIAL_PATHS.has(material_id):
		push_error("Unknown material '%s' — register it in LevelLoader.MATERIAL_PATHS" % material_id)
		return null
	return load(MATERIAL_PATHS[material_id]) as MaterialDefinition


static func spawn_level(parent: Node, level_path: String) -> Dictionary:
	## Returns { "meta": Dictionary, "objects": Array[BurnableObject] }
	var data := load_level_dict(level_path)
	var spawned: Array[BurnableObject] = []
	if data.is_empty():
		return {"meta": {}, "objects": spawned}

	var entries: Array = data.get("objects", [])
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var mat_id := String(entry.get("material", "paper"))
		var mat := get_material(mat_id)
		if mat == null:
			continue
		var obj := BURNABLE_SCENE.instantiate() as BurnableObject
		obj.material_def = mat
		var size_arr: Array = entry.get("size", [mat.default_size.x, mat.default_size.y])
		obj.object_size = Vector2(float(size_arr[0]), float(size_arr[1]))
		var pos_arr: Array = entry.get("position", [0, 0])
		obj.position = Vector2(float(pos_arr[0]), float(pos_arr[1]))
		obj.rotation_degrees = float(entry.get("rotation_deg", 0.0))
		obj.name = String(entry.get("id", "burnable"))
		obj.counts_for_score = bool(entry.get("scoring", true))
		parent.add_child(obj)
		spawned.append(obj)

	return {
		"meta": {
			"id": String(data.get("id", "level")),
			"display_name": String(data.get("display_name", "LEVEL")),
			"hint": String(data.get("hint", "")),
		},
		"objects": spawned,
	}
