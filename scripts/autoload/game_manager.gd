extends Node
## Top-level run loop: load level, wire fire/UI, handle win/fail/retry.

const LEVEL_01 := "res://resources/levels/level_01.json"
const GENERATED_DIR := "res://resources/levels/generated"

var fire_manager: FireManager
var particle_manager: ParticleManager
var score_manager: ScoreManager
var ui: UIManager
var level_root: Node2D

var _objects: Array[BurnableObject] = []
var _level_meta: Dictionary = {}
var current_level_path: String = LEVEL_01
var debug_generation: bool = false
var _debug_label: Label = null
var _generated_paths: PackedStringArray = PackedStringArray()
var _generated_index: int = -1


func register_scene(
	p_level_root: Node2D,
	p_fire: FireManager,
	p_particles: ParticleManager,
	p_score: ScoreManager,
	p_ui: UIManager
) -> void:
	level_root = p_level_root
	fire_manager = p_fire
	particle_manager = p_particles
	score_manager = p_score
	ui = p_ui
	if not ui.retry_pressed.is_connected(retry_level):
		ui.retry_pressed.connect(retry_level)
	if not score_manager.won.is_connected(_on_won):
		score_manager.won.connect(_on_won)
	if not score_manager.failed.is_connected(_on_failed):
		score_manager.failed.connect(_on_failed)
	if not score_manager.percent_changed.is_connected(_on_percent):
		score_manager.percent_changed.connect(_on_percent)
	_scan_generated()
	load_level(LEVEL_01)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retry"):
		retry_level()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				debug_generation = not debug_generation
				_refresh_debug()
			KEY_N:
				_load_next_generated()
			KEY_B:
				load_level(LEVEL_01)


func load_level(path: String) -> void:
	current_level_path = path
	_clear_level()
	var result := LevelLoader.spawn_level(level_root, path)
	_level_meta = result.get("meta", {})
	_objects = result.get("objects", [])
	for obj in _objects:
		obj.tap_requested.connect(_on_tap)
	fire_manager.set_objects(_objects)
	particle_manager.bind_objects(_objects)
	score_manager.bind_fire(fire_manager)
	score_manager.reset()
	ui.set_level_name(String(_level_meta.get("display_name", "LEVEL")))
	ui.set_percent(0.0)
	ui.show_playing()
	AudioManager.play_level_start()
	_refresh_debug()


func retry_level() -> void:
	AudioManager.play_retry()
	load_level(current_level_path)


func _clear_level() -> void:
	fire_manager.clear()
	particle_manager.clear()
	for child in level_root.get_children():
		level_root.remove_child(child)
		child.free()
	_objects.clear()


func _on_tap(obj: BurnableObject) -> void:
	if fire_manager.request_player_ignite(obj):
		AudioManager.play_ignite()


func _on_percent(percent: float) -> void:
	ui.set_percent(percent)


func _on_won() -> void:
	ui.show_won()
	AudioManager.play_win()


func _on_failed(percent: float) -> void:
	ui.show_failed(percent)
	AudioManager.play_fail()


func _scan_generated() -> void:
	_generated_paths.clear()
	var da := DirAccess.open(GENERATED_DIR)
	if da == null:
		return
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if fname.begins_with("burn_") and fname.ends_with(".json"):
			_generated_paths.append("%s/%s" % [GENERATED_DIR, fname])
		fname = da.get_next()
	da.list_dir_end()
	_generated_paths.sort()


func _load_next_generated() -> void:
	_scan_generated()
	if _generated_paths.is_empty():
		return
	_generated_index = (_generated_index + 1) % _generated_paths.size()
	load_level(_generated_paths[_generated_index])


func _refresh_debug() -> void:
	if not debug_generation:
		if _debug_label:
			_debug_label.visible = false
		return
	if _debug_label == null:
		_debug_label = Label.new()
		_debug_label.name = "GenDebug"
		_debug_label.position = Vector2(16, 110)
		_debug_label.size = Vector2(680, 400)
		_debug_label.add_theme_font_size_override("font_size", 14)
		_debug_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.7, 0.9))
		_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(_debug_label)
	_debug_label.visible = true
	var solver := LevelSolver.new()
	var report := solver.solve_path(current_level_path)
	var gen: Dictionary = {}
	if typeof(_level_meta.get("generator", null)) == TYPE_DICTIONARY:
		gen = _level_meta["generator"]
	var header := "DEBUG F1  N=next gen  B=SPARK\n%s seed=%s arch=%s sols=%s\n" % [
		String(_level_meta.get("id", "")),
		str(gen.get("seed", "-")),
		str(gen.get("archetype", "-")),
		str(report.get("solution_count", 0)),
	]
	_debug_label.text = header + solver.format_debug(report)
