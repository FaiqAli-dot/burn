class_name LevelSequenceBuilder
extends RefCounted
## Builds difficulty-ordered play sequence: teaching → phase2 → catalog.


static func build() -> Array:
	var paths: Array = []
	## Teaching first (FTE).
	for i in range(1, 9):
		var p := "res://resources/levels/teaching/teach_%02d.json" % i
		if FileAccess.file_exists(p):
			paths.append(p)
	## Representative Phase 2 handcrafted.
	var phase2 := [
		"res://resources/levels/phase2/p2_simple.json",
		"res://resources/levels/phase2/p2_grass.json",
		"res://resources/levels/phase2/p2_fabric.json",
		"res://resources/levels/phase2/p2_oil.json",
		"res://resources/levels/phase2/p2_explosion.json",
		"res://resources/levels/phase2/p2_multi.json",
		"res://resources/levels/phase2/p2_trap.json",
		"res://resources/levels/phase2/p2_large_chain.json",
	]
	for p in phase2:
		if FileAccess.file_exists(p):
			paths.append(p)
	## Catalog generated levels by difficulty.
	var catalog_path := "res://resources/levels/generated/catalog.json"
	if FileAccess.file_exists(catalog_path):
		var raw := LevelLoader.load_level_dict(catalog_path)
		var entries: Array = raw.get("entries", [])
		entries.sort_custom(func(a, b) -> bool:
			return float(a.get("difficulty", 0.0)) < float(b.get("difficulty", 0.0))
		)
		## Cap for mobile vertical slice — playable subset.
		var cap := mini(entries.size(), 40)
		for i in cap:
			var path := String(entries[i].get("path", ""))
			if path != "" and FileAccess.file_exists(path):
				paths.append(path)
	## Always ensure SPARK is available if teaching missing.
	if paths.is_empty():
		paths.append("res://resources/levels/level_01.json")
	return paths
