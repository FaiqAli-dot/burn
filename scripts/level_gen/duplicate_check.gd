class_name DuplicateCheck
extends RefCounted
## Structural signatures for near-duplicate rejection (not raw JSON equality).

var _seen: Dictionary = {} ## signature -> level id


func clear() -> void:
	_seen.clear()


func load_existing(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		## Also try res:// path via DirAccess.open
		pass
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if fname.ends_with(".json"):
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
	## Compact structural fingerprint.
	var archetype := "HAND"
	var gen = level_data.get("generator", {})
	if typeof(gen) == TYPE_DICTIONARY:
		archetype = String(gen.get("archetype", "HAND"))

	var mats: PackedStringArray = PackedStringArray()
	var scoring_n := 0
	var decoy_n := 0
	var cells: PackedStringArray = PackedStringArray()
	for o in level_data.get("objects", []):
		var mat := String(o.get("material", "paper"))
		mats.append(mat)
		if bool(o.get("scoring", true)):
			scoring_n += 1
		else:
			decoy_n += 1
		var p: Array = o.get("position", [0, 0])
		## Quantize to 80px cells for near-dupe tolerance.
		var cx := int(floor(float(p[0]) / 80.0))
		var cy := int(floor(float(p[1]) / 80.0))
		cells.append("%s:%d:%d" % [mat.substr(0, 1), cx, cy])
	mats.sort()
	cells.sort()

	## Relative solution position: lowest scoring paper approx.
	var start_cell := "na"
	var best_y := -9999.0
	for o in level_data.get("objects", []):
		if not bool(o.get("scoring", true)):
			continue
		if String(o.get("material", "")) != "paper":
			continue
		var p: Array = o.get("position", [0, 0])
		if float(p[1]) > best_y:
			best_y = float(p[1])
			start_cell = "%d:%d" % [int(floor(float(p[0]) / 80.0)), int(floor(float(p[1]) / 80.0))]

	var raw := "%s|s%d|d%d|m:%s|c:%s|st:%s" % [
		archetype,
		scoring_n,
		decoy_n,
		",".join(mats),
		",".join(cells),
		start_cell,
	]
	return str(hash(raw))


func known_count() -> int:
	return _seen.size()
