class_name EnvironmentPresenter
extends Node
## Applies EnvironmentTheme to backdrop + tracks ambient fire glow. Visual only.

var theme: EnvironmentTheme
var _backdrop: CanvasItem
var _material: ShaderMaterial
var _fire_glow: float = 0.0
var _visual_seed: int = 1


func bind_backdrop(backdrop: CanvasItem) -> void:
	_backdrop = backdrop
	if backdrop and backdrop.material is ShaderMaterial:
		_material = backdrop.material as ShaderMaterial


func apply_theme(t: EnvironmentTheme, visual_seed: int = 1) -> void:
	theme = t
	_visual_seed = visual_seed
	if theme == null:
		theme = EnvironmentTheme.workshop()
	if _material == null and _backdrop and _backdrop.material is ShaderMaterial:
		_material = _backdrop.material as ShaderMaterial
	if _material == null:
		return
	_material.set_shader_parameter("top_color", theme.top_color)
	_material.set_shader_parameter("bottom_color", theme.bottom_color)
	_material.set_shader_parameter("accent_color", theme.accent_color)
	_material.set_shader_parameter("vignette_strength", theme.vignette_strength)
	_material.set_shader_parameter("grain_strength", theme.grain_strength)
	_material.set_shader_parameter("warm_lift", theme.warm_lift)
	_material.set_shader_parameter("haze", theme.haze)
	_material.set_shader_parameter("fire_glow", _fire_glow)


func set_fire_glow(amount: float) -> void:
	_fire_glow = clampf(amount, 0.0, 1.5)
	if _material:
		_material.set_shader_parameter("fire_glow", _fire_glow)


func resolve_theme_id(meta: Dictionary) -> String:
	var env := String(meta.get("environment", ""))
	if env != "":
		return env
	var theme := String(meta.get("theme", ""))
	if theme != "":
		return theme
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
