class_name CompositionLayer
extends Node2D
## Decorative depth props only. gameplay=false — never registered with FireManager.

var _theme: EnvironmentTheme
var _seed: int = 1
var _props: Array[Node2D] = []


func clear() -> void:
	for p in _props:
		if is_instance_valid(p):
			p.queue_free()
	_props.clear()
	for c in get_children():
		c.queue_free()


func build(theme: EnvironmentTheme, visual_seed: int, play_rect: Rect2 = Rect2(40, 180, 640, 900)) -> void:
	clear()
	_theme = theme if theme else EnvironmentTheme.workshop()
	_seed = visual_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = (_seed * 7919 + 104729) & 0x7fffffff
	var count := _theme.deco_count
	for i in count:
		var prop := _make_prop(rng, i)
		var margin := 36.0
		prop.position = Vector2(
			rng.randf_range(play_rect.position.x + margin, play_rect.end.x - margin),
			rng.randf_range(play_rect.position.y + margin, play_rect.end.y - margin)
		)
		## Bias some props to edges so they don't crowd the puzzle core.
		if rng.randf() < 0.55:
			if rng.randf() < 0.5:
				prop.position.x = play_rect.position.x + rng.randf_range(8, 70)
			else:
				prop.position.x = play_rect.end.x - rng.randf_range(8, 70)
		prop.z_index = -4
		prop.modulate.a = rng.randf_range(0.18, 0.38)
		add_child(prop)
		_props.append(prop)


func _make_prop(rng: RandomNumberGenerator, index: int) -> Node2D:
	var root := Node2D.new()
	root.name = "Deco_%d" % index
	root.set_meta("gameplay", false)
	root.set_meta("decoration", true)
	var poly := Polygon2D.new()
	var palette := _theme.deco_palette
	var col := palette[index % palette.size()] if palette.size() > 0 else Color(0.2, 0.18, 0.15, 0.3)
	poly.color = col
	var kind := rng.randi() % 4
	match kind:
		0:
			## Soft plank / shelf silhouette.
			var w := rng.randf_range(40, 110)
			var h := rng.randf_range(8, 18)
			poly.polygon = PackedVector2Array([
				Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5),
				Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, h * 0.5),
			])
		1:
			## Tall upright.
			var w := rng.randf_range(10, 22)
			var h := rng.randf_range(50, 120)
			poly.polygon = PackedVector2Array([
				Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5),
				Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, h * 0.5),
			])
		2:
			## Soft circle blob.
			var r := rng.randf_range(14, 36)
			var pts := PackedVector2Array()
			for k in 10:
				var a := TAU * float(k) / 10.0
				pts.append(Vector2(cos(a), sin(a)) * r)
			poly.polygon = pts
		_:
			## Soft diamond.
			var s := rng.randf_range(16, 34)
			poly.polygon = PackedVector2Array([
				Vector2(0, -s), Vector2(s * 0.7, 0), Vector2(0, s), Vector2(-s * 0.7, 0),
			])
	poly.rotation = rng.randf_range(-0.25, 0.25)
	root.add_child(poly)
	return root
