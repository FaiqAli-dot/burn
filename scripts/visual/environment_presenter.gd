class_name EnvironmentPresenter
extends Node
## Applies EnvironmentTheme + authored backdrop art. Visual only.

var theme: EnvironmentTheme
var _backdrop: CanvasItem
var _material: ShaderMaterial
var _art_rect: TextureRect
var _fire_glow: float = 0.0
var _visual_seed: int = 1


func bind_backdrop(backdrop: CanvasItem) -> void:
	_backdrop = backdrop
	if backdrop and backdrop.material is ShaderMaterial:
		_material = backdrop.material as ShaderMaterial
	_ensure_art_layer()


func _ensure_art_layer() -> void:
	if _backdrop == null or _art_rect != null:
		return
	var parent := _backdrop.get_parent()
	if parent == null:
		return
	_art_rect = TextureRect.new()
	_art_rect.name = "EnvironmentArt"
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art_rect.modulate = Color(1, 1, 1, 0.72)
	## Sit above shader wash, below world.
	parent.add_child(_art_rect)
	if _backdrop.get_index() >= 0:
		parent.move_child(_art_rect, _backdrop.get_index() + 1)


func apply_theme(t: EnvironmentTheme, visual_seed: int = 1) -> void:
	theme = t
	_visual_seed = visual_seed
	if theme == null:
		theme = EnvironmentTheme.workshop()
	if _material == null and _backdrop and _backdrop.material is ShaderMaterial:
		_material = _backdrop.material as ShaderMaterial
	if _material:
		_material.set_shader_parameter("top_color", theme.top_color)
		_material.set_shader_parameter("bottom_color", theme.bottom_color)
		_material.set_shader_parameter("accent_color", theme.accent_color)
		_material.set_shader_parameter("vignette_strength", theme.vignette_strength)
		_material.set_shader_parameter("grain_strength", theme.grain_strength)
		_material.set_shader_parameter("warm_lift", theme.warm_lift)
		_material.set_shader_parameter("haze", theme.haze)
		_material.set_shader_parameter("fire_glow", _fire_glow)
	_ensure_art_layer()
	if _art_rect:
		_art_rect.texture = MaterialVisualCatalog.env_backdrop(String(theme.id))
		_art_rect.modulate = Color(1, 1, 1, 0.78)


func set_fire_glow(amount: float) -> void:
	_fire_glow = clampf(amount, 0.0, 1.5)
	if _material:
		_material.set_shader_parameter("fire_glow", _fire_glow)
	if _art_rect:
		## Warm the authored plate slightly when fire grows.
		var warm := lerpf(0.78, 0.92, clampf(_fire_glow, 0.0, 1.0))
		_art_rect.modulate = Color(1.0, lerpf(1.0, 0.92, _fire_glow * 0.2), lerpf(1.0, 0.85, _fire_glow * 0.25), warm)


func resolve_theme_id(meta: Dictionary) -> String:
	var env := String(meta.get("environment", ""))
	if env != "":
		return env
	var theme_name := String(meta.get("theme", ""))
	if theme_name != "":
		return theme_name
	var gen: Dictionary = {}
	if typeof(meta.get("generator", null)) == TYPE_DICTIONARY:
		gen = meta["generator"]
	var arch := String(gen.get("archetype", ""))
	match arch:
		"scatter_field", "grass_spread":
			return "forest"
		"obstacle_maze", "trap_lane":
			return "warehouse"
		_:
			return "workshop"
