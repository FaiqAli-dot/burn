class_name LevelGenPipeline
extends RefCounted
## LevelGenerator → Solver → Validator → Difficulty → DuplicateCheck → save JSON.

signal candidate_processed(index: int, accepted: bool, message: String)

var generator := LevelGenerator.new()
var solver := LevelSolver.new()
var validator := LevelValidator.new()
var difficulty := DifficultyAnalyzer.new()
var duplicates := DuplicateCheck.new()
var catalog := LevelCatalog.new()

var accept_limited_fallback: bool = true
var accept_open_fallback: bool = true
var debug: bool = false


func process_candidate(params: LevelGenerator.GenParams, output_dir: String, file_index: int) -> Dictionary:
	var candidate := generator.generate(params)
	var level := candidate.to_level_dict()
	var solve_report := solver.solve(level)
	if debug:
		print(solver.format_debug(solve_report))

	var vparams := {
		"solution_policy": params.solution_policy,
		"accept_limited_fallback": accept_limited_fallback,
		"accept_open_fallback": accept_open_fallback,
		"min_chain": maxi(5, params.required_chain_length - 3),
	}
	var validation := validator.validate(level, solve_report, vparams)
	if not bool(validation.get("ok", false)):
		return {
			"accepted": false,
			"reason": String(validation.get("message", "reject")),
			"level": level,
			"solve": solve_report,
			"validation": validation,
		}

	if duplicates.is_duplicate(level):
		return {
			"accepted": false,
			"reason": "duplicate",
			"level": level,
			"solve": solve_report,
			"validation": validation,
		}

	var diff := difficulty.analyze(level, solve_report)
	## Optional difficulty band filter via params.difficulty_target ± window handled by caller.

	var effective_policy := String(validation.get("effective_policy", params.solution_policy))
	if typeof(level.get("generator", null)) == TYPE_DICTIONARY:
		level["generator"]["solution_policy"] = effective_policy
		level["generator"]["difficulty"] = float(diff.get("difficulty", 0.0))
		level["generator"]["difficulty_band"] = String(diff.get("band", ""))
		level["generator"]["trap_strength"] = String(diff.get("trap_strength", ""))
		level["generator"]["solution_count"] = int(solve_report.get("solution_count", 0))
		level["generator"]["solutions"] = solve_report.get("solutions", [])
		level["generator"]["signature"] = duplicates.signature(level)

	var fname := "burn_%06d.json" % file_index
	var path := "%s/%s" % [output_dir, fname]
	_save_level(path, level)
	duplicates.register(level)
	catalog.add(level, diff, solve_report, path)

	return {
		"accepted": true,
		"reason": "ok",
		"path": path,
		"level": level,
		"solve": solve_report,
		"validation": validation,
		"difficulty": diff,
	}


func _save_level(path: String, level: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % path)
		return
	file.store_string(JSON.stringify(level, "\t"))
