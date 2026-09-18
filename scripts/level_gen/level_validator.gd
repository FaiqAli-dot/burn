class_name LevelValidator
extends RefCounted
## Rejects impossible / trivial / broken / policy-mismatched candidates.
## Solvability comes from LevelSolver (real sim) — never from intended graphs.

enum RejectReason {
	OK,
	EMPTY,
	TOO_SMALL,
	TOO_LARGE,
	NO_SOLUTION,
	TRIVIAL,
	SHORT_CHAIN,
	DISCONNECTED,
	OVERLAP,
	OUT_OF_BOUNDS,
	POLICY_MISMATCH,
	DUPLICATE,
	UNSTABLE,
	BORING,
}


func validate(level_data: Dictionary, solve_report: Dictionary, params: Dictionary = {}) -> Dictionary:
	var policy := String(params.get("solution_policy", "UNIQUE"))
	var min_objects := int(params.get("min_objects", 6))
	var max_objects := int(params.get("max_objects", 28))
	var min_chain := int(params.get("min_chain", 5))
	var min_scoring := int(params.get("min_scoring", 5))

	var objects: Array = level_data.get("objects", [])
	if objects.is_empty():
		return _reject(RejectReason.EMPTY, "no objects")

	var scoring := 0
	for o in objects:
		if bool(o.get("scoring", true)):
			scoring += 1
	if objects.size() < min_objects or scoring < min_scoring:
		return _reject(RejectReason.TOO_SMALL, "too few objects")
	if objects.size() > max_objects:
		return _reject(RejectReason.TOO_LARGE, "too many objects")

	var bounds := _bounds_check(objects)
	if not bool(bounds.get("ok", false)):
		return _reject(RejectReason.OUT_OF_BOUNDS, String(bounds.get("msg", "oob")))

	var overlap := _overlap_check(objects)
	if not bool(overlap.get("ok", false)):
		return _reject(RejectReason.OVERLAP, String(overlap.get("msg", "overlap")))

	var solution_count := int(solve_report.get("solution_count", 0))
	if solution_count < 1:
		return _reject(RejectReason.NO_SOLUTION, "impossible")

	if solution_count == objects.size() and scoring <= 4:
		return _reject(RejectReason.TRIVIAL, "everything solves")

	var best_chain := int(solve_report.get("best_chain_length", 0))
	if best_chain < min_chain:
		return _reject(RejectReason.SHORT_CHAIN, "chain too short (%d)" % best_chain)

	## Policy: UNIQUE=1, LIMITED=2–3, OPEN=4+.
	## Prefer UNIQUE; cascade to LIMITED/OPEN when fallbacks enabled (real fire is bidirectional).
	var policy_ok := false
	var effective := policy
	match policy:
		"UNIQUE":
			if solution_count == 1:
				policy_ok = true
				effective = "UNIQUE"
			elif bool(params.get("accept_limited_fallback", true)) and solution_count >= 2 and solution_count <= 3:
				policy_ok = true
				effective = "LIMITED"
			elif bool(params.get("accept_open_fallback", true)) and solution_count >= 4:
				policy_ok = true
				effective = "OPEN"
		"LIMITED":
			if solution_count >= 2 and solution_count <= 3:
				policy_ok = true
				effective = "LIMITED"
			elif bool(params.get("accept_open_fallback", true)) and solution_count >= 4:
				policy_ok = true
				effective = "OPEN"
			elif solution_count == 1 and bool(params.get("accept_unique_as_limited", true)):
				policy_ok = true
				effective = "UNIQUE"
		"OPEN":
			policy_ok = solution_count >= 1
			effective = "OPEN" if solution_count >= 4 else ("LIMITED" if solution_count >= 2 else "UNIQUE")
		_:
			policy_ok = solution_count >= 1
			effective = policy
	if not policy_ok:
		return _reject(RejectReason.POLICY_MISMATCH, "solutions=%d policy=%s" % [solution_count, policy])
	policy = effective

	## Boring only when OPEN and virtually every scoring start wins with no trap texture.
	var next_best := float(solve_report.get("next_best_percent", 0.0))
	if effective == "OPEN" and solution_count >= scoring and scoring > 10 and next_best >= 99.0:
		## Still accept OPEN climb-likes; mark message but do not reject — bidirectional
		## fire makes this common. DifficultyAnalyzer downranks via solutions feature.
		pass
	## Disconnected scoring: if some scoring objects never appear in any successful ignition_order.
	if not _scoring_reachable(level_data, solve_report):
		return _reject(RejectReason.DISCONNECTED, "scoring objects unreachable in solutions")

	return {
		"ok": true,
		"reason": RejectReason.OK,
		"message": "valid",
		"effective_policy": policy,
	}


func _reject(reason: int, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message, "effective_policy": ""}


func _bounds_check(objects: Array) -> Dictionary:
	for o in objects:
		var p: Array = o.get("position", [0, 0])
		var s: Array = o.get("size", [40, 40])
		var x := float(p[0])
		var y := float(p[1])
		var hx := float(s[0]) * 0.5
		var hy := float(s[1]) * 0.5
		if x - hx < 40.0 or x + hx > 680.0 or y - hy < 40.0 or y + hy > 1240.0:
			return {"ok": false, "msg": "object %s out of bounds" % String(o.get("id", "?"))}
	return {"ok": true, "msg": ""}


func _overlap_check(objects: Array) -> Dictionary:
	for i in objects.size():
		var a: Dictionary = objects[i]
		var pa: Array = a.get("position", [0, 0])
		var sa: Array = a.get("size", [40, 40])
		var ra := Rect2(
			Vector2(float(pa[0]), float(pa[1])) - Vector2(float(sa[0]), float(sa[1])) * 0.5,
			Vector2(float(sa[0]), float(sa[1]))
		)
		## Shrink slightly — light visual overlap of decoys OK; heavy overlap not.
		ra = ra.grow(-4.0)
		for j in range(i + 1, objects.size()):
			var b: Dictionary = objects[j]
			var pb: Array = b.get("position", [0, 0])
			var sb: Array = b.get("size", [40, 40])
			var rb := Rect2(
				Vector2(float(pb[0]), float(pb[1])) - Vector2(float(sb[0]), float(sb[1])) * 0.5,
				Vector2(float(sb[0]), float(sb[1]))
			).grow(-4.0)
			if ra.intersects(rb):
				## Allow decoy-decoy soft touches.
				var a_decoy := String(a.get("id", "")).begins_with("decoy")
				var b_decoy := String(b.get("id", "")).begins_with("decoy")
				if a_decoy and b_decoy:
					continue
				return {"ok": false, "msg": "overlap %s/%s" % [String(a.get("id", "?")), String(b.get("id", "?"))]}
	return {"ok": true, "msg": ""}


func _scoring_reachable(level_data: Dictionary, solve_report: Dictionary) -> bool:
	var scoring_ids: Dictionary = {}
	for o in level_data.get("objects", []):
		if bool(o.get("scoring", true)):
			scoring_ids[String(o.get("id", ""))] = true
	if scoring_ids.is_empty():
		return false
	var seen: Dictionary = {}
	for s in solve_report.get("starts", []):
		if not bool(s.get("success", false)):
			continue
		for oid in s.get("ignition_order", []):
			seen[String(oid)] = true
	for sid in scoring_ids.keys():
		if not seen.has(sid):
			return false
	return true
