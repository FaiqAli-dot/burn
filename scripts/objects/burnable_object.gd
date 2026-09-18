class_name BurnableObject
extends Area2D
## Single burnable prop. Owns fire *state*; FireManager owns propagation math.
## Visual children (particles/shaders) must never drive gameplay values.

signal state_changed(from_state: int, to_state: int)
signal heat_changed(heat: float, threshold: float)
signal ignited(by_player: bool)
signal destroyed
signal tap_requested(object: BurnableObject)

enum State {
	UNIGNITED,
	HEATING,
	IGNITING,
	BURNING,
	CHARRED,
	DESTROYED,
}

@export var material_def: MaterialDefinition
@export var object_size: Vector2 = Vector2(48, 48)

var state: int = State.UNIGNITED
var heat: float = 0.0
var burn_timer: float = 0.0
var char_timer: float = 0.0
var ignite_timer: float = 0.0
var burn_intensity: float = 0.0
var ignited_by_player: bool = false

## Contribution to burn % (area-weighted). Fixed at spawn.
var burn_weight: float = 1.0
var burned_fraction: float = 0.0
## If false, object is a tempting decoy and does not affect win %.
var counts_for_score: bool = true

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _body: Polygon2D = $Body
@onready var _glow: Polygon2D = $Glow
@onready var _visual: Node2D = $VisualRoot

const IGNITE_FLASH_TIME := 0.18


func _ready() -> void:
	monitoring = false
	monitorable = true
	input_pickable = true
	collision_layer = 1
	collision_mask = 0
	if material_def == null:
		push_error("BurnableObject missing MaterialDefinition at %s" % name)
		return
	if object_size == Vector2.ZERO:
		object_size = material_def.default_size
	burn_weight = maxf(object_size.x * object_size.y, 1.0)
	_setup_shape()
	_apply_base_look()
	if not counts_for_score:
		## Decoys read quieter so the main chain remains the visual focus.
		modulate = Color(0.82, 0.78, 0.74, 0.92)
	_glow.visible = false
	_glow.modulate.a = 0.0


func _setup_shape() -> void:
	var shape := RectangleShape2D.new()
	shape.size = object_size
	_collision.shape = shape
	var half := object_size * 0.5
	var pts := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	_body.polygon = pts
	_glow.polygon = pts


func _apply_base_look() -> void:
	_body.color = material_def.base_color
	modulate = Color.WHITE
	scale = Vector2.ONE


func get_heat_radius() -> float:
	return material_def.heat_radius if material_def else 0.0


func get_half_extents() -> Vector2:
	return object_size * 0.5


func edge_gap_to(other: BurnableObject) -> float:
	## Axis-aligned edge gap (rotation is visual-only for Phase 1).
	var dx := absf(global_position.x - other.global_position.x)
	var dy := absf(global_position.y - other.global_position.y)
	var ox := get_half_extents().x + other.get_half_extents().x
	var oy := get_half_extents().y + other.get_half_extents().y
	var gx := maxf(dx - ox, 0.0)
	var gy := maxf(dy - oy, 0.0)
	return sqrt(gx * gx + gy * gy)


func can_receive_heat() -> bool:
	return state in [State.UNIGNITED, State.HEATING]


func is_radiating() -> bool:
	if state in [State.IGNITING, State.BURNING]:
		return true
	if state == State.CHARRED and material_def.radiates_while_charred():
		return true
	return false


func get_radiated_heat_output() -> float:
	if material_def == null:
		return 0.0
	match state:
		State.IGNITING:
			return material_def.heat_output * 1.15
		State.BURNING:
			return material_def.heat_output * burn_intensity
		State.CHARRED:
			return material_def.heat_output * 0.28 * burn_intensity
		_:
			return 0.0


func is_counted_burned() -> bool:
	return state in [State.BURNING, State.CHARRED, State.DESTROYED]


func get_progress_contribution() -> float:
	## Soft progress: heating shows intent; burning/destroyed counts fully.
	match state:
		State.DESTROYED, State.CHARRED:
			return burn_weight
		State.BURNING:
			return burn_weight * clampf(0.55 + burned_fraction * 0.45, 0.0, 1.0)
		State.IGNITING:
			return burn_weight * 0.35
		State.HEATING:
			if material_def == null:
				return 0.0
			return burn_weight * 0.12 * clampf(heat / maxf(material_def.ignition_threshold, 0.01), 0.0, 1.0)
		_:
			return 0.0


func add_heat(amount: float) -> void:
	if amount <= 0.0 or not can_receive_heat() or material_def == null:
		return
	heat += amount
	if state == State.UNIGNITED and heat > 0.01:
		_set_state(State.HEATING)
	heat_changed.emit(heat, material_def.ignition_threshold)
	if heat >= material_def.ignition_threshold:
		_begin_ignite(false)


