class_name MaterialDefinition
extends Resource
## Tunable burn physics for one material type.
## Gameplay simulation reads these; visuals only sample display fields.

@export var id: StringName = &"paper"
@export var display_name: String = "Paper"

## 0–1 multiplier on incoming heat absorption.
@export_range(0.05, 2.0, 0.01) var flammability: float = 1.0
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

@export_group("Display")
@export var base_color: Color = Color(0.93, 0.89, 0.80)
@export var edge_color: Color = Color(0.78, 0.72, 0.62)
@export var burn_tint: Color = Color(1.0, 0.42, 0.12)
@export var char_color: Color = Color(0.14, 0.11, 0.09)
@export var default_size: Vector2 = Vector2(48, 48)

func radiates_while_charred() -> bool:
	return char_duration > 0.0
