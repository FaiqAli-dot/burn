class_name CameraDirector
extends Node
## Subtle camera juice on big fire events. Does not affect simulation.

var _camera: Camera2D
var _base_zoom := Vector2.ONE
var _shake_amp: float = 0.0
var _flash_rect: ColorRect


func bind_camera(cam: Camera2D) -> void:
	_camera = cam
	if _camera:
		_base_zoom = _camera.zoom


func bind_flash_layer(layer: CanvasLayer) -> void:
	if layer == null:
		return
	_flash_rect = ColorRect.new()
	_flash_rect.name = "ImpactFlash"
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1.0, 0.85, 0.55, 0.0)
	layer.add_child(_flash_rect)


func _process(delta: float) -> void:
	if _camera == null:
		return
	if _shake_amp > 0.01:
		_shake_amp = lerpf(_shake_amp, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		var t := Time.get_ticks_msec() * 0.05
		_camera.offset = Vector2(sin(t * 1.7), cos(t * 2.1)) * _shake_amp
	else:
		_camera.offset = Vector2.ZERO
		_shake_amp = 0.0


func on_chain(count: int) -> void:
	if count >= 5:
		_nudge_zoom(0.012 + minf(float(count) * 0.002, 0.03))
	if count >= 8:
		_shake(2.2 + minf(float(count) * 0.15, 3.0))


func on_explosion(_origin: Vector2, radius: float, _heat: float) -> void:
	_shake(clampf(radius * 0.03, 4.0, 10.0))
	_flash(0.35)
	_nudge_zoom(0.04)


func on_win() -> void:
	_nudge_zoom(0.025)
	_flash(0.18)


func on_fail() -> void:
	_shake(1.5)


func reset() -> void:
	_shake_amp = 0.0
	if _camera:
		_camera.offset = Vector2.ZERO
		_camera.zoom = _base_zoom
	if _flash_rect:
		_flash_rect.color.a = 0.0


func _shake(amp: float) -> void:
	_shake_amp = maxf(_shake_amp, amp)


func _flash(peak: float) -> void:
	if _flash_rect == null or not is_inside_tree():
		return
	_flash_rect.color = Color(1.0, 0.82, 0.48, peak)
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.0, 0.28).set_ease(Tween.EASE_OUT)


func _nudge_zoom(amount: float) -> void:
	if _camera == null or not is_inside_tree():
		return
	var target := _base_zoom * (1.0 + amount)
	var tw := create_tween()
	tw.tween_property(_camera, "zoom", target, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_camera, "zoom", _base_zoom, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
