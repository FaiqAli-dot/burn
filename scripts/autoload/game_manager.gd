extends Node
## Top-level flow: Intro → Main Menu → Level Select / Continue → Gameplay.
## Visual systems observe FireManager; never drive simulation.

const SCENE_INTRO := "res://scenes/intro.tscn"
const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_LEVELS := "res://scenes/level_select.tscn"
const SCENE_GAME := "res://scenes/main.tscn"
const LEVEL_01 := "res://resources/levels/level_01.json"
const GENERATED_DIR := "res://resources/levels/generated"

var fire_manager: FireManager
var particle_manager: ParticleManager
var score_manager: ScoreManager
var ui: UIManager
var level_root: Node2D
var camera_director: CameraDirector
var env_presenter: EnvironmentPresenter
var composition: CompositionLayer

var progress := ProgressStore.new()
var _objects: Array[BurnableObject] = []
var _level_meta: Dictionary = {}
var current_level_path: String = LEVEL_01
var pending_level_path: String = ""
var debug_generation: bool = false
var debug_art: bool = false
var _debug_label: Label = null
var _generated_paths: PackedStringArray = PackedStringArray()
var _generated_index: int = -1
var _browse_mode: bool = false
var _scene_bound: bool = false
var _glow_accum: float = 0.0


func _ready() -> void:
	progress.load_save()
	progress.configure_sequence(LevelSequenceBuilder.build())


func go_intro() -> void:
	get_tree().change_scene_to_file(SCENE_INTRO)


func go_main_menu() -> void:
	_scene_bound = false
	get_tree().change_scene_to_file(SCENE_MENU)


func go_level_select() -> void:
	_scene_bound = false
	get_tree().change_scene_to_file(SCENE_LEVELS)


func play_continue() -> void:
	pending_level_path = progress.current_path()
	get_tree().change_scene_to_file(SCENE_GAME)


func play_level(path: String, set_as_current: bool = true) -> void:
	if set_as_current:
		var idx := progress.sequence.find(path)
		if idx >= 0 and idx <= progress.highest_unlocked:
			progress.current_index = idx
			progress.save()
	pending_level_path = path
	get_tree().change_scene_to_file(SCENE_GAME)


func return_to_menu() -> void:
	_clear_level_runtime()
	go_main_menu()


func register_scene(
	p_level_root: Node2D,
	p_fire: FireManager,
	p_particles: ParticleManager,
	p_score: ScoreManager,
	p_ui: UIManager,
	p_camera: CameraDirector = null,
	p_env: EnvironmentPresenter = null,
	p_comp: CompositionLayer = null
) -> void:
	level_root = p_level_root
	fire_manager = p_fire
	particle_manager = p_particles
	score_manager = p_score
	ui = p_ui
	camera_director = p_camera
	env_presenter = p_env
	composition = p_comp
	_scene_bound = true

	if not ui.retry_pressed.is_connected(retry_level):
		ui.retry_pressed.connect(retry_level)
	if ui.has_signal("continue_pressed") and not ui.continue_pressed.is_connected(continue_level):
		ui.continue_pressed.connect(continue_level)
	if ui.has_signal("home_pressed") and not ui.home_pressed.is_connected(return_to_menu):
		ui.home_pressed.connect(return_to_menu)
	if not score_manager.won.is_connected(_on_won):
		score_manager.won.connect(_on_won)
	if not score_manager.failed.is_connected(_on_failed):
		score_manager.failed.connect(_on_failed)
	if not score_manager.percent_changed.is_connected(_on_percent):
		score_manager.percent_changed.connect(_on_percent)

	particle_manager.bind_world(level_root)
	particle_manager.bind_fire(fire_manager)
	if not fire_manager.chain_ignition.is_connected(_on_chain_audio):
		fire_manager.chain_ignition.connect(_on_chain_audio)
	if not fire_manager.explosion_occurred.is_connected(_on_explosion_audio):
		fire_manager.explosion_occurred.connect(_on_explosion_audio)
	if camera_director:
		if not fire_manager.chain_ignition.is_connected(camera_director.on_chain):
			fire_manager.chain_ignition.connect(camera_director.on_chain)
		if not fire_manager.explosion_occurred.is_connected(camera_director.on_explosion):
			fire_manager.explosion_occurred.connect(camera_director.on_explosion)

	_scan_generated()
	progress.load_save()
	progress.configure_sequence(LevelSequenceBuilder.build())
	var path := pending_level_path if pending_level_path != "" else progress.current_path()
	pending_level_path = ""
	load_level(path)


