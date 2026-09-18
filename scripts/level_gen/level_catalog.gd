class_name LevelCatalog
extends RefCounted
## Lightweight index of generated levels (no progression UI).

var entries: Array = [] ## Dictionaries


func clear() -> void:
	entries.clear()


func add(level_data: Dictionary, difficulty: Dictionary, solve_report: Dictionary, path: String) -> void:
	var gen: Dictionary = {}
	if typeof(level_data.get("generator", null)) == TYPE_DICTIONARY:
		gen = level_data["generator"]
	entries.append({
		"id": String(level_data.get("id", "")),
		"path": path,
		"archetype": String(gen.get("archetype", "")),
		"seed": int(gen.get("seed", 0)),
		"difficulty": float(difficulty.get("difficulty", 0.0)),
		"band": String(difficulty.get("band", "")),
		"solution_count": int(solve_report.get("solution_count", 0)),
		"policy": String(gen.get("solution_policy", "")),
	})


func get_by_id(id: String) -> Dictionary:
	for e in entries:
		if String(e.get("id", "")) == id:
			return e
	return {}


func get_by_seed(seed_value: int) -> Array:
	var out: Array = []
	for e in entries:
		if int(e.get("seed", -1)) == seed_value:
			out.append(e)
	return out


func get_by_archetype(archetype: String) -> Array:
	var out: Array = []
	var a := archetype.to_upper()
	for e in entries:
		if String(e.get("archetype", "")).to_upper() == a:
			out.append(e)
	return out


func get_by_difficulty_range(lo: float, hi: float) -> Array:
	var out: Array = []
	for e in entries:
		var d := float(e.get("difficulty", 0.0))
		if d >= lo and d <= hi:
			out.append(e)
	return out


func to_json_dict() -> Dictionary:
	return {"count": entries.size(), "entries": entries}


func save(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write catalog: %s" % path)
		return
	file.store_string(JSON.stringify(to_json_dict(), "\t"))


func load_file(path: String) -> void:
	var data := LevelLoader.load_level_dict(path)
	entries.clear()
	if typeof(data.get("entries", null)) == TYPE_ARRAY:
		entries = data["entries"]
