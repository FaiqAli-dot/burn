extends Node
## Platform-safe haptics. Desktop/headless = no-op. Observes events only.

var enabled: bool = true


func toggle_enabled() -> bool:
	enabled = not enabled
	return enabled


func tap() -> void:
	_pulse(0.2)


func ignite() -> void:
	_pulse(0.35)


func chain_step(intensity: float = 0.3) -> void:
	_pulse(clampf(intensity, 0.15, 0.7))


func explosion() -> void:
	_pulse(0.85)


func win() -> void:
	_pulse(0.4)


func fail() -> void:
	_pulse(0.25)


func _pulse(strength: float) -> void:
	if not enabled:
		return
	## Godot 4 Input.vibrate_handheld is mobile-only; guard for desktop/headless.
	if OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(int(lerpf(20.0, 60.0, strength)))
