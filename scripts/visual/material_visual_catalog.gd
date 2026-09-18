class_name MaterialVisualCatalog
extends RefCounted
## Display-only material look params. Does not alter MaterialDefinition sim fields.

const SURFACE_SHADER := preload("res://shaders/burnable_surface.gdshader")

static var _albedo_cache: Dictionary = {} ## key -> ImageTexture


static func visual_seed_for_level(meta: Dictionary, level_path: String = "") -> int:
	var gen: Dictionary = {}
	if typeof(meta.get("generator", null)) == TYPE_DICTIONARY:
		gen = meta["generator"]
	if gen.has("seed"):
		return int(gen["seed"])
	if meta.has("visual_seed"):
		return int(meta["visual_seed"])
	var id := String(meta.get("id", level_path.get_file().get_basename()))
	return hash(id) & 0x7fffffff


static func albedo_for(material_id: String, visual_seed: int) -> Texture2D:
	var key := "%s:%d" % [material_id, visual_seed % 97]
	if _albedo_cache.has(key):
		return _albedo_cache[key]
	var tex := SoftTextureFactory.material_albedo(material_id, visual_seed, 64)
	_albedo_cache[key] = tex
	return tex


static func make_surface_material(mat_def: MaterialDefinition, visual_seed: int) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = SURFACE_SHADER
	var mid := String(mat_def.id) if mat_def else "paper"
	sm.set_shader_parameter("albedo_tex", albedo_for(mid, visual_seed))
	sm.set_shader_parameter("base_color", mat_def.base_color if mat_def else Color.WHITE)
	sm.set_shader_parameter("edge_color", mat_def.edge_color if mat_def else Color(0.5, 0.5, 0.5))
	sm.set_shader_parameter("burn_tint", mat_def.burn_tint if mat_def else Color(1, 0.4, 0.1))
	sm.set_shader_parameter("char_color", mat_def.char_color if mat_def else Color(0.1, 0.1, 0.1))
	sm.set_shader_parameter("heat_amount", 0.0)
	sm.set_shader_parameter("burn_amount", 0.0)
	sm.set_shader_parameter("char_amount", 0.0)
	sm.set_shader_parameter("dissolve", 0.0)
	sm.set_shader_parameter("glow_strength", 0.0)
	sm.set_shader_parameter("style", style_index(mid))
	sm.set_shader_parameter("uv_scale", Vector2(1.0, 1.0))
	sm.set_shader_parameter("is_glass", mid == "glass")
	sm.set_shader_parameter("is_oil", mid == "oil")
	sm.set_shader_parameter("is_metal", mid == "metal")
	return sm


static func style_index(material_id: String) -> int:
	match material_id:
		"paper":
			return 0
		"wood":
			return 1
		"grass":
			return 2
		"fabric":
			return 3
		"oil":
			return 4
		"plastic":
			return 5
		"metal":
			return 6
		"glass":
			return 7
		_:
			return 0


static func clear_cache() -> void:
	_albedo_cache.clear()
