class_name ParticleManager
extends Node
## Visual-only layered fire. Listens to BurnableObject / FireManager; never feeds sim.

const MAX_CORE := 18
const MAX_OUTER := 22
const MAX_EMBERS := 14
const MAX_SMOKE := 12

var _fx: Dictionary = {} ## BurnableObject -> {core, outer, embers, smoke}
var _chain_intensity: float = 1.0
var _fire: FireManager
var _world: Node2D
var _soft_tex: Texture2D
var _active_burn_count: int = 0


func bind_world(world: Node2D) -> void:
	_world = world


func bind_fire(fire: FireManager) -> void:
	_fire = fire
	if fire and not fire.chain_ignition.is_connected(_on_chain):
		fire.chain_ignition.connect(_on_chain)
	if fire and not fire.explosion_occurred.is_connected(_on_explosion_fx):
		fire.explosion_occurred.connect(_on_explosion_fx)


func bind_objects(objects: Array[BurnableObject]) -> void:
	clear()
	_chain_intensity = 1.0
	_active_burn_count = 0
	_soft_tex = SoftTextureFactory.soft_blob(20)
	for obj in objects:
		_ensure_layers(obj)
		if not obj.state_changed.is_connected(_on_state_changed):
			obj.state_changed.connect(_on_state_changed.bind(obj))
		if not obj.destroyed.is_connected(_on_destroyed):
			obj.destroyed.connect(_on_destroyed.bind(obj))


func clear() -> void:
	for key in _fx.keys():
		var pack: Dictionary = _fx[key]
		for k in pack.keys():
			var p: GPUParticles2D = pack[k]
			if is_instance_valid(p):
				p.queue_free()
	_fx.clear()
	_chain_intensity = 1.0
	_active_burn_count = 0


func get_ambient_fire_glow() -> float:
	return clampf(float(_active_burn_count) * 0.12 * _chain_intensity, 0.0, 1.2)


func _on_chain(count: int) -> void:
	_chain_intensity = clampf(1.0 + float(count) * 0.08, 1.0, 2.4)


func _ensure_layers(obj: BurnableObject) -> Dictionary:
	if _fx.has(obj):
		return _fx[obj]
	var pack := {
		"core": _make_particles(obj, "FlameCore", MAX_CORE, 0.4, 9, Color(1.0, 0.95, 0.7, 0.95), true),
		"outer": _make_particles(obj, "FlameOuter", MAX_OUTER, 0.55, 8, Color(1.0, 0.45, 0.12, 0.75), true),
		"embers": _make_particles(obj, "Embers", MAX_EMBERS, 0.85, 10, Color(1.0, 0.7, 0.25, 0.9), false),
		"smoke": _make_particles(obj, "Smoke", MAX_SMOKE, 1.2, 7, Color(0.25, 0.22, 0.2, 0.35), false),
	}
	_style_core(pack["core"], obj)
	_style_outer(pack["outer"], obj)
	_style_embers(pack["embers"], obj)
	_style_smoke(pack["smoke"], obj)
	_fx[obj] = pack
	return pack


func _make_particles(obj: BurnableObject, pname: String, amount: int, lifetime: float, z: int, _col: Color, _flame: bool) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = pname
	particles.z_index = z
	particles.emitting = false
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.05
	particles.randomness = 0.45
	particles.visibility_rect = Rect2(-120, -160, 240, 240)
	particles.texture = _soft_tex if _soft_tex else SoftTextureFactory.soft_blob(16)
	obj.add_child(particles)
	return particles


func _base_mat(obj: BurnableObject) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0, -1, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(obj.object_size.x * 0.35, obj.object_size.y * 0.12, 1.0)
	return mat


func _style_core(p: GPUParticles2D, obj: BurnableObject) -> void:
	var mat := _base_mat(obj)
	mat.spread = 18.0
	mat.initial_velocity_min = 22.0
	mat.initial_velocity_max = 48.0
	mat.gravity = Vector3(0, -55, 0)
	var ps := obj.material_def.particle_scale if obj.material_def else 1.0
	mat.scale_min = 0.25 * ps
	mat.scale_max = 0.55 * ps
	mat.color_ramp = _ramp([
		Color(1.0, 0.98, 0.85, 1.0),
		Color(1.0, 0.85, 0.4, 0.9),
		Color(1.0, 0.4, 0.1, 0.3),
		Color(0.2, 0.05, 0.0, 0.0),
	])
	p.process_material = mat


