class_name LevelGenerator
extends RefCounted
## Constructive procedural level factory.
## Builds an intended graph → places objects → decoys → spatial jitter,
## then callers verify with LevelSolver (real FireManager). Never fakes solvability.

const GENERATOR_VERSION := "1.0.0"
const GRID := 40.0
const PLAY_LEFT := 100.0
const PLAY_RIGHT := 620.0
const PLAY_TOP := 90.0
const PLAY_BOTTOM := 1100.0

const ARCHETYPES := ["CLIMB", "CHAIN", "TRAP", "BRIDGE", "FORK"]
const POLICIES := ["UNIQUE", "LIMITED", "OPEN"]


class GenParams:
	var seed_value: int = 1
	var archetype: String = "CLIMB"
	var object_count: int = 14
	var required_chain_length: int = 8
	var decoy_count: int = 2
	var difficulty_target: float = 40.0
	var solution_count: int = 1 ## preferred UNIQUE
	var material_complexity: float = 0.55 ## 0=paper-heavy, 1=more wood
	var spatial_complexity: float = 0.4
	var solution_policy: String = "UNIQUE"


func make_params(seed_value: int = 1, archetype: String = "CLIMB") -> GenParams:
	var p := GenParams.new()
	p.seed_value = seed_value
	p.archetype = archetype.to_upper()
	return p


func generate(params: GenParams) -> LevelCandidate:
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix_seed(params.seed_value, params.archetype)

	var candidate := LevelCandidate.new()
	candidate.seed_value = params.seed_value
	candidate.archetype = params.archetype
	candidate.solution_policy = params.solution_policy
	candidate.generator_version = GENERATOR_VERSION

	var objects: Array = []
	match params.archetype:
		"CLIMB":
			objects = _gen_climb(rng, params)
		"CHAIN":
			objects = _gen_chain(rng, params)
		"TRAP":
			objects = _gen_trap(rng, params)
		"BRIDGE":
			objects = _gen_bridge(rng, params)
		"FORK":
			objects = _gen_fork(rng, params)
		_:
			objects = _gen_climb(rng, params)

	## Spatial variation on ~40px grid (deterministic jitter).
	_apply_spatial_variation(objects, rng, params.spatial_complexity)
	_clamp_to_playfield(objects)

	var intended := "sol_0"
	if objects.size() > 0:
		intended = String(objects[0].get("id", "sol_0"))
	candidate.intended_solution_id = intended

	var display := "%s-%d" % [params.archetype, params.seed_value]
	candidate.data = {
		"id": "burn_gen_%s_%d" % [params.archetype.to_lower(), params.seed_value],
		"display_name": display,
		"hint": _hint_for(params.archetype),
		"generator": {
			"version": GENERATOR_VERSION,
			"seed": params.seed_value,
			"archetype": params.archetype,
			"solution_policy": params.solution_policy,
			"intended_solution": intended,
			"difficulty_target": params.difficulty_target,
		},
		"objects": objects,
	}
	return candidate


func _mix_seed(seed_value: int, archetype: String) -> int:
	## Stable mix: same seed + archetype + generator_version → same RNG stream.
	var s := "%s|%s|%d" % [GENERATOR_VERSION, archetype.to_upper(), seed_value]
	return hash(s)


func _hint_for(archetype: String) -> String:
	match archetype:
		"CLIMB":
			return "Start low. Climb the fuse."
		"CHAIN":
			return "One path. Keep it fed."
		"TRAP":
			return "Looks hot. Isn't."
		"BRIDGE":
			return "Cross the beam."
		"FORK":
			return "Pick the branch that feeds both."
		_:
			return "Burn 100%."


func _paper_size(rng: RandomNumberGenerator) -> Vector2:
	var s := 44.0 + rng.randf() * 12.0
	return Vector2(s, s * (0.85 + rng.randf() * 0.25))


func _wood_beam_size(rng: RandomNumberGenerator, wide: bool = true) -> Vector2:
	if wide:
		return Vector2(180.0 + rng.randf() * 100.0, 34.0 + rng.randf() * 8.0)
	return Vector2(40.0 + rng.randf() * 10.0, 100.0 + rng.randf() * 40.0)


func _obj(id: String, material: String, pos: Vector2, size: Vector2, rot: float, scoring: bool = true) -> Dictionary:
	return {
		"id": id,
		"material": material,
		"position": [snapped(pos.x, 0.1), snapped(pos.y, 0.1)],
		"size": [snapped(size.x, 0.1), snapped(size.y, 0.1)],
		"rotation_deg": snapped(rot, 0.1),
		"scoring": scoring,
	}


