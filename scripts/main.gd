extends Node2D
## Gameplay scene bootstrap. Wires managers + visual directors once.

@onready var level_root: Node2D = $World/LevelRoot
@onready var fire_manager: FireManager = $Systems/FireManager
@onready var particle_manager: ParticleManager = $Systems/ParticleManager
@onready var score_manager: ScoreManager = $Systems/ScoreManager
@onready var ui: UIManager = $UI
@onready var camera: Camera2D = $World/Camera2D
@onready var backdrop: ColorRect = $Background/Backdrop
@onready var composition: CompositionLayer = $World/CompositionLayer


func _ready() -> void:
	var cam_dir := CameraDirector.new()
	cam_dir.name = "CameraDirector"
	$Systems.add_child(cam_dir)
	cam_dir.bind_camera(camera)
	cam_dir.bind_flash_layer(ui)

	var env := EnvironmentPresenter.new()
	env.name = "EnvironmentPresenter"
	$Systems.add_child(env)
	env.bind_backdrop(backdrop)

	GameManager.register_scene(
		level_root,
		fire_manager,
		particle_manager,
		score_manager,
		ui,
		cam_dir,
		env,
		composition
	)
