extends Control
## Home: CONTINUE + LEVELS. Progression via ProgressStore. Premium minimal.

@onready var brand: Label = $Brand
@onready var continue_btn: Button = $Actions/ContinueButton
@onready var levels_btn: Button = $Actions/LevelsButton
@onready var settings_btn: Button = $SettingsButton
@onready var progress_label: Label = $ProgressLabel
@onready var flame: Polygon2D = $FlameVisual


func _ready() -> void:
	GameManager.progress.load_save()
	GameManager.progress.configure_sequence(LevelSequenceBuilder.build())
	continue_btn.pressed.connect(_on_continue)
	levels_btn.pressed.connect(func() -> void: GameManager.go_level_select())
	settings_btn.pressed.connect(_on_settings)
	_style_buttons()
	_refresh_progress()
	brand.modulate.a = 0.0
	$Actions.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(brand, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property($Actions, "modulate:a", 1.0, 0.4).set_delay(0.1)
	var pulse := create_tween().set_loops()
	pulse.tween_property(flame, "modulate:a", 0.85, 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(flame, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func _style_buttons() -> void:
	for b in [continue_btn, levels_btn, settings_btn]:
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true


func _refresh_progress() -> void:
	var p := GameManager.progress
	var cur := GameManager.level_display_name(p.current_path())
	progress_label.text = "%d / %d  ·  %s" % [p.current_index + 1, maxi(p.sequence.size(), 1), cur]
	continue_btn.text = "CONTINUE" if p.highest_unlocked > 0 or p.completed.size() > 0 else "PLAY"


func _on_continue() -> void:
	GameManager.play_continue()


func _on_settings() -> void:
	var on := HapticsManager.toggle_enabled()
	settings_btn.text = "HAPTICS ON" if on else "HAPTICS OFF"
	var tw := create_tween()
	tw.tween_property(settings_btn, "modulate", Color(1.0, 0.75, 0.4, 1.0), 0.08)
	tw.tween_property(settings_btn, "modulate", Color.WHITE, 0.2)
