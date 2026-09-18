extends Node2D
## Main scene bootstrap. Wires managers once; GameManager owns the run loop.

@onready var level_root: Node2D = $World/LevelRoot
@onready var fire_manager: FireManager = $Systems/FireManager
@onready var particle_manager: ParticleManager = $Systems/ParticleManager
@onready var score_manager: ScoreManager = $Systems/ScoreManager
@onready var ui: UIManager = $UI


func _ready() -> void:
	GameManager.register_scene(level_root, fire_manager, particle_manager, score_manager, ui)