func _process(delta: float) -> void:
	if not _scene_bound or particle_manager == null or env_presenter == null:
		return
	var target := particle_manager.get_ambient_fire_glow()
	_glow_accum = lerpf(_glow_accum, target, clampf(delta * 3.5, 0.0, 1.0))
	env_presenter.set_fire_glow(_glow_accum)


func _unhandled_input(event: InputEvent) -> void:
	if not _scene_bound:
		return
	if event.is_action_pressed("retry"):
		retry_level()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				debug_generation = not debug_generation
				_browse_mode = debug_generation
				_refresh_debug()
			KEY_F2:
				## Art debug only — cycles environment theme on current level.
				if debug_generation or debug_art:
					debug_art = true
					_cycle_art_theme()
			KEY_N:
				if debug_generation:
					_load_next_generated(1)
			KEY_P:
				if debug_generation:
					_load_next_generated(-1)
			KEY_B:
				if debug_generation:
					load_level(LEVEL_01)
			KEY_ESCAPE:
				return_to_menu()
			KEY_BRACKETLEFT:
				if debug_generation:
					progress.restart_progress()
					load_level(progress.current_path())


func load_level(path: String) -> void:
	if not _scene_bound:
		play_level(path)
		return
	current_level_path = path
	_clear_level()
	var result := LevelLoader.spawn_level(level_root, path)
	_level_meta = result.get("meta", {})
	_objects = result.get("objects", [])
	var vseed := MaterialVisualCatalog.visual_seed_for_level(_level_meta, path)
	for obj in _objects:
		obj.visual_seed = vseed
		## Re-apply look now that seed is known (spawn may have used default).
		if obj.is_inside_tree():
			obj._apply_base_look()
		obj.tap_requested.connect(_on_tap)
		if not obj.destroyed.is_connected(_on_obj_destroyed):
			obj.destroyed.connect(_on_obj_destroyed)
	fire_manager.set_objects(_objects)
	particle_manager.bind_objects(_objects)
	score_manager.bind_fire(fire_manager)
	score_manager.reset()
	_apply_environment(vseed)
	if camera_director:
		camera_director.reset()
	ui.set_level_name(String(_level_meta.get("display_name", "LEVEL")))
	ui.set_percent(0.0)
	ui.show_playing()
	AudioManager.play_level_start()
	_refresh_debug()


func _apply_environment(vseed: int) -> void:
	if env_presenter == null:
		return
	var tid := env_presenter.resolve_theme_id(_level_meta)
	if debug_art and _level_meta.has("_art_theme_override"):
		tid = String(_level_meta["_art_theme_override"])
	var theme := EnvironmentTheme.from_id(tid)
	env_presenter.apply_theme(theme, vseed)
	if composition:
		composition.build(theme, vseed)


func _cycle_art_theme() -> void:
	var order := ["workshop", "forest", "warehouse"]
	var cur := String(_level_meta.get("_art_theme_override", env_presenter.resolve_theme_id(_level_meta) if env_presenter else "workshop"))
	var idx := order.find(cur)
	idx = (idx + 1) % order.size()
	_level_meta["_art_theme_override"] = order[idx]
	debug_art = true
	_apply_environment(MaterialVisualCatalog.visual_seed_for_level(_level_meta, current_level_path))
	_refresh_debug()


func retry_level() -> void:
	AudioManager.play_retry()
	progress.retry_current()
	load_level(current_level_path)


func continue_level() -> void:
	var lid := String(_level_meta.get("id", current_level_path.get_file().get_basename()))
	progress.mark_completed(lid)
	if progress.advance():
		load_level(progress.current_path())
	else:
		ui.show_won()