func _style_outer(p: GPUParticles2D, obj: BurnableObject) -> void:
	var mat := _base_mat(obj)
	mat.spread = 32.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 75.0
	mat.gravity = Vector3(0, -35, 0)
	var ps := obj.material_def.particle_scale if obj.material_def else 1.0
	mat.scale_min = 0.4 * ps
	mat.scale_max = 0.95 * ps
	mat.color_ramp = _ramp([
		Color(1.0, 0.7, 0.25, 0.85),
		Color(1.0, 0.35, 0.08, 0.7),
		Color(0.55, 0.1, 0.02, 0.3),
		Color(0.08, 0.03, 0.01, 0.0),
	])
	p.process_material = mat


func _style_embers(p: GPUParticles2D, obj: BurnableObject) -> void:
	var mat := _base_mat(obj)
	mat.spread = 50.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 110.0
	mat.gravity = Vector3(0, -20, 0)
	mat.scale_min = 0.12
	mat.scale_max = 0.28
	mat.color_ramp = _ramp([
		Color(1.0, 0.85, 0.4, 1.0),
		Color(1.0, 0.45, 0.1, 0.8),
		Color(0.4, 0.1, 0.02, 0.0),
	])
	p.process_material = mat
	p.explosiveness = 0.15


func _style_smoke(p: GPUParticles2D, obj: BurnableObject) -> void:
	var mat := _base_mat(obj)
	mat.spread = 40.0
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 36.0
	mat.gravity = Vector3(0, -25, 0)
	mat.scale_min = 0.7
	mat.scale_max = 1.6
	mat.color_ramp = _ramp([
		Color(0.35, 0.3, 0.28, 0.0),
		Color(0.28, 0.25, 0.22, 0.28),
		Color(0.18, 0.16, 0.15, 0.12),
		Color(0.1, 0.1, 0.1, 0.0),
	])
	p.process_material = mat


func _ramp(colors: Array) -> GradientTexture1D:
	var ramp := GradientTexture1D.new()
	var grad := Gradient.new()
	var n := colors.size()
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in n:
		offsets.append(float(i) / float(maxi(n - 1, 1)))
		cols.append(colors[i])
	grad.offsets = offsets
	grad.colors = cols
	ramp.gradient = grad
	return ramp


func _set_emitting(pack: Dictionary, on: bool, amp: float = 1.0) -> void:
	for k in ["core", "outer", "embers", "smoke"]:
		var p: GPUParticles2D = pack[k]
		if not is_instance_valid(p):
			continue
		p.emitting = on
		if on:
			p.speed_scale = amp


func _on_state_changed(_from: int, to_state: int, obj: BurnableObject) -> void:
	var pack := _ensure_layers(obj)
	var amp := _chain_intensity
	match to_state:
		BurnableObject.State.IGNITING:
			_active_burn_count += 1
			_set_emitting(pack, true, 1.35 * amp)
			pack["core"].amount = int(MAX_CORE * amp)
			pack["outer"].amount = int(MAX_OUTER * amp)
			_burst(obj, false)
		BurnableObject.State.BURNING:
			_set_emitting(pack, true, lerpf(1.0, 1.45, (amp - 1.0) / 1.4))
			pack["smoke"].emitting = true
		BurnableObject.State.CHARRED:
			pack["core"].emitting = false
			pack["outer"].emitting = true
			pack["outer"].amount = 8
			pack["outer"].speed_scale = 0.5
			pack["embers"].emitting = true
			pack["embers"].amount = 6
			pack["smoke"].emitting = true
			pack["smoke"].amount = 10
		BurnableObject.State.DESTROYED:
			_active_burn_count = maxi(_active_burn_count - 1, 0)
			_set_emitting(pack, false)
			_ash(obj)
		BurnableObject.State.UNIGNITED, BurnableObject.State.HEATING:
			_set_emitting(pack, false)


