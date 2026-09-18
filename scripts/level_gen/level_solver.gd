class_name LevelSolver
extends RefCounted
## Evaluates every legal starting object with the real fire simulation.
## Authoritative solvability — never invent success from intended graphs.

func solve(level_data: Dictionary) -> Dictionary:
	var objects: Array = level_data.get("objects", [])
	var starts: Array = []
	var solutions: Array = []
	var percents: Array = []

	for entry_variant in objects:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var oid := String(entry.get("id", ""))
		if oid.is_empty():
			continue
		var result := LevelSimHarness.run_ignition(level_data, oid)
		starts.append(result)
		percents.append(float(result.get("burn_percent", 0.0)))
		if bool(result.get("success", false)):
			solutions.append(oid)

	percents.sort()
	percents.reverse()
	var best := 0.0
	var next_best := 0.0
	if percents.size() > 0:
		best = float(percents[0])
	if percents.size() > 1:
		next_best = float(percents[1])
	elif percents.size() == 1:
		next_best = 0.0

	## Longest ignition chain among successful (or best) starts.
	var best_chain := 0
	var best_duration := 0.0
	var best_max_simul := 0
	for s in starts:
		best_chain = maxi(best_chain, int(s.get("chain_length", 0)))
		best_duration = maxf(best_duration, float(s.get("duration", 0.0)))
		best_max_simul = maxi(best_max_simul, int(s.get("max_simultaneous_burning", 0)))

	return {
		"starts": starts,
		"solutions": solutions,
		"solution_count": solutions.size(),
		"best_percent": best,
		"next_best_percent": next_best,
		"best_chain_length": best_chain,
		"best_duration": best_duration,
		"best_max_simultaneous": best_max_simul,
		"start_count": starts.size(),
	}


func solve_path(path: String) -> Dictionary:
	return solve(LevelLoader.load_level_dict(path))


func format_debug(report: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("SOLVER solutions=%d best=%.1f%% next=%.1f%%" % [
		int(report.get("solution_count", 0)),
		float(report.get("best_percent", 0.0)),
		float(report.get("next_best_percent", 0.0)),
	])
	for s in report.get("starts", []):
		lines.append("  %s success=%s pct=%.1f chain=%d dur=%.2f" % [
			String(s.get("start_object", "?")),
			str(s.get("success", false)),
			float(s.get("burn_percent", 0.0)),
			int(s.get("chain_length", 0)),
			float(s.get("duration", 0.0)),
		])
	return "\n".join(lines)