func _clear_level_runtime() -> void:
	if fire_manager:
		fire_manager.clear()
	if particle_manager:
		particle_manager.clear()
	_objects.clear()
	_scene_bound = false


func _clear_level() -> void:
	fire_manager.clear()
	particle_manager.clear()
	if composition:
		composition.clear()
	for child in level_root.get_children():
		level_root.remove_child(child)
		child.free()
	_objects.clear()
	_glow_accum = 0.0


func _on_tap(obj: BurnableObject) -> void:
	AudioManager.play_tap()
	HapticsManager.tap()
	if fire_manager.request_player_ignite(obj):
		AudioManager.play_ignite()
		HapticsManager.ignite()


func _on_percent(percent: float) -> void:
	ui.set_percent(percent)


func _on_won() -> void:
	ui.show_won()
	AudioManager.play_win()
	HapticsManager.win()
	if camera_director:
		camera_director.on_win()
	var lid := String(_level_meta.get("id", current_level_path.get_file().get_basename()))
	progress.mark_completed(lid)


func _on_failed(percent: float) -> void:
	ui.show_failed(percent)
	AudioManager.play_fail()
	HapticsManager.fail()
	if camera_director:
		camera_director.on_fail()


func _on_chain_audio(count: int) -> void:
	AudioManager.play_chain_step(count)
	HapticsManager.chain_step(0.2 + minf(float(count) * 0.04, 0.4))
	if count >= 6:
		AudioManager.play_large_burn()
	elif count >= 2:
		AudioManager.play_small_burn()


func _on_explosion_audio(_origin: Vector2, _radius: float, _heat: float) -> void:
	AudioManager.play_explosion()
	HapticsManager.explosion()


func _on_obj_destroyed() -> void:
	AudioManager.play_destroy()


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


func _load_next_generated(dir: int = 1) -> void:
	_scan_generated()
	if _generated_paths.is_empty():
		return
	_generated_index = (_generated_index + dir) % _generated_paths.size()
	if _generated_index < 0:
		_generated_index = _generated_paths.size() - 1
	load_level(_generated_paths[_generated_index])


func _refresh_debug() -> void:
	if not debug_generation:
		if _debug_label:
			_debug_label.visible = false
		return
	if ui == null:
		return
	if _debug_label == null:
		_debug_label = Label.new()
		_debug_label.name = "GenDebug"
		_debug_label.position = Vector2(16, 100)
		_debug_label.size = Vector2(688, 520)
		_debug_label.add_theme_font_size_override("font_size", 13)
		_debug_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.7, 0.92))
		_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(_debug_label)
	_debug_label.visible = true
	var solver := LevelSolver.new()
	var report := solver.solve_path(current_level_path)
	var gen: Dictionary = {}
	if typeof(_level_meta.get("generator", null)) == TYPE_DICTIONARY:
		gen = _level_meta["generator"]
	var env_name := String(_level_meta.get("_art_theme_override", env_presenter.resolve_theme_id(_level_meta) if env_presenter else ""))
	var obj_n := _objects.size()
	var header := (
		"DEBUG  F1=toggle  F2=art theme  N/P=browse  Esc=menu  [=reset\n"
		+ "id=%s seed=%s arch=%s diff=%s sols=%s objs=%d env=%s prog=%d/%d unlock=%d\n"
	) % [
		String(_level_meta.get("id", "")),
		str(gen.get("seed", "-")),
		str(gen.get("archetype", "-")),
		str(gen.get("difficulty", "-")),
		str(report.get("solution_count", 0)),
		obj_n,
		env_name,
		progress.current_index + 1,
		progress.sequence.size(),
		progress.highest_unlocked + 1,
	]
	_debug_label.text = header + solver.format_debug(report)


func is_level_unlocked(index: int) -> bool:
	return index <= progress.highest_unlocked


func level_display_name(path: String) -> String:
	var data := LevelLoader.load_level_dict(path)
	return String(data.get("display_name", path.get_file().get_basename())).to_upper()