func _snap(v: float) -> float:
	return round(v / GRID) * GRID


## --- Archetypes -----------------------------------------------------------

func _gen_climb(rng: RandomNumberGenerator, params: GenParams) -> Array:
	## Vertical fuse: bottom paper start → paper cluster → wood gate → climb.
	## Wood gates spaced so ≥2 papers below are required (UNIQUE-leaning).
	var objects: Array = []
	var cx := 360.0
	var y := PLAY_BOTTOM - 20.0
	var idx := 0

	## Solution start
	objects.append(_obj("sol_0", "paper", Vector2(cx, y), _paper_size(rng), rng.randf_range(-8, 8)))
	idx += 1
	y -= 90.0

	## Twin papers
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx - 80, y), _paper_size(rng), rng.randf_range(-10, 10)))
	idx += 1
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx + 80, y), _paper_size(rng), rng.randf_range(-10, 10)))
	idx += 1
	y -= 95.0

	## Triple under beam (co-heat wood)
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx - 110, y), _paper_size(rng), rng.randf_range(-6, 6)))
	idx += 1
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx, y - 10), _paper_size(rng), 0.0))
	idx += 1
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx + 110, y), _paper_size(rng), rng.randf_range(-6, 6)))
	idx += 1
	y -= 100.0

	## Wood beam gate
	objects.append(_obj("sol_%d" % idx, "wood", Vector2(cx, y), _wood_beam_size(rng, true), 0.0))
	idx += 1
	y -= 110.0

	## Papers above beam
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx - 90, y), _paper_size(rng), rng.randf_range(-12, 12)))
	idx += 1
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx + 90, y), _paper_size(rng), rng.randf_range(-12, 12)))
	idx += 1
	y -= 90.0

	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx, y), _paper_size(rng), rng.randf_range(-5, 5)))
	idx += 1
	y -= 100.0

	## Wood post
	objects.append(_obj("sol_%d" % idx, "wood", Vector2(cx, y), _wood_beam_size(rng, false), 0.0))
	idx += 1
	y -= 120.0

	## Top cluster
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx - 80, y), _paper_size(rng), rng.randf_range(-8, 8)))
	idx += 1
	objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx + 80, y), _paper_size(rng), rng.randf_range(-8, 8)))
	idx += 1
	y -= 85.0

	if params.material_complexity > 0.35:
		objects.append(_obj("sol_%d" % idx, "wood", Vector2(cx, y), Vector2(240 + rng.randf() * 60, 32), 0.0))
		idx += 1
		y -= 70.0
		objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx - 100, y), _paper_size(rng), 2.0))
		idx += 1
		objects.append(_obj("sol_%d" % idx, "paper", Vector2(cx + 100, y), _paper_size(rng), -2.0))
		idx += 1

	_add_decoys(objects, rng, params.decoy_count, true)
	return objects


func _gen_chain(rng: RandomNumberGenerator, params: GenParams) -> Array:
	## Diagonal paper chain with one wood link mid-way.
	var objects: Array = []
	var x := 160.0
	var y := PLAY_BOTTOM - 40.0
	var n := clampi(params.object_count - params.decoy_count, 8, 16)
	for i in n:
		var mat := "paper"
		var size := _paper_size(rng)
		if i == int(n * 0.45) or (params.material_complexity > 0.5 and i == int(n * 0.7)):
			mat = "wood"
			size = Vector2(70 + rng.randf() * 40, 36 + rng.randf() * 8)
		## Keep edge gaps paper-reachable (~45–70px).
		var step := 70.0 + rng.randf() * 18.0
		if i == 0:
			objects.append(_obj("sol_0", mat, Vector2(x, y), size, rng.randf_range(-10, 10)))
		else:
			x += step * 0.55
			y -= step * 0.75
			objects.append(_obj("sol_%d" % i, mat, Vector2(x, y), size, rng.randf_range(-12, 12)))
	_add_decoys(objects, rng, params.decoy_count, false)
	return objects


