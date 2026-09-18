extends Node
## Top-level run loop: load level, wire fire/UI, handle win/fail/retry.

const LEVEL_01 := "res://resources/levels/level_01.json"

var fire_manager: FireManager
var particle_manager: ParticleManager
var score_manager: ScoreManager
var ui: UIManager
var level_root: Node2D

var _objects: Array[BurnableObject] = []
var _level_meta: Dictionary = {}


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
	load_level(LEVEL_01)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retry"):
		retry_level()


func load_level(path: String) -> void:
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


func retry_level() -> void:
	AudioManager.play_retry()
	load_level(LEVEL_01)


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
