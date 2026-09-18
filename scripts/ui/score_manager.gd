class_name ScoreManager
extends Node
## Tracks burn percent and win/fail once fire settles.

signal won
signal failed(percent: float)
signal percent_changed(percent: float)

var _fire: FireManager
var _armed: bool = false
var _resolved: bool = false


func bind_fire(fire: FireManager) -> void:
	_fire = fire
	_armed = true
	_resolved = false
	if not fire.burn_progress_changed.is_connected(_on_progress):
		fire.burn_progress_changed.connect(_on_progress)
	if not fire.simulation_settled.is_connected(_on_settled):
		fire.simulation_settled.connect(_on_settled)


func reset() -> void:
	_resolved = false
	percent_changed.emit(0.0)


func _on_progress(percent: float) -> void:
	percent_changed.emit(percent)
	if _resolved or _fire == null:
		return
	if _fire.is_fully_burned():
		_resolved = true
		won.emit()


func _on_settled() -> void:
	if _resolved or _fire == null:
		return
	if _fire.is_fully_burned():
		_resolved = true
		won.emit()
	else:
		_resolved = true
		failed.emit(_fire.get_burn_percent())