func _gen_trap(rng: RandomNumberGenerator, params: GenParams) -> Array:
	## Real climb chain + a tempting near-miss side cluster that looks connected.
	var objects := _gen_climb(rng, params)
	## Remove default decoys and place a near-miss trap cluster beside the beam.
	var filtered: Array = []
	for o in objects:
		if not String(o.get("id", "")).begins_with("decoy"):
			filtered.append(o)
	objects = filtered

	## Near-miss: papers close enough to heat but not co-ignite the main beam alone.
	var trap_y := 740.0 + rng.randf_range(-20, 20)
	objects.append(_obj("trap_a", "paper", Vector2(600, trap_y), _paper_size(rng), -14.0, true))
	objects.append(_obj("trap_b", "paper", Vector2(640, trap_y - 70), _paper_size(rng), 10.0, true))
	objects.append(_obj("trap_wood", "wood", Vector2(655, trap_y - 150), Vector2(50, 50), 16.0, true))
	## True decoys in far corner (non-scoring).
	_add_decoys(objects, rng, maxi(1, params.decoy_count - 1), true)
	return objects


func _gen_bridge(rng: RandomNumberGenerator, params: GenParams) -> Array:
	## Two islands connected by a wood beam the player must feed from the correct side.
	var objects: Array = []
	var y_left := 900.0
	## Left island (solution side)
	objects.append(_obj("sol_0", "paper", Vector2(180, y_left), _paper_size(rng), -6.0))
	objects.append(_obj("sol_1", "paper", Vector2(160, y_left - 85), _paper_size(rng), 8.0))
	objects.append(_obj("sol_2", "paper", Vector2(220, y_left - 85), _paper_size(rng), -8.0))
	objects.append(_obj("sol_3", "paper", Vector2(190, y_left - 160), _paper_size(rng), 0.0))
	## Bridge beam
	objects.append(_obj("sol_4", "wood", Vector2(360, y_left - 200), Vector2(280 + rng.randf() * 40, 36), 0.0))
	## Right island (continuation)
	objects.append(_obj("sol_5", "paper", Vector2(520, y_left - 260), _paper_size(rng), 6.0))
	objects.append(_obj("sol_6", "paper", Vector2(560, y_left - 340), _paper_size(rng), -4.0))
	objects.append(_obj("sol_7", "paper", Vector2(500, y_left - 340), _paper_size(rng), 4.0))
	if params.material_complexity > 0.4:
		objects.append(_obj("sol_8", "wood", Vector2(530, y_left - 430), Vector2(44, 110), 0.0))
		objects.append(_obj("sol_9", "paper", Vector2(500, y_left - 530), _paper_size(rng), -5.0))
		objects.append(_obj("sol_10", "paper", Vector2(560, y_left - 530), _paper_size(rng), 5.0))
	_add_decoys(objects, rng, params.decoy_count, true)
	return objects


func _gen_fork(rng: RandomNumberGenerator, params: GenParams) -> Array:
	## Shared start feeds two branches that both must burn (connected at crown).
	var objects: Array = []
	var cx := 360.0
	var y := PLAY_BOTTOM - 30.0
	objects.append(_obj("sol_0", "paper", Vector2(cx, y), _paper_size(rng), 0.0))
	y -= 90.0
	objects.append(_obj("sol_1", "paper", Vector2(cx - 50, y), _paper_size(rng), 5.0))
	objects.append(_obj("sol_2", "paper", Vector2(cx + 50, y), _paper_size(rng), -5.0))
	y -= 100.0
	## Left branch
	objects.append(_obj("sol_3", "paper", Vector2(cx - 140, y), _paper_size(rng), 8.0))
	objects.append(_obj("sol_4", "paper", Vector2(cx - 160, y - 90), _paper_size(rng), -6.0))
	objects.append(_obj("sol_5", "wood", Vector2(cx - 150, y - 180), Vector2(48, 100), 0.0))
	objects.append(_obj("sol_6", "paper", Vector2(cx - 150, y - 280), _paper_size(rng), 4.0))
	## Right branch
	objects.append(_obj("sol_7", "paper", Vector2(cx + 140, y), _paper_size(rng), -8.0))
	objects.append(_obj("sol_8", "paper", Vector2(cx + 160, y - 90), _paper_size(rng), 6.0))
	objects.append(_obj("sol_9", "wood", Vector2(cx + 150, y - 180), Vector2(48, 100), 0.0))
	objects.append(_obj("sol_10", "paper", Vector2(cx + 150, y - 280), _paper_size(rng), -4.0))
	## Merge crown
	objects.append(_obj("sol_11", "wood", Vector2(cx, y - 340), Vector2(300, 34), 0.0))
	objects.append(_obj("sol_12", "paper", Vector2(cx - 90, y - 410), _paper_size(rng), 2.0))
	objects.append(_obj("sol_13", "paper", Vector2(cx + 90, y - 410), _paper_size(rng), -2.0))
	_add_decoys(objects, rng, params.decoy_count, true)
	return objects