func _burst(obj: BurnableObject, huge: bool) -> void:
	if not is_inside_tree():
		return
	var burst := GPUParticles2D.new()
	burst.z_index = 12
	burst.one_shot = true
	burst.emitting = true
	var amp := _chain_intensity * (1.8 if huge else 1.0)
	burst.amount = int((30 if huge else 16) * amp)
	burst.lifetime = 0.45 if huge else 0.32
	burst.explosiveness = 0.95
	burst.texture = _soft_tex if _soft_tex else SoftTextureFactory.soft_blob(16)
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 120.0 if huge else 85.0
	mat.initial_velocity_min = 55.0 if huge else 40.0
	mat.initial_velocity_max = 190.0 if huge else 125.0
	mat.gravity = Vector3(0, 45, 0)
	mat.scale_min = 0.45
	mat.scale_max = 1.7 if huge else 1.1
	mat.color = Color(1.0, 0.88, 0.45, 1.0)
	burst.process_material = mat
	obj.add_child(burst)
	get_tree().create_timer(0.65).timeout.connect(burst.queue_free)


func _ash(obj: BurnableObject) -> void:
	if not is_instance_valid(obj) or not obj.is_inside_tree():
		return
	var ash := GPUParticles2D.new()
	ash.z_index = 6
	ash.one_shot = true
	ash.emitting = true
	ash.amount = 12
	ash.lifetime = 0.7
	ash.explosiveness = 0.8
	ash.texture = _soft_tex if _soft_tex else SoftTextureFactory.soft_blob(16)
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3(0, 30, 0)
	mat.scale_min = 0.2
	mat.scale_max = 0.55
	mat.color = Color(0.35, 0.3, 0.28, 0.7)
	ash.process_material = mat
	obj.add_child(ash)
	get_tree().create_timer(0.85).timeout.connect(ash.queue_free)


func _on_explosion_fx(origin: Vector2, radius: float, _heat: float) -> void:
	if not is_inside_tree():
		return
	var host := Node2D.new()
	host.z_index = 20
	if _world and is_instance_valid(_world):
		_world.add_child(host)
		host.global_position = origin
	else:
		add_child(host)
		host.position = origin

	## Shockwave ring (visual only).
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 8.0)
	ring.polygon = pts
	ring.color = Color(1.0, 0.85, 0.45, 0.55)
	host.add_child(ring)
	var ring_tw := host.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * clampf(radius * 0.02, 4.0, 14.0), 0.35)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.35)

	var fireball := GPUParticles2D.new()
	fireball.one_shot = true
	fireball.emitting = true
	fireball.amount = int(clampf(radius * 0.4, 28.0, 72.0))
	fireball.lifetime = 0.55
	fireball.explosiveness = 1.0
	fireball.texture = _soft_tex if _soft_tex else SoftTextureFactory.soft_blob(16)
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 0.35
	mat.initial_velocity_max = radius * 1.15
	mat.gravity = Vector3(0, 70, 0)
	mat.scale_min = 0.7
	mat.scale_max = 2.0
	mat.color_ramp = _ramp([
		Color(1.0, 0.95, 0.7, 1.0),
		Color(1.0, 0.55, 0.15, 0.9),
		Color(0.4, 0.1, 0.02, 0.3),
		Color(0.1, 0.08, 0.06, 0.0),
	])
	fireball.process_material = mat
	host.add_child(fireball)

	var smoke := GPUParticles2D.new()
	smoke.one_shot = true
	smoke.emitting = true
	smoke.amount = int(clampf(radius * 0.2, 12.0, 36.0))
	smoke.lifetime = 0.9
	smoke.explosiveness = 0.7
	smoke.texture = _soft_tex if _soft_tex else SoftTextureFactory.soft_blob(16)
	var sm := ParticleProcessMaterial.new()
	sm.particle_flag_disable_z = true
	sm.spread = 180.0
	sm.initial_velocity_min = radius * 0.1
	sm.initial_velocity_max = radius * 0.45
	sm.gravity = Vector3(0, -15, 0)
	sm.scale_min = 1.0
	sm.scale_max = 2.4
	sm.color = Color(0.25, 0.22, 0.2, 0.45)
	smoke.process_material = sm
	host.add_child(smoke)

	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(host):
			host.queue_free()
	)


func _on_destroyed(obj: BurnableObject) -> void:
	if _fx.has(obj):
		var pack: Dictionary = _fx[obj]
		_set_emitting(pack, false)
	if _chain_intensity > 1.5 and is_instance_valid(obj) and obj.is_inside_tree():
		_burst(obj, _chain_intensity > 1.9)
