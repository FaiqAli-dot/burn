class_name FireManager
extends Node
## Pure gameplay fire simulation. Does not spawn particles or read shaders.
## Heat spreads by distance × material heat_output × target flammability.
## Explosion heat bursts are queued from MaterialDefinition.explodes (deterministic).

signal simulation_settled
signal burn_progress_changed(percent: float)
signal explosion_occurred(origin: Vector2, radius: float, heat: float)
signal chain_ignition(count: int)

var _objects: Array[BurnableObject] = []
var _active: bool = false
var _has_started: bool = false
var _settled_emitted: bool = false
var _pending_bursts: Array = [] ## {pos, radius, heat, falloff}
var _ignition_count: int = 0


func set_objects(objects: Array[BurnableObject]) -> void:
	_objects = objects
	_active = true
	_has_started = false
	_settled_emitted = false
	_pending_bursts.clear()
	_ignition_count = 0
	for obj in _objects:
		if not obj.ignited.is_connected(_on_object_ignited):
			obj.ignited.connect(_on_object_ignited)
		if not obj.destroyed.is_connected(_on_object_destroyed):
			obj.destroyed.connect(_on_object_destroyed.bind(obj))
		if not obj.explosion_triggered.is_connected(_on_explosion_triggered):
			obj.explosion_triggered.connect(_on_explosion_triggered)


func clear() -> void:
	_objects.clear()
	_active = false
	_has_started = false
	_settled_emitted = false
	_pending_bursts.clear()
	_ignition_count = 0


func has_started() -> bool:
	return _has_started


func get_ignition_count() -> int:
	return _ignition_count


func request_player_ignite(target: BurnableObject) -> bool:
	if not _active or _has_started:
		return false
	if target == null or target not in _objects:
		return false
	return target.try_player_ignite()


func _on_object_ignited(_by_player: bool) -> void:
	_has_started = true
	_ignition_count += 1
	chain_ignition.emit(_ignition_count)
	_emit_progress()


func _on_object_destroyed(_obj: BurnableObject) -> void:
	_emit_progress()


func _on_explosion_triggered(origin: BurnableObject, radius: float, heat: float, falloff_power: float) -> void:
	_pending_bursts.append({
		"pos": origin.global_position,
		"radius": radius,
		"heat": heat,
		"falloff": falloff_power,
		"source": origin,
	})
	explosion_occurred.emit(origin.global_position, radius, heat)


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not _active or _objects.is_empty():
		return

	## 0) Deterministic explosion heat bursts (instantaneous, before continuous radiators).
	_apply_pending_bursts()

	## 1) Radiators push heat into neighbors (AABB edge gap — no teleports).
	for src in _objects:
		if not is_instance_valid(src) or not src.is_radiating():
			continue
		var output := src.get_radiated_heat_output()
		if output <= 0.0:
			continue
		var max_r := src.get_heat_radius()
		for dst in _objects:
			if dst == src or not is_instance_valid(dst) or not dst.can_receive_heat():
				continue
			var gap := src.edge_gap_to(dst)
			if gap > max_r:
				continue
			var falloff := 1.0 - (gap / max_r)
			## Mild curve: local and readable, but still bridges short gaps.
			falloff = pow(falloff, 1.15)
			var transfer := output * falloff * dst.material_def.flammability * delta
			dst.add_heat(transfer)

	## 2) Advance per-object timers / state machines.
	for obj in _objects:
		if is_instance_valid(obj):
			obj.simulation_tick(delta)

	_emit_progress()

	if _has_started and not _settled_emitted and not _any_fire_activity():
		_settled_emitted = true
		simulation_settled.emit()


func _apply_pending_bursts() -> void:
	if _pending_bursts.is_empty():
		return
	var bursts := _pending_bursts.duplicate()
	_pending_bursts.clear()
	for burst in bursts:
		var pos: Vector2 = burst["pos"]
		var radius: float = float(burst["radius"])
		var heat: float = float(burst["heat"])
		var power: float = float(burst["falloff"])
		var source = burst.get("source", null)
		for dst in _objects:
			if not is_instance_valid(dst) or not dst.can_receive_heat():
				continue
			if source != null and dst == source:
				continue
			## Use center distance for burst (explosion is radial from origin).
			var dist := pos.distance_to(dst.global_position) - dst.get_half_extents().length() * 0.35
			dist = maxf(dist, 0.0)
			if dist > radius:
				continue
			var falloff := 1.0 - (dist / radius)
			falloff = pow(falloff, power)
			var transfer := heat * falloff * dst.material_def.flammability
			dst.add_heat(transfer)


func _any_fire_activity() -> bool:
	## HEATING alone does not keep the sim alive — without radiators, the chain stalled.
	if not _pending_bursts.is_empty():
		return true
	for obj in _objects:
		if not is_instance_valid(obj):
			continue
		if obj.state in [
			BurnableObject.State.IGNITING,
			BurnableObject.State.BURNING,
			BurnableObject.State.CHARRED,
		]:
			return true
	return false


func get_burn_percent() -> float:
	if _objects.is_empty():
		return 0.0
	var total := 0.0
	var done := 0.0
	for obj in _objects:
		if not is_instance_valid(obj) or not obj.contributes_to_burn_goal():
			continue
		total += obj.burn_weight
		done += obj.get_progress_contribution()
	if total <= 0.0:
		return 0.0
	return clampf((done / total) * 100.0, 0.0, 100.0)


func _emit_progress() -> void:
	burn_progress_changed.emit(get_burn_percent())


func is_fully_burned() -> bool:
	## Win when every flammable scoring object has finished (DESTROYED).
	var any_goal := false
	for obj in _objects:
		if not is_instance_valid(obj) or not obj.contributes_to_burn_goal():
			continue
		any_goal = true
		if obj.state != BurnableObject.State.DESTROYED:
			return false
	return any_goal