func _add_decoys(objects: Array, rng: RandomNumberGenerator, count: int, corners: bool) -> void:
	for i in count:
		var pos: Vector2
		if corners:
			if i % 2 == 0:
				pos = Vector2(78 + rng.randf() * 16, PLAY_BOTTOM - 20 - rng.randf() * 30)
			else:
				pos = Vector2(642 - rng.randf() * 16, PLAY_BOTTOM - 10 - rng.randf() * 40)
		else:
			pos = Vector2(
				rng.randf_range(PLAY_LEFT, PLAY_RIGHT),
				rng.randf_range(PLAY_TOP + 40, PLAY_BOTTOM - 80)
			)
		var mat := "wood" if i == 0 else "paper"
		var size := Vector2(52, 52) if mat == "wood" else _paper_size(rng)
		for _attempt in 12:
			if not _overlaps_any(pos, size, objects, 36.0):
				break
			if corners:
				pos.y = clampf(pos.y - 40.0, PLAY_TOP, PLAY_BOTTOM)
				pos.x = clampf(pos.x + rng.randf_range(-20, 20), PLAY_LEFT, PLAY_RIGHT)
			else:
				pos.x = clampf(pos.x + rng.randf_range(-100, 100), PLAY_LEFT, PLAY_RIGHT)
				pos.y = clampf(pos.y + rng.randf_range(-100, 100), PLAY_TOP, PLAY_BOTTOM)
		if _overlaps_any(pos, size, objects, 24.0):
			continue ## skip decoy rather than overlap scoring props
		objects.append(_obj("decoy_%d" % i, mat, pos, size, rng.randf_range(-18, 18), false))


func _overlaps_any(pos: Vector2, size: Vector2, objects: Array, pad: float) -> bool:
	var a := Rect2(pos - size * 0.5 - Vector2(pad, pad), size + Vector2(pad, pad) * 2.0)
	for entry_variant in objects:
		var e: Dictionary = entry_variant
		var p: Array = e.get("position", [0, 0])
		var s: Array = e.get("size", [40, 40])
		var b := Rect2(
			Vector2(float(p[0]), float(p[1])) - Vector2(float(s[0]), float(s[1])) * 0.5,
			Vector2(float(s[0]), float(s[1]))
		)
		if a.intersects(b):
			return true
	return false


func _apply_spatial_variation(objects: Array, rng: RandomNumberGenerator, complexity: float) -> void:
	var amp := GRID * clampf(complexity, 0.0, 1.0) * 0.45
	for i in objects.size():
		var e: Dictionary = objects[i]
		if String(e.get("id", "")).begins_with("decoy"):
			continue
		## Keep sol_0 as anchor for intended start readability.
		if String(e.get("id", "")) == "sol_0":
			continue
		var p: Array = e["position"]
		var size_arr: Array = e.get("size", [40, 40])
		var size := Vector2(float(size_arr[0]), float(size_arr[1]))
		var jx := rng.randf_range(-amp, amp)
		var jy := rng.randf_range(-amp * 0.6, amp * 0.6)
		var candidate := Vector2(float(p[0]) + jx, float(p[1]) + jy)
		## Reject jitter that causes hard overlaps with other scoring props.
		var others: Array = []
		for j in objects.size():
			if j == i:
				continue
			others.append(objects[j])
		if not _overlaps_any(candidate, size, others, 8.0):
			e["position"] = [snapped(candidate.x, 0.1), snapped(candidate.y, 0.1)]
		e["rotation_deg"] = snapped(float(e.get("rotation_deg", 0.0)) + rng.randf_range(-3, 3) * complexity, 0.1)


func _clamp_to_playfield(objects: Array) -> void:
	for entry_variant in objects:
		var e: Dictionary = entry_variant
		var p: Array = e["position"]
		var s: Array = e.get("size", [40, 40])
		var half := Vector2(float(s[0]), float(s[1])) * 0.5
		var x := clampf(float(p[0]), PLAY_LEFT + half.x, PLAY_RIGHT - half.x)
		var y := clampf(float(p[1]), PLAY_TOP + half.y, PLAY_BOTTOM - half.y)
		e["position"] = [snapped(x, 0.1), snapped(y, 0.1)]
