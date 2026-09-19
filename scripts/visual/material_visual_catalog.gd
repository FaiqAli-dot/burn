class_name MaterialVisualCatalog
extends RefCounted
## Loads authored material sprites + burn masks. Display only.

const SPRITE_SHADER := preload("res://shaders/burnable_sprite.gdshader")

const VARIANT_MAP := {
	"paper": ["sheet", "folded", "stack", "torn"],
	"wood": ["plank", "log", "branch", "crate"],
	"grass": ["clump", "patch", "tuft", "blades"],
	"fabric": ["strip", "folded", "hanging", "bundle"],
	"oil": ["puddle", "trail", "droplet", "spill"],
	"plastic": ["bottle", "container", "sheet", "block"],
	"metal": ["can", "plate", "sheet", "beam"],
	"glass": ["bottle", "panel", "shard", "jar"],
}

const MASK_PATHS := [
	"res://assets/fire/burn_masks/hole_irregular.png",
	"res://assets/fire/burn_masks/crack.png",
	"res://assets/fire/burn_masks/multihole.png",
	"res://assets/fire/burn_masks/edge_eat.png",
]

static var _tex_cache: Dictionary = {}


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


static func sprite_path(material_id: String, visual_seed: int, object_id: String = "") -> String:
	var variants: Array = VARIANT_MAP.get(material_id, VARIANT_MAP["paper"])
	var h := hash("%s:%s:%d" % [material_id, object_id, visual_seed]) & 0x7fffffff
	var name := String(variants[h % variants.size()])
	return "res://assets/materials/%s/%s.png" % [material_id, name]


static func load_tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	if not ResourceLoader.exists(path):
		push_warning("Missing art asset: %s" % path)
		return null
	var tex := load(path) as Texture2D
	_tex_cache[path] = tex
	return tex


static func sprite_for(material_id: String, visual_seed: int, object_id: String = "") -> Texture2D:
	return load_tex(sprite_path(material_id, visual_seed, object_id))


static func burn_mask_for(visual_seed: int, object_id: String = "") -> Texture2D:
	var h := hash("mask:%s:%d" % [object_id, visual_seed]) & 0x7fffffff
	return load_tex(MASK_PATHS[h % MASK_PATHS.size()])


static func flame_tex(kind: String = "medium") -> Texture2D:
	var path := "res://assets/fire/flames/%s.png" % kind
	if not ResourceLoader.exists(path):
		path = "res://assets/fire/flames/medium.png"
	return load_tex(path)


static func ember_tex() -> Texture2D:
	return load_tex("res://assets/fire/embers/cluster.png")


static func smoke_tex(thick: bool = false) -> Texture2D:
	return load_tex("res://assets/fire/smoke/thick.png" if thick else "res://assets/fire/smoke/soft.png")


static func burst_tex() -> Texture2D:
	return load_tex("res://assets/fire/bursts/fireball.png")


static func env_backdrop(theme_id: String) -> Texture2D:
	var id := theme_id.to_lower()
	if id not in ["workshop", "forest", "warehouse"]:
		id = "workshop"
	return load_tex("res://assets/environments/%s/backdrop.png" % id)


static func brand_flame() -> Texture2D:
	return load_tex("res://assets/ui/branding/flame_mark.png")


static func make_sprite_material(mat_def: MaterialDefinition, visual_seed: int, object_id: String = "") -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = SPRITE_SHADER
	var mid := String(mat_def.id) if mat_def else "paper"
	sm.set_shader_parameter("burn_mask", burn_mask_for(visual_seed, object_id))
	sm.set_shader_parameter("burn_tint", mat_def.burn_tint if mat_def else Color(1, 0.42, 0.12))
	sm.set_shader_parameter("char_color", mat_def.char_color if mat_def else Color(0.12, 0.09, 0.07))
	sm.set_shader_parameter("heat_amount", 0.0)
	sm.set_shader_parameter("burn_amount", 0.0)
	sm.set_shader_parameter("char_amount", 0.0)
	sm.set_shader_parameter("dissolve", 0.0)
	sm.set_shader_parameter("glow_strength", 0.0)
	sm.set_shader_parameter("edge_char", mid in ["paper", "wood", "grass", "fabric"])
	sm.set_shader_parameter("hole_burn", mid in ["paper", "fabric", "grass"])
	sm.set_shader_parameter("melt", mid in ["plastic", "oil"])
	sm.set_shader_parameter("is_metal", mid == "metal")
	sm.set_shader_parameter("is_glass", mid == "glass")
	sm.set_shader_parameter("is_oil", mid == "oil")
	return sm


## Back-compat helpers used by older call sites.
static func albedo_for(material_id: String, visual_seed: int) -> Texture2D:
	return sprite_for(material_id, visual_seed)


static func make_surface_material(mat_def: MaterialDefinition, visual_seed: int) -> ShaderMaterial:
	return make_sprite_material(mat_def, visual_seed)


static func style_index(material_id: String) -> int:
	match material_id:
		"paper": return 0
		"wood": return 1
		"grass": return 2
		"fabric": return 3
		"oil": return 4
		"plastic": return 5
		"metal": return 6
		"glass": return 7
		_: return 0


static func clear_cache() -> void:
	_tex_cache.clear()
