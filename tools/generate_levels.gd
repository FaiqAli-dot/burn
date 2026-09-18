extends SceneTree
## Batch procedural level generation.
## godot --headless --path . -s res://tools/generate_levels.gd

const OUTPUT_DIR := "res://resources/levels/generated"
const REPORT_PATH := "res://resources/levels/generated/generation_report.json"
const CATALOG_PATH := "res://resources/levels/generated/catalog.json"

const CANDIDATES := 1000
const MAX_ACCEPT := 400
const BASE_SEED := 1000
const ARCHETYPES := ["CLIMB", "CHAIN", "TRAP", "BRIDGE", "FORK"]
const DIFF_LO := 0.0
const DIFF_HI := 100.0
const DEBUG := false


func _init() -> void:
	_ensure_dir(OUTPUT_DIR)
	var pipeline := LevelGenPipeline.new()
	pipeline.debug = DEBUG
	pipeline.duplicates.load_existing(OUTPUT_DIR)
	pipeline.catalog.clear()

	var accepted := 0
	var attempted := 0
	var reject_counts: Dictionary = {}
	var by_archetype: Dictionary = {}
	var t0 := Time.get_ticks_msec()
	var file_index := _next_file_index(OUTPUT_DIR)

	while attempted < CANDIDATES and accepted < MAX_ACCEPT:
		var archetype: String = ARCHETYPES[attempted % ARCHETYPES.size()]
		var params := pipeline.generator.make_params(BASE_SEED + attempted, archetype)
		params.solution_policy = "UNIQUE"
		params.decoy_count = 2 if archetype != "TRAP" else 3
		params.material_complexity = 0.4 + float(attempted % 5) * 0.1
		params.spatial_complexity = 0.25 + float(attempted % 4) * 0.1
		params.object_count = 12 + (attempted % 6)
		params.required_chain_length = 7

		## Generate + solve + validate first (no save yet).
		var candidate := pipeline.generator.generate(params)
		var level := candidate.to_level_dict()
		var solve_report := pipeline.solver.solve(level)
		var validation := pipeline.validator.validate(level, solve_report, {
			"solution_policy": params.solution_policy,
			"accept_limited_fallback": pipeline.accept_limited_fallback,
			"accept_open_fallback": pipeline.accept_open_fallback,
			"min_chain": maxi(5, params.required_chain_length - 3),
		})
		attempted += 1

		if not bool(validation.get("ok", false)):
			_bump(reject_counts, String(validation.get("message", "reject")))
			continue
		if pipeline.duplicates.is_duplicate(level):
			_bump(reject_counts, "duplicate")
			continue

		var diff := pipeline.difficulty.analyze(level, solve_report)
		var dscore := float(diff.get("difficulty", 0.0))
		if dscore < DIFF_LO or dscore > DIFF_HI:
			_bump(reject_counts, "difficulty_filter")
			continue

		var effective_policy := String(validation.get("effective_policy", params.solution_policy))
		if typeof(level.get("generator", null)) == TYPE_DICTIONARY:
			level["generator"]["solution_policy"] = effective_policy
			level["generator"]["difficulty"] = dscore
			level["generator"]["difficulty_band"] = String(diff.get("band", ""))
			level["generator"]["trap_strength"] = String(diff.get("trap_strength", ""))
			level["generator"]["solution_count"] = int(solve_report.get("solution_count", 0))
			level["generator"]["solutions"] = solve_report.get("solutions", [])
			level["generator"]["signature"] = pipeline.duplicates.signature(level)

		var fname := "burn_%06d.json" % file_index
		var path := "%s/%s" % [OUTPUT_DIR, fname]
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(level, "\t"))
		pipeline.duplicates.register(level)
		pipeline.catalog.add(level, diff, solve_report, path)
		accepted += 1
		file_index += 1
		_bump(by_archetype, archetype)
		if accepted % 25 == 0:
			print("PROGRESS accepted=%d attempted=%d" % [accepted, attempted])

	var elapsed_ms := Time.get_ticks_msec() - t0
	pipeline.catalog.save(CATALOG_PATH)

	var report := {
		"generator_version": LevelGenerator.GENERATOR_VERSION,
		"candidates": attempted,
		"accepted": accepted,
		"elapsed_ms": elapsed_ms,
		"accept_rate": snapped(float(accepted) / maxf(float(attempted), 1.0), 0.0001),
		"by_archetype": by_archetype,
		"reject_counts": reject_counts,
		"output_dir": OUTPUT_DIR,
		"base_seed": BASE_SEED,
		"max_accept": MAX_ACCEPT,
	}
	var rf := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if rf:
		rf.store_string(JSON.stringify(report, "\t"))

	print("BATCH_DONE attempted=%d accepted=%d rate=%.1f%% elapsed_ms=%d" % [
		attempted, accepted, report["accept_rate"] * 100.0, elapsed_ms
	])
	print("BATCH_REJECTS %s" % JSON.stringify(reject_counts))
	print("BATCH_ARCHETYPES %s" % JSON.stringify(by_archetype))
	quit(0 if accepted > 0 else 1)


func _bump(d: Dictionary, key: String) -> void:
	d[key] = int(d.get(key, 0)) + 1


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _next_file_index(dir_path: String) -> int:
	var da := DirAccess.open(dir_path)
	if da == null:
		return 1
	var max_idx := 0
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if fname.begins_with("burn_") and fname.ends_with(".json"):
			var num := fname.substr(5, 6)
			if num.is_valid_int():
				max_idx = maxi(max_idx, int(num))
		fname = da.get_next()
	da.list_dir_end()
	return max_idx + 1
