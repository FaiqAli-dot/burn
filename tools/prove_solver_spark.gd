extends SceneTree
## Prove LevelSolver against handcrafted SPARK using real FireManager.
## godot --headless --path . -s res://tools/prove_solver_spark.gd


func _init() -> void:
	var solver := LevelSolver.new()
	var report := solver.solve_path("res://resources/levels/level_01.json")
	print(solver.format_debug(report))

	var solutions: Array = report.get("solutions", [])
	var has_start_paper := "start_paper" in solutions
	var decoy_ok := true
	for s in report.get("starts", []):
		var oid := String(s.get("start_object", ""))
		if oid.begins_with("decoy"):
			if bool(s.get("success", false)) or float(s.get("burn_percent", 0.0)) > 5.0:
				printerr("FAIL: decoy %s progressed scoring (pct=%.1f)" % [oid, float(s.get("burn_percent", 0.0))])
				decoy_ok = false

	var all_ok := true
	if not has_start_paper:
		printerr("FAIL: start_paper must be a solution")
		all_ok = false
	if int(report.get("solution_count", 0)) < 1:
		printerr("FAIL: expected at least one solution")
		all_ok = false
	if not decoy_ok:
		all_ok = false

	if all_ok:
		print("PROVE_SOLVER_OK")
		quit(0)
	else:
		print("PROVE_SOLVER_FAIL")
		quit(1)
