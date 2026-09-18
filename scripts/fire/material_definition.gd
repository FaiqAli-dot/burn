class_name MaterialDefinition
extends Resource
## Tunable burn physics for one material type.
## Gameplay simulation reads these; visuals only sample display fields.

@export var id: StringName = &"paper"
@export var display_name: String = "Paper"

## 0–1 multiplier on incoming heat absorption.
@export_range(0.0, 2.0, 0.01) var flammability: float = 1.0
## Accumulated heat required to enter IGNITING.
@export var ignition_threshold: float = 18.0
## Heat radiated per second at full burn intensity.
@export var heat_output: float = 50.0
## Max distance (px) heat can travel from object edge.
@export var heat_radius: float = 96.0
## Seconds spent in BURNING before char/destroy.
@export var burn_duration: float = 2.0
## Seconds spent CHARRED before DESTROYED. 0 = skip char (paper).
@export var char_duration: float = 0.0
## Extra ignition flash scale for this material.
@export_range(0.5, 2.0, 0.05) var ignition_flash: float = 1.0

@export_group("Behavior")
## If false, never ignites (metal/glass obstacles).
@export var is_flammable: bool = true
## If false, player tap cannot start fire on this object.
@export var player_ignitable: bool = true
## If false, excluded from burn % / win even when scoring flag is true.
@export var counts_toward_burn_goal: bool = true
## Detonate once while burning (oil).
@export var explodes: bool = false
@export_range(0.0, 1.0, 0.01) var explode_at_burn_fraction: float = 0.4
@export var explosion_radius: float = 150.0
@export var explosion_heat: float = 90.0
@export_range(0.5, 2.5, 0.05) var explosion_falloff_power: float = 1.2

@export_group("Display")
@export var base_color: Color = Color(0.93, 0.89, 0.80)
@export var edge_color: Color = Color(0.78, 0.72, 0.62)
@export var burn_tint: Color = Color(1.0, 0.42, 0.12)
@export var char_color: Color = Color(0.14, 0.11, 0.09)
@export var default_size: Vector2 = Vector2(48, 48)
## Visual juice bias (1 = normal flames).
@export_range(0.4, 2.0, 0.05) var particle_scale: float = 1.0


func radiates_while_charred() -> bool:
	return char_duration > 0.0 and is_flammable
