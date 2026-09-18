extends Control
## Level browser for progression sequence. Locked entries gated by ProgressStore.

@onready var title: Label = $Title
@onready var list: VBoxContainer = $Scroll/List
@onready var back_btn: Button = $BackButton


func _ready() -> void:
	back_btn.pressed.connect(func() -> void: GameManager.go_main_menu())
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.flat = true
	GameManager.progress.load_save()
	GameManager.progress.configure_sequence(LevelSequenceBuilder.build())
	_build_list()


func _build_list() -> void:
	for c in list.get_children():
		c.queue_free()
	var seq: Array = GameManager.progress.sequence
	for i in seq.size():
		var path := String(seq[i])
		var unlocked := GameManager.is_level_unlocked(i)
		var completed: bool = GameManager.progress.completed.has(path.get_file().get_basename())
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.flat = true
		btn.custom_minimum_size = Vector2(0, 56)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var name := GameManager.level_display_name(path)
		if unlocked:
			var mark := "●" if completed else "○"
			btn.text = "  %s  %02d  %s" % [mark, i + 1, name]
			btn.add_theme_color_override("font_color", Color(0.94, 0.88, 0.78, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.72, 0.38, 1.0))
			var capture_path := path
			btn.pressed.connect(func() -> void: GameManager.play_level(capture_path))
		else:
			btn.text = "  ░  %02d  LOCKED" % (i + 1)
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.45, 0.4, 0.36, 0.7))
			btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.36, 0.7))
		btn.add_theme_font_size_override("font_size", 22)
		list.add_child(btn)
	## Showcase section (always available for art review).
	var sep := Label.new()
	sep.text = "SHOWCASE"
	sep.add_theme_font_size_override("font_size", 16)
	sep.add_theme_color_override("font_color", Color(0.7, 0.55, 0.4, 0.7))
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(sep)
	for i in range(1, 8):
		var spath := "res://resources/levels/showcase/SHOWCASE_%02d.json" % i
		if not FileAccess.file_exists(spath):
			continue
		var sbtn := Button.new()
		sbtn.focus_mode = Control.FOCUS_NONE
		sbtn.flat = true
		sbtn.custom_minimum_size = Vector2(0, 48)
		sbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sbtn.text = "  ◇  %s" % GameManager.level_display_name(spath)
		sbtn.add_theme_font_size_override("font_size", 20)
		sbtn.add_theme_color_override("font_color", Color(0.85, 0.72, 0.55, 0.95))
		var capture := spath
		sbtn.pressed.connect(func() -> void: GameManager.play_level(capture, false))
		list.add_child(sbtn)
