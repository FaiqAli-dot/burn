class_name DuplicateCheck
extends RefCounted
## Structural signatures for near-duplicate rejection (not raw JSON equality).

var _seen: Dictionary = {} ## signature -> level id


func clear() -> void:
	_seen.clear()


func load_existing(dir_path: String) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if fname.ends_with(".json") and fname.begins_with("burn_"):
			var data := LevelLoader.load_level_dict("%s/%s" % [dir_path, fname])
			if not data.is_empty():
				var sig := signature(data)
				_seen[sig] = String(data.get("id", fname))
		fname = da.get_next()
	da.list_dir_end()


func is_duplicate(level_data: Dictionary) -> bool:
	return _seen.has(signature(level_data))


func register(level_data: Dictionary) -> String:
	var sig := signature(level_data)
	var id := String(level_data.get("id", ""))
	_seen[sig] = id
	return sig


func signature(level_data: Dictionary) -> String:
	## Finer structural fingerprint: ordered scoring materials + 40px cells + sizes.
	var archetype := "HAND"
	var gen = level_data.get("generator", {})
	if typeof(gen) == TYPE_DICTIONARY:
		archetype = String(gen.get("archetype", "HAND"))

	var scoring_tokens: PackedStringArray = PackedStringArray()
	var decoy_n := 0
	for o in level_data.get("objects", []):
		var mat := String(o.get("material", "paper"))
		var p: Array = o.get("position", [0, 0])
		var s: Array = o.get("size", [40, 40])
		var cx := int(round(float(p[0]) / 40.0))
		var cy := int(round(float(p[1]) / 40.0))
		var sx := int(round(float(s[0]) / 20.0))
		var sy := int(round(float(s[1]) / 20.0))
		if bool(o.get("scoring", true)):
			scoring_tokens.append("%s@%d,%d#%d,%d" % [mat.substr(0, 1), cx, cy, sx, sy])
		else:
			decoy_n += 1

	var raw := "%s|d%d|%s" % [archetype, decoy_n, "|".join(scoring_tokens)]
	return str(hash(raw))


func known_count() -> int:
	return _seen.size()
