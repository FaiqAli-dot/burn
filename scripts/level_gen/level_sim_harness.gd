class_name LevelSimHarness
extends RefCounted
## Headless spawn + tick loop using the REAL FireManager / BurnableObject sim.
## Visual nodes are not required; heat/state APIs drive gameplay.

const DT := 1.0 / 60.0
const MAX_SECONDS := 35.0


static func build_objects(level_data: Dictionary) -> Array[BurnableObject]:
	var objects: Array[BurnableObject] = []
	var entries: Array = level_data.get("objects", [])
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var mat := LevelLoader.get_material(String(entry.get("material", "paper")))
		if mat == null:
			continue
		var obj := BurnableObject.new()
		obj.material_def = mat
		var size_arr: Array = entry.get("size", [mat.default_size.x, mat.default_size.y])
		obj.object_size = Vector2(float(size_arr[0]), float(size_arr[1]))
		obj.burn_weight = maxf(obj.object_size.x * obj.object_size.y, 1.0)
		var pos_arr: Array = entry.get("position", [0, 0])
		obj.position = Vector2(float(pos_arr[0]), float(pos_arr[1]))
		obj.rotation_degrees = float(entry.get("rotation_deg", 0.0))
		obj.name = String(entry.get("id", "burnable_%d" % objects.size()))
		obj.counts_for_score = bool(entry.get("scoring", true))
		objects.append(obj)
	return objects


static func has_active_fire(objects: Array[BurnableObject]) -> bool:
	for obj in objects:
		if not is_instance_valid(obj):
			continue
		if obj.state in [
			BurnableObject.State.IGNITING,
			BurnableObject.State.BURNING,
			BurnableObject.State.CHARRED,
		]:
			return true
	return false


static func run_ignition(
	level_data: Dictionary,
	start_id: String,
	max_seconds: float = MAX_SECONDS
) -> Dictionary:
	## Reset → ignite start_id → tick until settle. Returns metrics dict.
	var objects := build_objects(level_data)
	var fire := FireManager.new()
	fire.set_objects(objects)

	var target: BurnableObject = null
	for obj in objects:
		if obj.name == start_id:
			target = obj
			break
	if target == null:
		return {
			"start_object": start_id,
			"success": false,
			"burn_percent": 0.0,
			"destroyed_count": 0,
			"scoring_destroyed": 0,
			"scoring_total": 0,
			"chain_length": 0,
			"ignition_order": [],
			"max_simultaneous_burning": 0,
			"duration": 0.0,
			"error": "missing_start",
		}

	var ignition_order: Array = []
	var max_simul := 0
	for obj in objects:
		obj.ignited.connect(func(_by_player: bool) -> void:
			ignition_order.append(obj.name)
		)

	var ignited_ok := fire.request_player_ignite(target)
	if not ignited_ok:
		return {
			"start_object": start_id,
			"success": false,
			"burn_percent": 0.0,
			"destroyed_count": 0,
			"scoring_destroyed": 0,
			"scoring_total": _count_scoring(objects),
			"chain_length": 0,
			"ignition_order": [],
			"max_simultaneous_burning": 0,
			"duration": 0.0,
			"error": "ignite_failed",
		}

	var elapsed := 0.0
	var steps := int(max_seconds / DT)
	for i in steps:
		fire.tick(DT)
		elapsed += DT
		var burning_now := 0
		for obj in objects:
			if obj.state == BurnableObject.State.BURNING:
				burning_now += 1
		max_simul = maxi(max_simul, burning_now)
		if fire.is_fully_burned():
			break
		if fire.has_started() and not has_active_fire(objects):
			break

	var destroyed := 0
	var scoring_destroyed := 0
	var scoring_total := 0
	for obj in objects:
		if obj.counts_for_score:
			scoring_total += 1
			if obj.state == BurnableObject.State.DESTROYED:
				scoring_destroyed += 1
		if obj.state == BurnableObject.State.DESTROYED:
			destroyed += 1

	return {
		"start_object": start_id,
		"success": fire.is_fully_burned(),
		"burn_percent": fire.get_burn_percent(),
		"destroyed_count": destroyed,
		"scoring_destroyed": scoring_destroyed,
		"scoring_total": scoring_total,
		"chain_length": ignition_order.size(),
		"ignition_order": ignition_order,
		"max_simultaneous_burning": max_simul,
		"duration": elapsed,
		"error": "",
	}


static func _count_scoring(objects: Array[BurnableObject]) -> int:
	var n := 0
	for obj in objects:
		if obj.counts_for_score:
			n += 1
	return n