func try_player_ignite() -> bool:
	if state != State.UNIGNITED and state != State.HEATING:
		return false
	ignited_by_player = true
	heat = material_def.ignition_threshold if material_def else 1.0
	_begin_ignite(true)
	return true


func _begin_ignite(by_player: bool) -> void:
	if state in [State.IGNITING, State.BURNING, State.CHARRED, State.DESTROYED]:
		return
	ignite_timer = IGNITE_FLASH_TIME
	_set_state(State.IGNITING)
	ignited.emit(by_player)
	_play_ignition_flash()


func simulation_tick(delta: float) -> void:
	if material_def == null:
		return
	match state:
		State.HEATING:
			_update_heating_visual()
		State.IGNITING:
			ignite_timer -= delta
			burn_intensity = 1.0
			if ignite_timer <= 0.0:
				burn_timer = material_def.burn_duration
				_set_state(State.BURNING)
		State.BURNING:
			burn_timer -= delta
			var total := maxf(material_def.burn_duration, 0.01)
			burned_fraction = 1.0 - clampf(burn_timer / total, 0.0, 1.0)
			burn_intensity = lerpf(1.0, 0.55, burned_fraction)
			_update_burn_visual()
			if burn_timer <= 0.0:
				if material_def.char_duration > 0.0:
					char_timer = material_def.char_duration
					_set_state(State.CHARRED)
				else:
					_destroy()
		State.CHARRED:
			char_timer -= delta
			burn_intensity = lerpf(0.4, 0.05, 1.0 - clampf(char_timer / maxf(material_def.char_duration, 0.01), 0.0, 1.0))
			_update_char_visual()
			if char_timer <= 0.0:
				_destroy()


func _destroy() -> void:
	if state == State.DESTROYED:
		return
	burned_fraction = 1.0
	burn_intensity = 0.0
	_set_state(State.DESTROYED)
	destroyed.emit()
	_play_destroy_tween()


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	var old := state
	state = new_state
	state_changed.emit(old, new_state)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		tap_requested.emit(self)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_requested.emit(self)


func _update_heating_visual() -> void:
	if material_def == null or _body == null:
		return
	var t := clampf(heat / maxf(material_def.ignition_threshold, 0.01), 0.0, 1.0)
	_body.color = material_def.base_color.lerp(material_def.burn_tint, t * 0.35)
	if _glow:
		_glow.visible = t > 0.15
		_glow.modulate = Color(material_def.burn_tint.r, material_def.burn_tint.g, material_def.burn_tint.b, t * 0.35)


func _update_burn_visual() -> void:
	if material_def == null or _body == null:
		return
	var t := burned_fraction
	_body.color = material_def.burn_tint.lerp(material_def.char_color, t * 0.85)
	if _glow:
		_glow.visible = true
		_glow.modulate = Color(1.0, 0.55, 0.15, lerpf(0.55, 0.15, t))
	scale = Vector2.ONE * lerpf(1.0, 0.92, t)


func _update_char_visual() -> void:
	if material_def == null or _body == null:
		return
	_body.color = material_def.char_color
	if _glow:
		_glow.visible = true
		_glow.modulate = Color(1.0, 0.3, 0.05, 0.12)
	scale = Vector2.ONE * 0.9


func _play_ignition_flash() -> void:
	if _glow == null:
		return
	_glow.visible = true
	_glow.modulate = Color(1.0, 0.95, 0.7, 0.9)
	var flash := create_tween()
	flash.set_parallel(true)
	var peak := 1.0 + 0.18 * (material_def.ignition_flash if material_def else 1.0)
	flash.tween_property(self, "scale", Vector2.ONE * peak, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flash.chain().tween_property(self, "scale", Vector2.ONE, 0.12)
	var glow_tween := create_tween()
	glow_tween.tween_property(_glow, "modulate:a", 0.5, IGNITE_FLASH_TIME)


func _play_destroy_tween() -> void:
	input_pickable = false
	if not is_inside_tree():
		visible = false
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2.ONE * 0.7, 0.35)
	tw.chain().tween_callback(func() -> void:
		visible = false
		if _glow:
			_glow.visible = false
	)


func reset_for_retry() -> void:
	heat = 0.0
	burn_timer = 0.0
	char_timer = 0.0
	ignite_timer = 0.0
	burn_intensity = 0.0
	burned_fraction = 0.0
	ignited_by_player = false
	visible = true
	input_pickable = true
	_set_state(State.UNIGNITED)
	_apply_base_look()
	_glow.visible = false
	_glow.modulate.a = 0.0
