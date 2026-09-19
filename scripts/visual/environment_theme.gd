class_name EnvironmentTheme
extends Resource
## Visual-only environment palette. Never feeds FireManager / solver.

@export var id: StringName = &"workshop"
@export var display_name: String = "Workshop"

@export_group("Backdrop")
@export var top_color: Color = Color(0.13, 0.10, 0.08, 1.0)
@export var bottom_color: Color = Color(0.045, 0.035, 0.030, 1.0)
@export var accent_color: Color = Color(0.55, 0.28, 0.12, 1.0)
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.52
@export_range(0.0, 0.2, 0.005) var grain_strength: float = 0.032
@export_range(0.0, 0.2, 0.005) var warm_lift: float = 0.06
@export_range(0.0, 1.0, 0.01) var haze: float = 0.12

@export_group("Lighting")
@export var ambient_tint: Color = Color(0.92, 0.86, 0.78, 1.0)
@export var fire_fill: Color = Color(1.0, 0.55, 0.22, 1.0)
@export_range(0.4, 1.6, 0.05) var shadow_opacity: float = 0.55
@export var shadow_offset: Vector2 = Vector2(6, 10)

@export_group("Decoration")
@export var deco_palette: PackedColorArray = PackedColorArray([
	Color(0.22, 0.18, 0.14, 0.35),
	Color(0.16, 0.14, 0.12, 0.28),
	Color(0.28, 0.20, 0.14, 0.22),
])
@export_range(0, 12, 1) var deco_count: int = 5
@export var mood: String = "warm_workshop"


static func workshop() -> EnvironmentTheme:
	var t := EnvironmentTheme.new()
	t.id = &"workshop"
	t.display_name = "Workshop"
	t.top_color = Color(0.14, 0.10, 0.08)
	t.bottom_color = Color(0.04, 0.032, 0.028)
	t.accent_color = Color(0.62, 0.32, 0.12)
	t.vignette_strength = 0.54
	t.grain_strength = 0.034
	t.warm_lift = 0.07
	t.haze = 0.10
	t.ambient_tint = Color(0.94, 0.88, 0.78)
	t.fire_fill = Color(1.0, 0.52, 0.18)
	t.shadow_opacity = 0.58
	t.shadow_offset = Vector2(7, 11)
	t.deco_count = 6
	t.mood = "warm_workshop"
	t.deco_palette = PackedColorArray([
		Color(0.24, 0.18, 0.13, 0.32),
		Color(0.18, 0.14, 0.11, 0.26),
		Color(0.32, 0.22, 0.14, 0.20),
	])
	return t


static func forest() -> EnvironmentTheme:
	var t := EnvironmentTheme.new()
	t.id = &"forest"
	t.display_name = "Forest"
	t.top_color = Color(0.08, 0.11, 0.09)
	t.bottom_color = Color(0.03, 0.04, 0.035)
	t.accent_color = Color(0.28, 0.42, 0.22)
	t.vignette_strength = 0.58
	t.grain_strength = 0.028
	t.warm_lift = 0.04
	t.haze = 0.16
	t.ambient_tint = Color(0.82, 0.90, 0.78)
	t.fire_fill = Color(1.0, 0.58, 0.22)
	t.shadow_opacity = 0.62
	t.shadow_offset = Vector2(5, 12)
	t.deco_count = 7
	t.mood = "cool_canopy"
	t.deco_palette = PackedColorArray([
		Color(0.12, 0.18, 0.12, 0.34),
		Color(0.10, 0.14, 0.10, 0.28),
		Color(0.18, 0.22, 0.14, 0.22),
	])
	return t


static func warehouse() -> EnvironmentTheme:
	var t := EnvironmentTheme.new()
	t.id = &"warehouse"
	t.display_name = "Warehouse"
	t.top_color = Color(0.09, 0.09, 0.11)
	t.bottom_color = Color(0.028, 0.028, 0.034)
	t.accent_color = Color(0.35, 0.38, 0.45)
	t.vignette_strength = 0.60
	t.grain_strength = 0.036
	t.warm_lift = 0.035
	t.haze = 0.08
	t.ambient_tint = Color(0.78, 0.82, 0.90)
	t.fire_fill = Color(1.0, 0.48, 0.16)
	t.shadow_opacity = 0.66
	t.shadow_offset = Vector2(8, 9)
	t.deco_count = 5
	t.mood = "cold_steel"
	t.deco_palette = PackedColorArray([
		Color(0.16, 0.17, 0.20, 0.36),
		Color(0.12, 0.12, 0.14, 0.28),
		Color(0.22, 0.22, 0.26, 0.20),
	])
	return t


static func from_id(theme_id: String) -> EnvironmentTheme:
	match theme_id.to_lower():
		"forest":
			return forest()
		"warehouse", "night", "warehouse_night":
			return warehouse()
		_:
			return workshop()
