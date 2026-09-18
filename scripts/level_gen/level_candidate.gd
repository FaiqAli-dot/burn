class_name LevelCandidate
extends RefCounted
## In-progress or finalized level dict plus generation bookkeeping.

var data: Dictionary = {}
var seed_value: int = 0
var archetype: String = "CLIMB"
var solution_policy: String = "UNIQUE"
var intended_solution_id: String = ""
var generator_version: String = "1.0.0"


func to_level_dict() -> Dictionary:
	return data.duplicate(true)


func object_count() -> int:
	return (data.get("objects", []) as Array).size()


func scoring_count() -> int:
	var n := 0
	for entry_variant in data.get("objects", []):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if bool(entry_variant.get("scoring", true)):
			n += 1
	return n
