class_name ParticleManager
extends Node
## Visual-only fire. Listens to BurnableObject / FireManager signals; never feeds sim.

const MAX_FLAME_PARTICLES := 36

var _flames: Dictionary = {} ## BurnableObject -> GPUParticles2D
var _chain_intensity: float = 1.0
var _fire: FireManager
var _world: Node2D


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
	for obj in objects:
		_ensure_flame(obj)
		if not obj.state_changed.is_connected(_on_state_changed):
			obj.state_changed.connect(_on_state_changed.bind(obj))
		if not obj.destroyed.is_connected(_on_destroyed):
			obj.destroyed.connect(_on_destroyed.bind(obj))


func clear() -> void:
	for key in _flames.keys():
		var p: GPUParticles2D = _flames[key]
		if is_instance_valid(p):
			p.queue_free()
	_flames.clear()
	_chain_intensity = 1.0


func _on_chain(count: int) -> void:
	_chain_intensity = clampf(1.0 + float(count) * 0.08, 1.0, 2.4)


func _ensure_flame(obj: BurnableObject) -> GPUParticles2D:
	if _flames.has(obj) and is_instance_valid(_flames[obj]):
		return _flames[obj]
	var particles := GPUParticles2D.new()
	particles.name = "FlameVisual"
	particles.z_index = 8
	particles.emitting = false
	particles.amount = MAX_FLAME_PARTICLES
	particles.lifetime = 0.55
	particles.explosiveness = 0.05
	particles.randomness = 0.4
	particles.visibility_rect = Rect2(-100, -140, 200, 200)
	particles.process_material = _make_flame_material(obj)
	particles.texture = _make_soft_particle_texture()
	obj.add_child(particles)
	_flames[obj] = particles
	return particles


func _make_flame_material(obj: BurnableObject) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 28.0
	mat.initial_velocity_min = 28.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, -40, 0)
	var pscale := 1.0
	if obj.material_def:
		pscale = obj.material_def.particle_scale
	mat.scale_min = 0.35 * pscale
	mat.scale_max = 0.85 * pscale
	mat.color = Color(1.0, 0.55, 0.15, 0.85)
	var ramp := GradientTexture1D.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.65, 0.95),
		Color(1.0, 0.45, 0.1, 0.85),
		Color(0.7, 0.12, 0.02, 0.4),
		Color(0.1, 0.05, 0.02, 0.0),
	])
	ramp.gradient = grad
	mat.color_ramp = ramp
	var emission_box := Vector3(obj.object_size.x * 0.35, obj.object_size.y * 0.15, 1.0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = emission_box
	return mat


func _make_soft_particle_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var dx := (x + 0.5) / 16.0 - 0.5
			var dy := (y + 0.5) / 16.0 - 0.5
			var d := sqrt(dx * dx + dy * dy) * 2.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _on_state_changed(_from: int, to_state: int, obj: BurnableObject) -> void:
	var p := _ensure_flame(obj)
	var amp := _chain_intensity
	match to_state:
		BurnableObject.State.IGNITING:
			p.emitting = true
			p.amount = int(MAX_FLAME_PARTICLES * amp)
			p.speed_scale = 1.35 * amp
			_burst(obj, false)
		BurnableObject.State.BURNING:
			p.emitting = true
			p.speed_scale = 1.0 * lerpf(1.0, 1.4, (amp - 1.0) / 1.4)
		BurnableObject.State.CHARRED:
			p.emitting = true
			p.amount = 10
			p.speed_scale = 0.55
		BurnableObject.State.DESTROYED, BurnableObject.State.UNIGNITED, BurnableObject.State.HEATING:
			p.emitting = false


func _burst(obj: BurnableObject, huge: bool) -> void:
	if not is_inside_tree():
		return
	var burst := GPUParticles2D.new()
	burst.z_index = 12
	burst.one_shot = true
	burst.emitting = true
	var amp := _chain_intensity * (1.8 if huge else 1.0)
	burst.amount = int((28 if huge else 16) * amp)
	burst.lifetime = 0.45 if huge else 0.35
	burst.explosiveness = 0.95
	burst.texture = _make_soft_particle_texture()
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 110.0 if huge else 80.0
	mat.initial_velocity_min = 50.0 if huge else 40.0
	mat.initial_velocity_max = 180.0 if huge else 120.0
	mat.gravity = Vector3(0, 40, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.6 if huge else 1.1
	mat.color = Color(1.0, 0.85, 0.4, 1.0) if huge else Color(1.0, 0.9, 0.55, 1.0)
	burst.process_material = mat
	obj.add_child(burst)
	get_tree().create_timer(0.6).timeout.connect(burst.queue_free)


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
	var burst := GPUParticles2D.new()
	burst.one_shot = true
	burst.emitting = true
	burst.amount = int(clampf(radius * 0.35, 24.0, 64.0))
	burst.lifetime = 0.55
	burst.explosiveness = 1.0
	burst.texture = _make_soft_particle_texture()
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 0.4
	mat.initial_velocity_max = radius * 1.1
	mat.gravity = Vector3(0, 80, 0)
	mat.scale_min = 0.6
	mat.scale_max = 1.8
	mat.color = Color(1.0, 0.75, 0.25, 1.0)
	burst.process_material = mat
	host.add_child(burst)
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		if is_instance_valid(host):
			host.queue_free()
	)


func _on_destroyed(obj: BurnableObject) -> void:
	if _flames.has(obj):
		var p: GPUParticles2D = _flames[obj]
		if is_instance_valid(p):
			p.emitting = false
	## Escalated ash puff on big chains.
	if _chain_intensity > 1.5 and is_instance_valid(obj) and obj.is_inside_tree():
		_burst(obj, _chain_intensity > 1.9)
