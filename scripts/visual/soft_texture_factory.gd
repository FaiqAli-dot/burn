class_name SoftTextureFactory
extends RefCounted
## Tiny original procedural textures. Deterministic from visual_seed. Display only.


static func soft_blob(size: int = 32) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var mid := float(size) * 0.5
	for y in size:
		for x in size:
			var dx := (float(x) + 0.5 - mid) / mid
			var dy := (float(y) + 0.5 - mid) / mid
			var d := sqrt(dx * dx + dy * dy)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


static func material_albedo(material_id: String, seed: int, size: int = 64) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(seed) + ":" + material_id) & 0x7fffffff
	match material_id:
		"paper":
			return _paper(rng, size)
		"wood":
			return _wood(rng, size)
		"grass":
			return _grass(rng, size)
		"fabric":
			return _fabric(rng, size)
		"oil":
			return _oil(rng, size)
		"plastic":
			return _plastic(rng, size)
		"metal":
			return _metal(rng, size)
		"glass":
			return _glass(rng, size)
		_:
			return _paper(rng, size)


static func _hash2(p: Vector2) -> float:
	return fposmod(sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453, 1.0)


static func _noise(p: Vector2) -> float:
	var i := Vector2(floor(p.x), floor(p.y))
	var f := Vector2(p.x - i.x, p.y - i.y)
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	var a := _hash2(i)
	var b := _hash2(i + Vector2(1, 0))
	var c := _hash2(i + Vector2(0, 1))
	var d := _hash2(i + Vector2(1, 1))
	return lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)


static func _paper(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base := Color(0.94, 0.90, 0.82)
	for y in size:
		for x in size:
			var uv := Vector2(float(x) / size, float(y) / size)
			var fiber := _noise(uv * Vector2(28.0 + rng.randf() * 4.0, 6.0)) * 0.08
			var fold := absf(sin(uv.x * TAU * 2.0 + uv.y * 3.0)) * 0.04
			var speck := 0.0
			if rng.randf() > 0.97:
				speck = -0.06
			var c := base.lightened(fiber - fold + speck)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)


static func _wood(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dark := Color(0.32, 0.18, 0.10)
	var light := Color(0.52, 0.34, 0.18)
	var phase := rng.randf() * TAU
	for y in size:
		for x in size:
			var uv := Vector2(float(x) / size, float(y) / size)
			var grain := sin(uv.x * 18.0 + sin(uv.y * 4.0 + phase) * 2.2)
			grain = grain * 0.5 + 0.5
			var knot := _noise(uv * 5.0 + Vector2(phase, 0))
			var c := dark.lerp(light, grain)
			if knot > 0.78:
				c = c.darkened(0.18)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)


static func _grass(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var tip := Color(0.55, 0.78, 0.34)
	var base := Color(0.28, 0.48, 0.18)
	img.fill(Color(0.22, 0.36, 0.14, 1.0))
	for _i in 90:
		var x0 := rng.randi_range(2, size - 3)
		var y0 := rng.randi_range(size / 2, size - 2)
		var h := rng.randi_range(8, size / 2)
		var lean := rng.randf_range(-0.35, 0.35)
		for s in h:
			var t := float(s) / float(h)
			var x := int(x0 + lean * s)
			var y := y0 - s
			if x < 0 or x >= size or y < 0 or y >= size:
				continue
			var c := base.lerp(tip, t)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
			if x + 1 < size:
				img.set_pixel(x + 1, y, Color(c.r, c.g, c.b, 0.85))
	return ImageTexture.create_from_image(img)


static func _fabric(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var a := Color(0.52, 0.38, 0.64)
	var b := Color(0.40, 0.28, 0.52)
	var weave := 3 + rng.randi() % 3
	for y in size:
		for x in size:
			var wx := (x / weave) % 2
			var wy := (y / weave) % 2
			var fold := absf(sin(float(x) * 0.18 + float(y) * 0.05)) * 0.08
			var c := a if (wx + wy) % 2 == 0 else b
			c = c.lightened(fold)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)


static func _oil(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var mid := float(size) * 0.5
	for y in size:
		for x in size:
			var dx := (float(x) + 0.5 - mid) / mid
			var dy := (float(y) + 0.5 - mid) / mid
			var d := sqrt(dx * dx + dy * dy)
			var edge := _smooth(1.05, 0.55, d)
			var swirl := _noise(Vector2(dx, dy) * 3.5 + Vector2(rng.randf(), 0))
			var c := Color(0.12, 0.16, 0.22).lerp(Color(0.28, 0.34, 0.40), swirl)
			var gloss := pow(clampf(1.0 - d, 0.0, 1.0), 2.2) * 0.35
			c = c.lightened(gloss)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, edge * 0.92))
	return ImageTexture.create_from_image(img)


static func _plastic(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base := Color(0.34, 0.54, 0.72)
	for y in size:
		for x in size:
			var uv := Vector2(float(x) / size, float(y) / size)
			var gloss := pow(1.0 - absf(uv.y - 0.28), 6.0) * 0.28
			var scratch := 0.0
			if absf(_noise(uv * Vector2(40, 2) + Vector2(rng.randf(), 0)) - 0.5) < 0.02:
				scratch = 0.08
			var c := base.lightened(gloss + scratch)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)


static func _metal(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var uv := Vector2(float(x) / size, float(y) / size)
			var band := sin(uv.y * 40.0 + rng.randf() * 0.2) * 0.04
			var sheen := pow(absf(sin(uv.x * PI)), 1.6) * 0.18
			var c := Color(0.58, 0.60, 0.64).lightened(band + sheen)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)


static func _glass(rng: RandomNumberGenerator, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var uv := Vector2(float(x) / size, float(y) / size)
			var edge := maxf(absf(uv.x - 0.5), absf(uv.y - 0.5))
			var rim := smoothstep(0.42, 0.5, edge) * 0.55
			var tint := Color(0.72, 0.88, 0.94, 0.28 + rim)
			var spark := 0.0
			if _noise(uv * 12.0 + Vector2(rng.randf(), 0)) > 0.88:
				spark = 0.2
			tint = tint.lightened(spark)
			img.set_pixel(x, y, tint)
	return ImageTexture.create_from_image(img)


static func _smooth(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / maxf(edge1 - edge0, 0.0001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
