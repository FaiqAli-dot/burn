extends SceneTree


func _init() -> void:
	var good := _run_case("start_paper")
	var decoy := _run_case("decoy_wood")
	var dead := _run_case("decoy_paper_a")
	var top := _run_case("p_crown_l")

	print("VALIDATE start_paper burned=%.1f%% fully=%s" % [good.percent, good.fully])
	print("VALIDATE decoy_wood burned=%.1f%% fully=%s" % [decoy.percent, decoy.fully])
	print("VALIDATE decoy_paper_a burned=%.1f%% fully=%s" % [dead.percent, dead.fully])
	print("VALIDATE p_crown_l burned=%.1f%% fully=%s" % [top.percent, top.fully])

	var all_ok := true
	if not good.fully or good.percent < 99.0:
		printerr("FAIL: start_paper should clear scoring objects")
		all_ok = false
	if decoy.fully or decoy.percent > 5.0:
		printerr("FAIL: decoy_wood should not progress the real level")
		all_ok = false
	if dead.fully or dead.percent > 5.0:
		printerr("FAIL: decoy paper cluster should not progress the real level")
		all_ok = false

	if all_ok:
		print("VALIDATE_OK")
		quit(0)
	else:
		print("VALIDATE_FAIL")
		quit(1)


func _run_case(object_id: String) -> Dictionary:
	var objects: Array[BurnableObject] = []
	var data := LevelLoader.load_level_dict("res://resources/levels/level_01.json")
	for entry_variant in data.get("objects", []):
		var entry: Dictionary = entry_variant
		var mat := LevelLoader.get_material(String(entry.get("material", "paper")))
		var obj := BurnableObject.new()
		obj.material_def = mat
		var size_arr: Array = entry.get("size", [mat.default_size.x, mat.default_size.y])
		obj.object_size = Vector2(float(size_arr[0]), float(size_arr[1]))
		obj.burn_weight = maxf(obj.object_size.x * obj.object_size.y, 1.0)
		var pos_arr: Array = entry.get("position", [0, 0])
		obj.position = Vector2(float(pos_arr[0]), float(pos_arr[1]))
		obj.name = String(entry.get("id", "burnable"))
		obj.counts_for_score = bool(entry.get("scoring", true))
		objects.append(obj)

	var fire := FireManager.new()
	fire.set_objects(objects)
	var target: BurnableObject = null
	for obj in objects:
		if obj.name == object_id:
			target = obj
			break
	if target == null:
		return {"percent": 0.0, "fully": false}
	fire.request_player_ignite(target)
	var dt := 1.0 / 60.0
	for i in int(40.0 / dt):
		fire.tick(dt)
		if fire.is_fully_burned():
			break
		if fire.has_started() and not _active(objects):
			break
	return {"percent": fire.get_burn_percent(), "fully": fire.is_fully_burned()}


func _active(objects: Array[BurnableObject]) -> bool:
	for obj in objects:
		if obj.state in [BurnableObject.State.IGNITING, BurnableObject.State.BURNING, BurnableObject.State.CHARRED]:
			return true
	return false
