class_name MaterialVisualDefinition
extends Resource
## Appearance-only material art. Never feeds FireManager / solver.

@export var material_id: StringName = &"paper"
@export var variant_paths: PackedStringArray = PackedStringArray()
@export var preferred_aspect: Vector2 = Vector2(1, 1)
@export var sprite_scale_bias: float = 1.15
@export var burn_mask_paths: PackedStringArray = PackedStringArray()
@export var shadow_opacity: float = 0.45
@export var uses_transparency: bool = false
@export var rim_light_when_near_fire: bool = false
@export var melt_on_burn: bool = false
@export var hole_burn: bool = true
@export var edge_char: bool = true
