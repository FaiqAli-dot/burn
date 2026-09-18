class_name DifficultyAnalyzer
extends RefCounted
## Measurable 0–100 difficulty from solver + structure. Configurable weights.

var weights := {
	"chain": 0.22,
	"decoys": 0.12,
	"solutions": 0.20,
	"near_miss": 0.18,
	"branching": 0.10,
	"materials": 0.10,
	"spatial": 0.08,
}


func analyze(level_data: Dictionary, solve_report: Dictionary) -> Dictionary:
	var objects: Array = level_data.get("objects", [])
	var scoring := 0
	var decoys := 0
	var woods := 0
	var papers := 0
	for o in objects:
		var mat := String(o.get("material", "paper"))
		if mat == "wood":
			woods += 1
		else:
			papers += 1
		if bool(o.get("scoring", true)):
			scoring += 1
		else:
			decoys += 1

	var chain := float(solve_report.get("best_chain_length", 0))
	var sol_count := float(solve_report.get("solution_count", 0))
	var best := float(solve_report.get("best_percent", 0.0))
	var next_best := float(solve_report.get("next_best_percent", 0.0))
	var max_simul := float(solve_report.get("best_max_simultaneous", 0))

	## Normalize features to 0–1 then weight.
	var f_chain := clampf(chain / 18.0, 0.0, 1.0)
	var f_decoy := clampf(float(decoys) / 4.0, 0.0, 1.0)
	## Fewer solutions → harder.
	var f_sol := 0.0
	if sol_count <= 1.0:
		f_sol = 1.0
	elif sol_count <= 3.0:
		f_sol = 0.65
	elif sol_count <= 6.0:
		f_sol = 0.35
	else:
		f_sol = 0.1
	## Near-miss trap strength: high next_best under 100 is a strong trap.
	var f_near := 0.0
	if best >= 99.0 and next_best < 99.0:
		f_near = clampf(next_best / 100.0, 0.0, 1.0)
		## Medium near-miss (~40–70) scores highest trap feel.
		if next_best >= 35.0 and next_best <= 75.0:
			f_near = 1.0
		elif next_best < 15.0:
			f_near = 0.35
	var f_branch := clampf(max_simul / 6.0, 0.0, 1.0)
	var f_mat := clampf(float(woods) / maxf(float(scoring), 1.0), 0.0, 1.0)
	var f_spatial := clampf(_spatial_spread(objects) / 700.0, 0.0, 1.0)

	var score := 100.0 * (
		f_chain * float(weights["chain"])
		+ f_decoy * float(weights["decoys"])
		+ f_sol * float(weights["solutions"])
		+ f_near * float(weights["near_miss"])
		+ f_branch * float(weights["branching"])
		+ f_mat * float(weights["materials"])
		+ f_spatial * float(weights["spatial"])
	)
	score = clampf(score, 0.0, 100.0)

	var band := "easy"
	if score >= 66.0:
		band = "hard"
	elif score >= 33.0:
		band = "medium"

	var trap_band := "weak"
	if next_best >= 35.0 and next_best < 99.0:
		trap_band = "strong"
	elif next_best >= 15.0:
		trap_band = "medium"

	return {
		"difficulty": snapped(score, 0.1),
		"band": band,
		"trap_strength": trap_band,
		"features": {
			"chain": snapped(f_chain, 0.01),
			"decoys": snapped(f_decoy, 0.01),
			"solutions": snapped(f_sol, 0.01),
			"near_miss": snapped(f_near, 0.01),
			"branching": snapped(f_branch, 0.01),
			"materials": snapped(f_mat, 0.01),
			"spatial": snapped(f_spatial, 0.01),
		},
		"next_best_percent": next_best,
		"solution_count": int(sol_count),
	}


func _spatial_spread(objects: Array) -> float:
	if objects.is_empty():
		return 0.0
	var min_p := Vector2(9999, 9999)
	var max_p := Vector2(-9999, -9999)
	for o in objects:
		var p: Array = o.get("position", [0, 0])
		var v := Vector2(float(p[0]), float(p[1]))
		min_p.x = minf(min_p.x, v.x)
		min_p.y = minf(min_p.y, v.y)
		max_p.x = maxf(max_p.x, v.x)
		max_p.y = maxf(max_p.y, v.y)
	return min_p.distance_to(max_p)
