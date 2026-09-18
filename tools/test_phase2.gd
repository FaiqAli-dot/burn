extends SceneTree
## Phase 2 smoke: materials load, oil explodes, teaching levels solve.
## godot --headless --path . -s res://tools/test_phase2.gd


func _init() -> void:
	var fails: PackedStringArray = PackedStringArray()

	for mid in ["grass", "fabric", "oil", "plastic", "metal", "glass"]:
		var mat := LevelLoader.get_material(mid)
		if mat == null:
			fails.append("missing material %s" % mid)

	var oil := LevelLoader.get_material("oil")
	if oil and not oil.explodes:
		fails.append("oil should explode")
	var metal := LevelLoader.get_material("metal")
	if metal and metal.is_flammable:
		fails.append("metal should not be flammable")

	## Oil explosion path on p2_explosion
	var solver := LevelSolver.new()
	var blast := solver.solve_path("res://resources/levels/phase2/p2_explosion.json")
	if int(blast.get("solution_count", 0)) < 1:
		fails.append("p2_explosion should have a solution")

	var teach := solver.solve_path("res://resources/levels/teaching/teach_01.json")
	if int(teach.get("solution_count", 0)) < 1:
		fails.append("teach_01 should solve")

	## Deterministic explosion: same start twice → same percent
	var data := LevelLoader.load_level_dict("res://resources/levels/phase2/p2_oil.json")
	var a := LevelSimHarness.run_ignition(data, "s")
	var b := LevelSimHarness.run_ignition(data, "s")
	if absf(float(a.get("burn_percent", 0)) - float(b.get("burn_percent", 0))) > 0.01:
		fails.append("oil ignition not deterministic")

	if fails.is_empty():
		print("TEST_PHASE2_OK")
		quit(0)
	else:
		for f in fails:
			printerr("FAIL %s" % f)
		print("TEST_PHASE2_FAIL count=%d" % fails.size())
		quit(1)
