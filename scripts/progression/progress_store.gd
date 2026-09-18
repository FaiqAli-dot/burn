class_name ProgressStore
extends RefCounted
## Local progression + save. No accounts/cloud.

const SAVE_PATH := "user://burn_progress.json"

var current_index: int = 0
var highest_unlocked: int = 0
var completed: Dictionary = {} ## level_id -> true
var sequence: Array = [] ## paths


func configure_sequence(paths: Array) -> void:
	sequence = paths.duplicate()
	if highest_unlocked >= sequence.size():
		highest_unlocked = maxi(sequence.size() - 1, 0)
	current_index = clampi(current_index, 0, maxi(sequence.size() - 1, 0))


func current_path() -> String:
	if sequence.is_empty():
		return "res://resources/levels/level_01.json"
	return String(sequence[clampi(current_index, 0, sequence.size() - 1)])


func mark_completed(level_id: String) -> void:
	completed[level_id] = true
	if current_index >= highest_unlocked and current_index + 1 < sequence.size():
		highest_unlocked = current_index + 1
	save()


func can_continue() -> bool:
	return current_index < highest_unlocked or (
		current_index < sequence.size() - 1 and completed.has(_id_for_index(current_index))
	)


func advance() -> bool:
	if current_index + 1 >= sequence.size():
		return false
	if current_index + 1 > highest_unlocked:
		return false
	current_index += 1
	save()
	return true


func retry_current() -> void:
	pass ## index unchanged


func restart_progress() -> void:
	current_index = 0
	highest_unlocked = 0
	completed.clear()
	save()


func _id_for_index(i: int) -> String:
	if i < 0 or i >= sequence.size():
		return ""
	return String(sequence[i]).get_file().get_basename()


func save() -> void:
	var data := {
		"current_index": current_index,
		"highest_unlocked": highest_unlocked,
		"completed": completed,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	current_index = int(d.get("current_index", 0))
	highest_unlocked = int(d.get("highest_unlocked", 0))
	var c = d.get("completed", {})
	if typeof(c) == TYPE_DICTIONARY:
		completed = c
