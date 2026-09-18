extends SceneTree
func _init() -> void:
	var gen := LevelGenerator.new()
	var solver := LevelSolver.new()
	var validator := LevelValidator.new()
	var reasons := {}
	for i in 20:
		for arch in ["CLIMB","CHAIN","TRAP","BRIDGE","FORK"]:
			var p := gen.make_params(1000+i, arch)
			p.solution_policy = "UNIQUE"
			var lvl := gen.generate(p).to_level_dict()
			var r := solver.solve(lvl)
			var v := validator.validate(lvl, r, {"solution_policy":"UNIQUE","accept_limited_fallback":true,"min_chain":4})
			var key := String(v.get("message","ok")) if not bool(v.get("ok",false)) else "OK sols=%d" % int(r.get("solution_count",0))
			reasons[key] = int(reasons.get(key,0))+1
			if bool(v.get("ok",false)) and int(reasons.get("_examples",0)) < 3:
				print("OK_EXAMPLE arch=", arch, " seed=", 1000+i, " sols=", r.get("solution_count"), " chain=", r.get("best_chain_length"), " policy=", v.get("effective_policy"))
				reasons["_examples"] = int(reasons.get("_examples",0))+1
	print("REASONS ", JSON.stringify(reasons))
	quit()
